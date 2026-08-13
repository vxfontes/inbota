package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"regexp"
	"strings"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/app/service"
)

type InboxUsecase struct {
	Users         repository.UserRepository
	Inbox         repository.InboxRepository
	Suggestions   repository.AiSuggestionRepository
	Flags         repository.FlagRepository
	Subflags      repository.SubflagRepository
	ContextRules  repository.ContextRuleRepository
	Tasks         repository.TaskRepository
	Reminders     repository.ReminderRepository
	Events        repository.EventRepository
	ShoppingLists repository.ShoppingListRepository
	ShoppingItems repository.ShoppingItemRepository

	// Usecases (preferred): used to unify business rules. When running inside a tx,
	// we inject the tx-bound repositories into a copied usecase instance.
	TasksUsecase     *TaskUsecase
	RemindersUsecase *ReminderUsecase
	EventsUsecase    *EventUsecase
	RoutinesUsecase  *RoutineUsecase

	PromptBuilder   *service.PromptBuilder
	AIClient        service.AIClient
	SchemaValidator *service.AiSchemaValidator
	RuleMatcher     *service.ContextRuleMatcher
	TxRunner        repository.TxRunner
	Now             func() time.Time
}

type InboxListInput struct {
	Status *string
	Source *string
}

type InboxItemResult struct {
	Item        domain.InboxItem
	Suggestion  *domain.AiSuggestion
	Suggestions []domain.AiSuggestion
	Confirmed   []ConfirmResult
}

type ConfirmInboxInput struct {
	Type      string
	Title     string
	FlagID    *string
	SubflagID *string
	Payload   json.RawMessage
}

type ConfirmResult struct {
	Type          domain.AiSuggestionType
	Task          *domain.Task
	Reminder      *domain.Reminder
	Event         *domain.Event
	ShoppingList  *domain.ShoppingList
	ShoppingItems []domain.ShoppingItem
	Routine       *domain.Routine
}

func (uc *InboxUsecase) CreateInboxItem(ctx context.Context, userID string, source *string, rawText string, rawMediaURL *string) (domain.InboxItem, error) {
	rawText = normalizeString(rawText)
	if userID == "" || rawText == "" {
		return domain.InboxItem{}, ErrMissingRequiredFields
	}

	item := domain.InboxItem{
		UserID:      userID,
		RawText:     rawText,
		RawMediaURL: normalizeOptionalString(rawMediaURL),
		Status:      domain.InboxStatusNew,
		Source:      domain.InboxSourceManual,
	}
	if source != nil && strings.TrimSpace(*source) != "" {
		parsed, ok := parseInboxSource(*source)
		if !ok {
			return domain.InboxItem{}, ErrInvalidSource
		}
		item.Source = parsed
	}

	return uc.Inbox.Create(ctx, item)
}

func (uc *InboxUsecase) ListInboxItems(ctx context.Context, userID string, input InboxListInput, opts repository.ListOptions) ([]InboxItemResult, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}

	filter := repository.InboxListFilter{}
	if input.Status != nil && strings.TrimSpace(*input.Status) != "" {
		parsed, ok := parseInboxStatus(*input.Status)
		if !ok {
			return nil, nil, ErrInvalidStatus
		}
		filter.Status = &parsed
	}
	if input.Source != nil && strings.TrimSpace(*input.Source) != "" {
		parsed, ok := parseInboxSource(*input.Source)
		if !ok {
			return nil, nil, ErrInvalidSource
		}
		filter.Source = &parsed
	}

	items, next, err := uc.Inbox.ListWithSuggestion(ctx, userID, filter, opts)
	if err != nil {
		return nil, nil, err
	}

	results := make([]InboxItemResult, 0, len(items))
	for _, item := range items {
		var suggestion *domain.AiSuggestion
		if item.SuggestionID != nil {
			suggestion = &domain.AiSuggestion{
				ID:          *item.SuggestionID,
				UserID:      item.UserID,
				InboxItemID: item.ID,
				Type:        domain.AiSuggestionType(*item.SuggestionType),
				Title:       *item.SuggestionTitle,
				Confidence:  item.SuggestionConfidence,
				FlagID:      item.SuggestionFlagID,
				SubflagID:   item.SuggestionSubflagID,
				PayloadJSON: item.PayloadJSON,
			}
			if item.SuggestionNeedsReview != nil {
				suggestion.NeedsReview = *item.SuggestionNeedsReview
			}
			if item.SuggestionCreatedAt != nil {
				suggestion.CreatedAt = *item.SuggestionCreatedAt
			}
		}
		results = append(results, InboxItemResult{Item: item.InboxItem, Suggestion: suggestion})
	}

	return results, next, nil
}

func (uc *InboxUsecase) GetInboxItem(ctx context.Context, userID, id string) (InboxItemResult, error) {
	if userID == "" || id == "" {
		return InboxItemResult{}, ErrMissingRequiredFields
	}
	item, err := uc.Inbox.GetWithSuggestion(ctx, userID, id)
	if err != nil {
		return InboxItemResult{}, err
	}

	var suggestion *domain.AiSuggestion
	if item.SuggestionID != nil {
		suggestion = &domain.AiSuggestion{
			ID:          *item.SuggestionID,
			UserID:      item.UserID,
			InboxItemID: item.ID,
			Type:        domain.AiSuggestionType(*item.SuggestionType),
			Title:       *item.SuggestionTitle,
			Confidence:  item.SuggestionConfidence,
			FlagID:      item.SuggestionFlagID,
			SubflagID:   item.SuggestionSubflagID,
			PayloadJSON: item.PayloadJSON,
		}
		if item.SuggestionNeedsReview != nil {
			suggestion.NeedsReview = *item.SuggestionNeedsReview
		}
		if item.SuggestionCreatedAt != nil {
			suggestion.CreatedAt = *item.SuggestionCreatedAt
		}
	}

	result := InboxItemResult{Item: item.InboxItem, Suggestion: suggestion}
	if uc.Suggestions != nil {
		suggestions, _, err := uc.Suggestions.ListByInboxItem(ctx, userID, id, repository.ListOptions{})
		if err != nil {
			return InboxItemResult{}, err
		}
		if len(suggestions) > 0 {
			result.Suggestions = suggestions
			if result.Suggestion == nil {
				latest := suggestions[0]
				result.Suggestion = &latest
			}
		}
	}

	return result, nil
}

func (uc *InboxUsecase) GetInboxItemsByIDs(ctx context.Context, userID string, ids []string) (map[string]domain.InboxItem, error) {
	if userID == "" {
		return nil, ErrMissingRequiredFields
	}
	if len(ids) == 0 {
		return map[string]domain.InboxItem{}, nil
	}
	items, err := uc.Inbox.GetByIDs(ctx, userID, ids)
	if err != nil {
		return nil, err
	}
	out := make(map[string]domain.InboxItem, len(items))
	for _, item := range items {
		out[item.ID] = item
	}
	return out, nil
}

func (uc *InboxUsecase) ReprocessInboxItem(ctx context.Context, userID, id string) (InboxItemResult, error) {
	if userID == "" || id == "" {
		return InboxItemResult{}, ErrMissingRequiredFields
	}
	if uc.Inbox == nil || uc.AIClient == nil {
		return InboxItemResult{}, ErrDependencyMissing
	}
	if uc.PromptBuilder == nil || uc.SchemaValidator == nil {
		return InboxItemResult{}, ErrDependencyMissing
	}
	if uc.Users == nil || uc.Flags == nil || uc.Subflags == nil || uc.ContextRules == nil {
		return InboxItemResult{}, ErrDependencyMissing
	}

	item, err := uc.Inbox.Get(ctx, userID, id)
	if err != nil {
		return InboxItemResult{}, err
	}
	if item.Status == domain.InboxStatusConfirmed || item.Status == domain.InboxStatusDismissed {
		return InboxItemResult{}, ErrInvalidStatus
	}

	item.Status = domain.InboxStatusProcessing
	item.LastError = nil
	item, err = uc.Inbox.Update(ctx, item)
	if err != nil {
		return InboxItemResult{}, err
	}

	user, err := uc.Users.Get(ctx, userID)
	if err != nil {
		return uc.failInboxPersistence(ctx, item, err)
	}

	now := time.Now()
	if uc.Now != nil {
		now = uc.Now()
	}

	// Default fallback: Brazil timezone.
	fallbackLoc, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		fallbackLoc = now.Location()
	}

	if tz := strings.TrimSpace(user.Timezone); tz != "" {
		if loc, err := time.LoadLocation(tz); err == nil {
			now = now.In(loc)
		} else {
			now = now.In(fallbackLoc)
		}
	} else {
		now = now.In(fallbackLoc)
	}

	flags, err := listAllFlags(ctx, uc.Flags, userID)
	if err != nil {
		return uc.failInboxPersistence(ctx, item, err)
	}
	subflagsByFlag := make(map[string][]domain.Subflag, len(flags))
	for _, flag := range flags {
		subflags, err := listAllSubflags(ctx, uc.Subflags, userID, flag.ID)
		if err != nil {
			return uc.failInboxPersistence(ctx, item, err)
		}
		subflagsByFlag[flag.ID] = subflags
	}
	rules, err := listAllContextRules(ctx, uc.ContextRules, userID)
	if err != nil {
		return uc.failInboxPersistence(ctx, item, err)
	}

	// In-memory index of this user's valid flags/subflags, built from the exact same data
	// just loaded to construct the prompt (flags, subflagsByFlag) — used below by
	// resolveSuggestionFlagContext to validate the AI's flagId/subflagId before persisting a
	// suggestion, without any extra DB round-trip. See resolveSuggestionFlagContext's doc
	// comment for why this replaced a live repository lookup.
	//
	// Keys are lowercased so lookups match Postgres' case-insensitive uuid comparison (the old
	// uc.Flags.Get/uc.Subflags.Get path resolved regardless of hex case; a Go map lookup on the
	// raw string wouldn't). Map values stay the canonical, as-stored DB ID (flag.ID / sub.ID) —
	// never the lowercased key — so anything resolved here and later persisted or logged uses
	// the same casing as the rest of the app, not whatever case the model happened to emit.
	flagIndex := make(map[string]string, len(flags))
	subflagIndex := make(map[string]subflagIndexEntry, len(flags))
	for _, flag := range flags {
		flagIndex[strings.ToLower(flag.ID)] = flag.ID
		for _, sub := range subflagsByFlag[flag.ID] {
			subflagIndex[strings.ToLower(sub.ID)] = subflagIndexEntry{SubflagID: sub.ID, FlagID: flag.ID}
		}
	}

	contexts := make([]service.ContextItem, 0)
	for _, flag := range flags {
		flagName := flag.Name
		contexts = append(contexts, service.ContextItem{
			FlagID:   flag.ID,
			FlagName: flagName,
		})
		for _, sub := range subflagsByFlag[flag.ID] {
			subID := sub.ID
			subName := sub.Name
			contexts = append(contexts, service.ContextItem{
				FlagID:      flag.ID,
				FlagName:    flagName,
				SubflagID:   &subID,
				SubflagName: &subName,
			})
		}
	}

	ruleItems := make([]service.RuleItem, 0, len(rules))
	for _, rule := range rules {
		ruleItems = append(ruleItems, service.RuleItem{
			Keyword:   rule.Keyword,
			FlagID:    rule.FlagID,
			SubflagID: rule.SubflagID,
		})
	}

	var hint *service.ContextHint
	matcher := uc.RuleMatcher
	if matcher != nil {
		if match := matcher.Match(item.RawText, rules); match != nil {
			reason := "keyword:" + match.Keyword
			hint = &service.ContextHint{
				FlagID:    match.FlagID,
				SubflagID: match.SubflagID,
				Reason:    reason,
			}
		}
	}

	promptInput := service.PromptInput{
		RawText:  item.RawText,
		Locale:   strings.TrimSpace(user.Locale),
		Timezone: strings.TrimSpace(user.Timezone),
		Now:      now,
		Contexts: contexts,
		Rules:    ruleItems,
		Hint:     hint,
	}
	prompt := uc.PromptBuilder.Build(promptInput)

	completion, err := uc.AIClient.Complete(ctx, prompt)
	if err != nil {
		return uc.failInboxProcessing(ctx, item, err)
	}

	usedHardFallback := false
	validatedMany, err := uc.SchemaValidator.ValidateMany([]byte(completion.Content))
	if err != nil {
		if !errors.Is(err, service.ErrAISchemaInvalid) {
			return uc.failInboxProcessing(ctx, item, err)
		}

		if fallbackClient, ok := uc.AIClient.(service.AIClientWithFallback); ok {
			fallbackModel := strings.TrimSpace(fallbackClient.FallbackModel())
			if fallbackModel != "" && !strings.EqualFold(strings.TrimSpace(completion.Model), fallbackModel) {
				fallbackCompletion, fallbackErr := fallbackClient.CompleteWithModel(ctx, prompt, fallbackModel)
				if fallbackErr == nil {
					if fallbackValidated, fallbackValErr := uc.SchemaValidator.ValidateMany([]byte(fallbackCompletion.Content)); fallbackValErr == nil {
						completion = fallbackCompletion
						validatedMany = fallbackValidated
						err = nil
					}
				}
			}
		}

		if err == nil {
			goto validatedOutputReady
		}

		var fallbackContext *service.AIContext
		if hint != nil {
			flagID := strings.TrimSpace(hint.FlagID)
			var flagIDPtr *string
			if flagID != "" {
				flagIDCopy := flagID
				flagIDPtr = &flagIDCopy
			}
			var subflagIDPtr *string
			if hint.SubflagID != nil {
				subflagID := strings.TrimSpace(*hint.SubflagID)
				if subflagID != "" {
					subflagIDCopy := subflagID
					subflagIDPtr = &subflagIDCopy
				}
			}
			fallbackContext = &service.AIContext{
				FlagID:    flagIDPtr,
				SubflagID: subflagIDPtr,
			}
		}

		validatedMany = []service.ValidatedOutput{service.BuildFallbackTaskOutput(item.RawText, fallbackContext)}
		usedHardFallback = true
	}

validatedOutputReady:
	if !usedHardFallback && len(validatedMany) == 1 {
		if expanded, expandErr := uc.expandValidatedOutputsByClauses(ctx, promptInput); expandErr == nil && len(expanded) > 1 {
			validatedMany = expanded
		}
	}

	anyNeedsReview := outputsNeedReview(validatedMany)
	if !usedHardFallback && anyNeedsReview {
		if fallbackClient, ok := uc.AIClient.(service.AIClientWithFallback); ok && fallbackClient.FallbackOnNeedsReview() {
			fallbackModel := strings.TrimSpace(fallbackClient.FallbackModel())
			if fallbackModel != "" && !strings.EqualFold(strings.TrimSpace(completion.Model), fallbackModel) {
				fallbackCompletion, fallbackErr := fallbackClient.CompleteWithModel(ctx, prompt, fallbackModel)
				if fallbackErr == nil {
					if fallbackValidated, fallbackValErr := uc.SchemaValidator.ValidateMany([]byte(fallbackCompletion.Content)); fallbackValErr == nil {
						completion = fallbackCompletion
						validatedMany = fallbackValidated
					}
				}
			}
		}
	}
	for idx := range validatedMany {
		normalizeValidatedOutput(&validatedMany[idx], item.RawText)
	}
	anyNeedsReview = outputsNeedReview(validatedMany)

	// Persist suggestions (one or many). When multiple suggestions are returned,
	// we auto-confirm all entities to keep quick-add deterministic.
	autoConfirm := len(validatedMany) > 1

	// We'll return the last created suggestion (if any) for backward compatibility.
	var suggestion domain.AiSuggestion
	createdSuggestions := make([]domain.AiSuggestion, 0, len(validatedMany))
	confirmedResults := make([]ConfirmResult, 0, len(validatedMany))

	if uc.TxRunner != nil {
		if err := uc.TxRunner.WithTx(ctx, func(tx repository.TxRepositories) error {
			if tx.Suggestions == nil || tx.Inbox == nil {
				return ErrDependencyMissing
			}

			for _, vout := range validatedMany {
				s := domain.AiSuggestion{
					UserID:      userID,
					InboxItemID: item.ID,
					Type:        domain.AiSuggestionType(vout.Output.Type),
					Title:       vout.Output.Title,
					Confidence:  vout.Output.Confidence,
					NeedsReview: vout.Output.NeedsReview,
					PayloadJSON: vout.Output.Payload,
				}
				if vout.Output.Context != nil {
					s.FlagID, s.SubflagID = uc.resolveSuggestionFlagContext(userID, item.ID, flagIndex, subflagIndex, vout.Output.Context.FlagID, vout.Output.Context.SubflagID)
				}
				// Note: assign to the closure-captured `suggestion`/`item` only on success.
				// Repository methods here return the zero value alongside a non-nil error, so
				// reassigning the captured variable unconditionally (e.g. `item, err = ...`)
				// would clobber it with a zeroed-out struct (empty ID) right before the error
				// path below hands it to failInboxPersistence — leaving the item impossible to
				// recover and stuck in PROCESSING forever.
				created, err := tx.Suggestions.Create(ctx, s)
				if err != nil {
					return err
				}
				suggestion = created
				createdSuggestions = append(createdSuggestions, suggestion)

				if autoConfirm {
					confirmed, err := uc.applyValidatedSuggestionTx(ctx, tx, userID, item, vout)
					if err != nil {
						return err
					}
					confirmedResults = append(confirmedResults, confirmed)
				}
			}

			if autoConfirm {
				item.Status = domain.InboxStatusConfirmed
			} else if anyNeedsReview {
				item.Status = domain.InboxStatusNeedsReview
			} else {
				item.Status = domain.InboxStatusSuggested
			}
			item.LastError = nil
			updated, err := tx.Inbox.Update(ctx, item)
			if err != nil {
				return err
			}
			item = updated
			return nil
		}); err != nil {
			// Everything inside WithTx is about persisting the AI's (already-validated)
			// output, not about the AI itself — any failure here is ours, not the model's.
			// `item` above is guaranteed to still hold a valid ID at this point (see the
			// no-clobber note inside the closure), so this can actually flip it out of
			// PROCESSING instead of targeting an empty ID.
			return uc.failInboxPersistence(ctx, item, err)
		}
	} else {
		if uc.Suggestions == nil {
			return uc.failInboxPersistence(ctx, item, ErrDependencyMissing)
		}

		for _, vout := range validatedMany {
			s := domain.AiSuggestion{
				UserID:      userID,
				InboxItemID: item.ID,
				Type:        domain.AiSuggestionType(vout.Output.Type),
				Title:       vout.Output.Title,
				Confidence:  vout.Output.Confidence,
				NeedsReview: vout.Output.NeedsReview,
				PayloadJSON: vout.Output.Payload,
			}
			if vout.Output.Context != nil {
				s.FlagID, s.SubflagID = uc.resolveSuggestionFlagContext(userID, item.ID, flagIndex, subflagIndex, vout.Output.Context.FlagID, vout.Output.Context.SubflagID)
			}
			// Same no-clobber rule as the tx branch above: only assign to the outer
			// `suggestion`/`item` once we know the call succeeded.
			created, err := uc.Suggestions.Create(ctx, s)
			if err != nil {
				return uc.failInboxPersistence(ctx, item, err)
			}
			suggestion = created
			createdSuggestions = append(createdSuggestions, suggestion)
			if autoConfirm {
				// No-tx mode: best effort creation without a wrapping transaction.
				// Prefer running with TxRunner in production.
				confirmed, err := uc.applyValidatedSuggestionNoTx(ctx, userID, item, vout)
				if err != nil {
					return uc.failInboxPersistence(ctx, item, err)
				}
				confirmedResults = append(confirmedResults, confirmed)
			}
		}

		if autoConfirm {
			item.Status = domain.InboxStatusConfirmed
		} else if anyNeedsReview {
			item.Status = domain.InboxStatusNeedsReview
		} else {
			item.Status = domain.InboxStatusSuggested
		}
		item.LastError = nil
		updated, err := uc.Inbox.Update(ctx, item)
		if err != nil {
			return uc.failInboxPersistence(ctx, item, err)
		}
		item = updated
	}

	// If no suggestions were persisted (shouldn't happen), return nil suggestion.
	if suggestion.ID == "" {
		return InboxItemResult{
			Item:        item,
			Suggestion:  nil,
			Suggestions: createdSuggestions,
			Confirmed:   confirmedResults,
		}, nil
	}
	return InboxItemResult{
		Item:        item,
		Suggestion:  &suggestion,
		Suggestions: createdSuggestions,
		Confirmed:   confirmedResults,
	}, nil
}

func (uc *InboxUsecase) ConfirmInboxItem(ctx context.Context, userID, id string, input ConfirmInboxInput) (ConfirmResult, error) {
	title := normalizeString(input.Title)
	if userID == "" || id == "" || title == "" || input.Type == "" {
		return ConfirmResult{}, ErrMissingRequiredFields
	}
	if uc.SchemaValidator == nil || uc.Inbox == nil {
		return ConfirmResult{}, ErrDependencyMissing
	}

	typ, ok := parseSuggestionType(input.Type)
	if !ok || typ == domain.AiSuggestionTypeNote {
		return ConfirmResult{}, ErrInvalidType
	}

	item, err := uc.Inbox.Get(ctx, userID, id)
	if err != nil {
		return ConfirmResult{}, err
	}
	if item.Status == domain.InboxStatusConfirmed || item.Status == domain.InboxStatusDismissed {
		return ConfirmResult{}, ErrInvalidStatus
	}

	hintFlagID := normalizeOptionalString(input.FlagID)
	hintSubflagID := normalizeOptionalString(input.SubflagID)
	var ctxHint *service.AIContext
	if hintFlagID != nil || hintSubflagID != nil {
		ctxHint = &service.AIContext{
			FlagID:    hintFlagID,
			SubflagID: hintSubflagID,
		}
	}

	payload := input.Payload
	if len(payload) == 0 {
		return ConfirmResult{}, ErrMissingRequiredFields
	}
	output := service.AIOutput{
		Type:        string(typ),
		Title:       title,
		NeedsReview: false,
		Context:     ctxHint,
		Payload:     payload,
	}
	raw, err := json.Marshal(output)
	if err != nil {
		return ConfirmResult{}, err
	}
	validated, err := uc.SchemaValidator.Validate(raw)
	if err != nil {
		return ConfirmResult{}, err
	}
	if typ == domain.AiSuggestionTypeShopping {
		title = normalizeShoppingListTitle(title, item.RawText, validated.Payload)
	}

	result := ConfirmResult{Type: typ}
	var flagID *string
	var subflagID *string
	if validated.Output.Context != nil {
		rawFlagID := normalizeOptionalString(validated.Output.Context.FlagID)
		rawSubflagID := normalizeOptionalString(validated.Output.Context.SubflagID)

		if uc.RoutinesUsecase != nil {
			var err error
			flagID, subflagID, err = uc.RoutinesUsecase.ResolveFlagAndSubflag(ctx, userID, rawFlagID, rawSubflagID)
			if err != nil {
				return ConfirmResult{}, err
			}
		} else {
			flagID = rawFlagID
			subflagID = rawSubflagID
		}
	}

	// Get current time in user timezone for weekday guardrail.
	now := time.Now()
	if uc.Now != nil {
		now = uc.Now()
	}
	fallbackLoc, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		fallbackLoc = now.Location()
	}
	if uc.Users != nil {
		user, err := uc.Users.Get(ctx, userID)
		if err == nil {
			if tz := strings.TrimSpace(user.Timezone); tz != "" {
				if loc, err := time.LoadLocation(tz); err == nil {
					now = now.In(loc)
				} else {
					now = now.In(fallbackLoc)
				}
			} else {
				now = now.In(fallbackLoc)
			}
		} else {
			now = now.In(fallbackLoc)
		}
	} else {
		now = now.In(fallbackLoc)
	}

	if uc.TxRunner != nil {
		if err := uc.TxRunner.WithTx(ctx, func(tx repository.TxRepositories) error {
			if tx.Inbox == nil {
				return ErrDependencyMissing
			}
			switch typ {
			case domain.AiSuggestionTypeTask:
				if tx.Tasks == nil {
					return ErrDependencyMissing
				}
				if uc.TasksUsecase == nil {
					return ErrDependencyMissing
				}
				taskPayload, ok := validated.Payload.(service.TaskPayload)
				if !ok {
					return ErrInvalidPayload
				}

				taskUC := *uc.TasksUsecase
				taskUC.Tasks = tx.Tasks
				created, err := taskUC.Create(ctx, userID, title, nil, nil, taskPayload.DueAt, flagID, subflagID, &item.ID)
				if err != nil {
					return err
				}
				result.Task = &created
			case domain.AiSuggestionTypeReminder:
				if tx.Reminders == nil {
					return ErrDependencyMissing
				}
				if uc.RemindersUsecase == nil {
					return ErrDependencyMissing
				}
				reminderPayload, ok := validated.Payload.(service.ReminderPayload)
				if !ok {
					return ErrInvalidPayload
				}

				fixWeekdayMismatch(&reminderPayload.At, nil, item.RawText, now)

				remUC := *uc.RemindersUsecase
				remUC.Reminders = tx.Reminders
				created, err := remUC.Create(ctx, userID, title, nil, &reminderPayload.At, flagID, subflagID, &item.ID)
				if err != nil {
					return err
				}
				result.Reminder = &created
			case domain.AiSuggestionTypeEvent:
				if tx.Events == nil {
					return ErrDependencyMissing
				}
				if uc.EventsUsecase == nil {
					return ErrDependencyMissing
				}
				eventPayload, ok := validated.Payload.(service.EventPayload)
				if !ok {
					return ErrInvalidPayload
				}

				// Guardrail: if the user explicitly mentioned a weekday (e.g. "sexta") and the
				// model returned a different weekday (e.g. sábado), fix it deterministically.
				fixWeekdayMismatch(&eventPayload.Start, eventPayload.End, item.RawText, now)

				eventUC := *uc.EventsUsecase
				eventUC.Events = tx.Events
				created, err := eventUC.Create(ctx, userID, title, &eventPayload.Start, eventPayload.End, &eventPayload.AllDay, nil, flagID, subflagID, &item.ID)
				if err != nil {
					return err
				}
				result.Event = &created
			case domain.AiSuggestionTypeShopping:
				if tx.ShoppingLists == nil || tx.ShoppingItems == nil {
					return ErrDependencyMissing
				}
				shopPayload, ok := validated.Payload.(service.ShoppingPayload)
				if !ok {
					return ErrInvalidPayload
				}
				list := domain.ShoppingList{
					UserID:            userID,
					Title:             title,
					SourceInboxItemID: &item.ID,
				}
				createdList, err := tx.ShoppingLists.Create(ctx, list)
				if err != nil {
					return err
				}
				result.ShoppingList = &createdList

				items := make([]domain.ShoppingItem, 0, len(shopPayload.Items))
				for idx, shopItem := range shopPayload.Items {
					item := domain.ShoppingItem{
						UserID:    userID,
						ListID:    createdList.ID,
						Title:     shopItem.Title,
						Quantity:  shopItem.Quantity,
						Checked:   false,
						SortOrder: idx,
					}
					created, err := tx.ShoppingItems.Create(ctx, item)
					if err != nil {
						return err
					}
					items = append(items, created)
				}
				result.ShoppingItems = items
			case domain.AiSuggestionTypeRoutine:
				if tx.Routines == nil {
					return ErrDependencyMissing
				}
				routinePayload, ok := validated.Payload.(service.RoutinePayload)
				if !ok {
					return ErrInvalidPayload
				}
				if uc.RoutinesUsecase == nil {
					return ErrDependencyMissing
				}

				// Use the RoutineUsecase to keep creation rules unified.
				routineUC := *uc.RoutinesUsecase
				routineUC.Routines = tx.Routines

				created, err := routineUC.Create(ctx, userID, RoutineInput{
					Title:             title,
					RecurrenceType:    routinePayload.RecurrenceType,
					Weekdays:          routinePayload.Weekdays,
					StartTime:         routinePayload.StartTime,
					EndTime:           routinePayload.EndTime,
					WeekOfMonth:       routinePayload.WeekOfMonth,
					DayOfMonth:        routinePayload.DayOfMonth,
					StartsOn:          routinePayload.StartsOn,
					EndsOn:            routinePayload.EndsOn,
					FlagID:            flagID,
					SubflagID:         subflagID,
					SourceInboxItemID: &item.ID,
				})
				if err != nil {
					return err
				}
				result.Routine = &created
			default:
				return ErrInvalidType
			}

			item.Status = domain.InboxStatusConfirmed
			item.LastError = nil
			if _, err := tx.Inbox.Update(ctx, item); err != nil {
				return err
			}
			return nil
		}); err != nil {
			return ConfirmResult{}, err
		}
	} else {
		switch typ {
		case domain.AiSuggestionTypeTask:
			if uc.TasksUsecase == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			taskPayload, ok := validated.Payload.(service.TaskPayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			created, err := uc.TasksUsecase.Create(ctx, userID, title, nil, nil, taskPayload.DueAt, flagID, subflagID, &item.ID)
			if err != nil {
				return ConfirmResult{}, err
			}
			result.Task = &created
		case domain.AiSuggestionTypeReminder:
			if uc.RemindersUsecase == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			reminderPayload, ok := validated.Payload.(service.ReminderPayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			created, err := uc.RemindersUsecase.Create(ctx, userID, title, nil, &reminderPayload.At, flagID, subflagID, &item.ID)
			if err != nil {
				return ConfirmResult{}, err
			}
			result.Reminder = &created
		case domain.AiSuggestionTypeEvent:
			if uc.EventsUsecase == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			eventPayload, ok := validated.Payload.(service.EventPayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			created, err := uc.EventsUsecase.Create(ctx, userID, title, &eventPayload.Start, eventPayload.End, &eventPayload.AllDay, nil, flagID, subflagID, &item.ID)
			if err != nil {
				return ConfirmResult{}, err
			}
			result.Event = &created
		case domain.AiSuggestionTypeShopping:
			if uc.ShoppingLists == nil || uc.ShoppingItems == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			shopPayload, ok := validated.Payload.(service.ShoppingPayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			list := domain.ShoppingList{
				UserID:            userID,
				Title:             title,
				SourceInboxItemID: &item.ID,
			}
			createdList, err := uc.ShoppingLists.Create(ctx, list)
			if err != nil {
				return ConfirmResult{}, err
			}
			result.ShoppingList = &createdList

			items := make([]domain.ShoppingItem, 0, len(shopPayload.Items))
			for idx, shopItem := range shopPayload.Items {
				item := domain.ShoppingItem{
					UserID:    userID,
					ListID:    createdList.ID,
					Title:     shopItem.Title,
					Quantity:  shopItem.Quantity,
					Checked:   false,
					SortOrder: idx,
				}
				created, err := uc.ShoppingItems.Create(ctx, item)
				if err != nil {
					return ConfirmResult{}, err
				}
				items = append(items, created)
			}
			result.ShoppingItems = items
		case domain.AiSuggestionTypeRoutine:
			if uc.RoutinesUsecase == nil {
				return ConfirmResult{}, ErrDependencyMissing
			}
			routinePayload, ok := validated.Payload.(service.RoutinePayload)
			if !ok {
				return ConfirmResult{}, ErrInvalidPayload
			}
			created, err := uc.RoutinesUsecase.Create(ctx, userID, RoutineInput{
				Title:             title,
				RecurrenceType:    routinePayload.RecurrenceType,
				Weekdays:          routinePayload.Weekdays,
				StartTime:         routinePayload.StartTime,
				EndTime:           routinePayload.EndTime,
				WeekOfMonth:       routinePayload.WeekOfMonth,
				DayOfMonth:        routinePayload.DayOfMonth,
				StartsOn:          routinePayload.StartsOn,
				EndsOn:            routinePayload.EndsOn,
				FlagID:            flagID,
				SubflagID:         subflagID,
				SourceInboxItemID: &item.ID,
			})
			if err != nil {
				return ConfirmResult{}, err
			}
			result.Routine = &created
		default:
			return ConfirmResult{}, ErrInvalidType
		}

		item.Status = domain.InboxStatusConfirmed
		item.LastError = nil
		if _, err := uc.Inbox.Update(ctx, item); err != nil {
			return ConfirmResult{}, err
		}
	}

	return result, nil
}

func (uc *InboxUsecase) DismissInboxItem(ctx context.Context, userID, id string) (domain.InboxItem, error) {
	if userID == "" || id == "" {
		return domain.InboxItem{}, ErrMissingRequiredFields
	}
	item, err := uc.Inbox.Get(ctx, userID, id)
	if err != nil {
		return domain.InboxItem{}, err
	}
	if item.Status == domain.InboxStatusConfirmed {
		return domain.InboxItem{}, ErrInvalidStatus
	}
	item.Status = domain.InboxStatusDismissed
	item.LastError = nil
	return uc.Inbox.Update(ctx, item)
}

// subflagIndexEntry is the value side of subflagIndex: the canonical, as-stored-in-Postgres
// IDs for a subflag and the flag it belongs to, keyed (in subflagIndex) by the subflag's ID
// lowercased. Kept as a small struct rather than two parallel maps so the pair can't drift
// out of sync.
type subflagIndexEntry struct {
	SubflagID string
	FlagID    string
}

// resolveSuggestionFlagContext validates a flag/subflag pair coming straight from the AI
// output before it is persisted on an ai_suggestions row. The model is asked for a flagId
// even when the user has zero flags (the schema requires a string), so it may hallucinate a
// value that is not a valid UUID or doesn't belong to this user.
//
// Unlike ConfirmInboxItem (~line 616), which resolves via RoutineUsecase.ResolveFlagAndSubflag
// against the DB and treats an unresolvable flag as a hard error, this is a best-effort path:
// an unresolvable flagId/subflagId is dropped (nil) instead of blocking the insert or blowing
// up on an invalid UUID / FK violation. It validates against flagIndex/subflagIndex, built by
// the caller from the exact same flags/subflags already loaded into memory to build the AI
// prompt (see ReprocessInboxItem) — no repository call happens here. This is deliberate:
//   - It's the same data the model was actually offered, so "valid" means the same thing for
//     both the prompt and the persisted suggestion.
//   - It avoids taking a second connection from the pool while one is already checked out for
//     the enclosing transaction (previously done via uc.Flags.Get/uc.Subflags.Get inside
//     WithTx — with SetMaxOpenConns(10), a handful of concurrent reprocesses could exhaust the
//     pool and deadlock waiting on each other).
//   - It can't confuse a transient DB error (timeout, pool exhaustion) with "invalid flag":
//     there's no DB call left to fail transiently.
//
// Lookups are done on strings.ToLower(rawID) against flagIndex/subflagIndex, whose keys are
// themselves lowercased by the caller: Postgres' uuid type parses/compares hex case-
// insensitively, so a model that emits the right ID in uppercase must still resolve, exactly
// like the old uc.Flags.Get/uc.Subflags.Get path did. Whenever a flag/subflag DOES resolve,
// the value returned is the canonical DB ID (flagIndex's/subflagIndex's value, i.e. flag.ID /
// sub.ID as stored), never the model's raw string and never the lowercased lookup key — so
// what gets persisted (and what a caller might log on success) always has the same casing as
// the rest of the app. The raw, as-received value is only ever used for the discard warning
// below, precisely because it was NOT found and there's no canonical form to substitute.
//
// Flag and subflag are validated independently. A valid flag with an invalid/unrelated
// subflag keeps the flag and drops only the subflag — the model is far more likely to get a
// subflag wrong than a flag, and losing both because of an invalid subflag was needlessly
// punitive (this mirrors ResolveFlagAndSubflag's field-level checks, but stops short of its
// "any invalid field invalidates the whole pair" behavior, which is correct for ConfirmInboxItem
// but too strict for a best-effort suggestion). A subflag whose parent isn't the given flag is
// treated as invalid; if only the subflag is given (and valid), its parent flag is used.
//
// Any discard is logged at Warn (with userID/inboxItemID/the raw rejected value) rather than
// silently swallowed, so a model hallucinating flags 100% of the time is distinguishable from
// the expected "model got it right, user just doesn't have that flag" case.
func (uc *InboxUsecase) resolveSuggestionFlagContext(userID, inboxItemID string, flagIndex map[string]string, subflagIndex map[string]subflagIndexEntry, rawFlagID, rawSubflagID *string) (*string, *string) {
	rawFlag := normalizeOptionalString(rawFlagID)
	rawSubflag := normalizeOptionalString(rawSubflagID)

	var flagID *string
	if rawFlag != nil {
		if canonical, ok := flagIndex[strings.ToLower(*rawFlag)]; ok {
			resolved := canonical
			flagID = &resolved
		} else {
			slog.Warn("inbox_suggestion_flag_id_discarded",
				slog.String("user_id", userID),
				slog.String("inbox_item_id", inboxItemID),
				slog.String("raw_flag_id", *rawFlag),
			)
		}
	}

	var subflagID *string
	if rawSubflag != nil {
		entry, ok := subflagIndex[strings.ToLower(*rawSubflag)]
		valid := ok && (flagID == nil || entry.FlagID == *flagID)
		if !valid {
			slog.Warn("inbox_suggestion_subflag_id_discarded",
				slog.String("user_id", userID),
				slog.String("inbox_item_id", inboxItemID),
				slog.String("raw_subflag_id", *rawSubflag),
			)
		} else {
			resolvedSubflagID := entry.SubflagID
			subflagID = &resolvedSubflagID
			if flagID == nil {
				resolvedFlagID := entry.FlagID
				flagID = &resolvedFlagID
			}
		}
	}

	return flagID, subflagID
}

// failInboxProcessing handles AI-side failures during reprocessing: the model didn't
// answer, or its output couldn't be salvaged even with fallbacks. This is treated as an
// expected, recoverable outcome — we park the item in NEEDS_REVIEW with the cause recorded
// in LastError and return a nil error, so the HTTP layer replies 200 with the degraded item
// instead of a 500. Do not use this for persistence/DB failures; see failInboxPersistence.
func (uc *InboxUsecase) failInboxProcessing(ctx context.Context, item domain.InboxItem, cause error) (InboxItemResult, error) {
	errText := cause.Error()
	if len(errText) > 500 {
		errText = errText[:500]
	}
	item.Status = domain.InboxStatusNeedsReview
	item.LastError = &errText
	updated, err := uc.Inbox.Update(ctx, item)
	if err != nil {
		return InboxItemResult{}, err
	}
	return InboxItemResult{Item: updated}, nil
}

// failInboxPersistence handles failures that happen on OUR side after the AI has already
// produced a usable output: reading the user's flags/subflags/rules, or writing the
// suggestion/confirmed entities back to Postgres. Unlike failInboxProcessing, this is not an
// expected outcome — it's a backend error the caller should be told about — so it preserves
// and returns the original cause (the HTTP layer will surface a 5xx). The critical part is
// that it still flips the item out of PROCESSING and records LastError first: the earlier
// "item.Status = PROCESSING" update (right after Get) was committed in its own transaction,
// so nothing rolls that back for us. Without this, any error past that point leaves the item
// stuck in PROCESSING forever even though the HTTP response correctly reports failure.
func (uc *InboxUsecase) failInboxPersistence(ctx context.Context, item domain.InboxItem, cause error) (InboxItemResult, error) {
	errText := cause.Error()
	if len(errText) > 500 {
		errText = errText[:500]
	}
	item.Status = domain.InboxStatusNeedsReview
	item.LastError = &errText
	if _, updateErr := uc.Inbox.Update(ctx, item); updateErr != nil {
		// Best effort: recovering the item also failed (e.g. DB is genuinely down). There's
		// nothing else we can do here except make it loud instead of silent — this is exactly
		// the failure mode that used to leave items stuck in PROCESSING unnoticed. Surface the
		// original cause that triggered the failure to the caller.
		slog.Warn("inbox_item_recovery_update_failed",
			slog.String("user_id", item.UserID),
			slog.String("inbox_item_id", item.ID),
			slog.String("cause", cause.Error()),
			slog.String("update_error", updateErr.Error()),
		)
		return InboxItemResult{}, cause
	}
	return InboxItemResult{}, cause
}

func normalizeValidatedOutput(vout *service.ValidatedOutput, rawText string) {
	if vout == nil {
		return
	}
	vout.Output.Title = normalizeString(vout.Output.Title)
	if strings.EqualFold(strings.TrimSpace(vout.Output.Type), string(domain.AiSuggestionTypeShopping)) {
		vout.Output.Title = normalizeShoppingListTitle(vout.Output.Title, rawText, vout.Payload)
	}
}

func normalizeShoppingListTitle(title, rawText string, payload any) string {
	base := normalizeString(title)
	lowerTitle := strings.ToLower(base)
	lowerRaw := strings.ToLower(rawText)

	shouldUseGeneric := false
	if strings.Contains(lowerRaw, "lista de compras") || strings.Contains(lowerRaw, "lista compras") {
		shouldUseGeneric = true
	}
	if strings.HasPrefix(lowerTitle, "comprar ") || strings.HasPrefix(lowerTitle, "buy ") {
		shouldUseGeneric = true
	}

	if p, ok := payload.(service.ShoppingPayload); ok && len(p.Items) > 0 {
		if len(p.Items) == 1 {
			itemTitle := strings.ToLower(strings.TrimSpace(p.Items[0].Title))
			if itemTitle != "" && (lowerTitle == itemTitle || lowerTitle == "comprar "+itemTitle) {
				shouldUseGeneric = true
			}
		}
	}

	if shouldUseGeneric || base == "" {
		return "Lista de compras"
	}
	return base
}

func outputsNeedReview(outputs []service.ValidatedOutput) bool {
	for _, vout := range outputs {
		if vout.Output.NeedsReview {
			return true
		}
	}
	return false
}

func (uc *InboxUsecase) expandValidatedOutputsByClauses(ctx context.Context, input service.PromptInput) ([]service.ValidatedOutput, error) {
	if uc.AIClient == nil || uc.PromptBuilder == nil || uc.SchemaValidator == nil {
		return nil, ErrDependencyMissing
	}

	clauses := splitAtomicActionClauses(input.RawText)
	if len(clauses) <= 1 {
		return nil, nil
	}

	expanded := make([]service.ValidatedOutput, 0, len(clauses))
	for _, clause := range clauses {
		clauseInput := input
		clauseInput.RawText = clause
		prompt := uc.PromptBuilder.Build(clauseInput)
		completion, err := uc.AIClient.Complete(ctx, prompt)
		if err != nil {
			continue
		}
		validated, err := uc.SchemaValidator.ValidateMany([]byte(completion.Content))
		if err != nil || len(validated) == 0 {
			continue
		}
		expanded = append(expanded, validated[0])
	}

	expanded = dedupeValidatedOutputs(expanded)
	if len(expanded) <= 1 {
		return nil, nil
	}
	return expanded, nil
}

func splitAtomicActionClauses(rawText string) []string {
	clean := strings.Join(strings.Fields(strings.TrimSpace(rawText)), " ")
	if clean == "" {
		return nil
	}

	markers := []string{
		" e também ",
		" e tambem ",
		" e adicione ",
		" e adicionar ",
		" e inclua ",
		" e incluir ",
		" e me lembre ",
		" e lembre ",
		" e tenho ",
		" e preciso ",
		" e quero ",
		" e agende ",
		" e marque ",
	}

	clauses := []string{clean}
	for {
		changed := false
		next := make([]string, 0, len(clauses)+1)

		for _, clause := range clauses {
			lower := strings.ToLower(clause)
			markerIdx := -1
			for _, marker := range markers {
				if idx := strings.Index(lower, marker); idx > 0 && (markerIdx == -1 || idx < markerIdx) {
					markerIdx = idx
				}
			}
			if markerIdx < 0 {
				next = append(next, strings.TrimSpace(clause))
				continue
			}

			left := strings.TrimSpace(clause[:markerIdx])
			rightStart := markerIdx + len(" e ")
			right := strings.TrimSpace(clause[rightStart:])
			if left != "" {
				next = append(next, left)
			}
			if right != "" {
				next = append(next, right)
			}
			changed = true
		}

		clauses = next
		if !changed {
			break
		}
	}

	seen := make(map[string]struct{}, len(clauses))
	out := make([]string, 0, len(clauses))
	for _, clause := range clauses {
		normalized := strings.TrimSpace(clause)
		if normalized == "" {
			continue
		}
		key := strings.ToLower(normalized)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, normalized)
	}

	return out
}

func dedupeValidatedOutputs(outputs []service.ValidatedOutput) []service.ValidatedOutput {
	if len(outputs) <= 1 {
		return outputs
	}
	seen := make(map[string]struct{}, len(outputs))
	deduped := make([]service.ValidatedOutput, 0, len(outputs))

	for _, vout := range outputs {
		key := strings.ToLower(strings.TrimSpace(vout.Output.Type)) + "|" +
			strings.ToLower(strings.TrimSpace(vout.Output.Title)) + "|" +
			strings.TrimSpace(string(vout.Output.Payload))
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		deduped = append(deduped, vout)
	}
	return deduped
}

func fixWeekdayMismatch(start *time.Time, end *time.Time, rawText string, now time.Time) {
	if start == nil {
		return
	}
	if hasExplicitDate(rawText) {
		return
	}

	weekday, ok := detectSingleWeekdayMention(rawText)
	if !ok {
		return
	}

	loc := now.Location()
	startLocal := start.In(loc)
	if startLocal.Weekday() == weekday {
		return
	}

	// Build the next occurrence for the requested weekday.
	nextDate := nextOccurrenceOfWeekday(now, weekday)

	fixedStart := time.Date(
		nextDate.Year(), nextDate.Month(), nextDate.Day(),
		startLocal.Hour(), startLocal.Minute(), startLocal.Second(), startLocal.Nanosecond(),
		loc,
	)

	// Preserve duration if we have an end.
	if end != nil {
		endLocal := end.In(loc)
		dur := endLocal.Sub(startLocal)
		fixedEnd := fixedStart.Add(dur)
		*end = fixedEnd
	}

	*start = fixedStart
}

func hasExplicitDate(text string) bool {
	lower := strings.ToLower(text)
	// very lightweight checks
	if regexp.MustCompile(`\b\d{4}-\d{2}-\d{2}\b`).FindStringIndex(lower) != nil {
		return true
	}
	if regexp.MustCompile(`\b\d{1,2}/\d{1,2}(?:/\d{2,4})?\b`).FindStringIndex(lower) != nil {
		return true
	}
	return false
}

func detectSingleWeekdayMention(text string) (time.Weekday, bool) {
	lower := strings.ToLower(text)
	// Map of portuguese weekday tokens.
	tokens := map[time.Weekday][]string{
		time.Sunday:    {"domingo"},
		time.Monday:    {"segunda"},
		time.Tuesday:   {"terça", "terca"},
		time.Wednesday: {"quarta"},
		time.Thursday:  {"quinta"},
		time.Friday:    {"sexta"},
		time.Saturday:  {"sábado", "sabado"},
	}

	found := []time.Weekday{}
	for wd, list := range tokens {
		for _, t := range list {
			if regexp.MustCompile(`\b`+regexp.QuoteMeta(t)+`(\-feira)?\b`).FindStringIndex(lower) != nil {
				found = append(found, wd)
				break
			}
		}
	}

	if len(found) != 1 {
		return time.Sunday, false
	}
	return found[0], true
}

func nextOccurrenceOfWeekday(now time.Time, target time.Weekday) time.Time {
	start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	nowWd := start.Weekday()
	delta := (int(target) - int(nowWd) + 7) % 7
	// If it's today, keep today only if the time hasn't passed. We'll handle this by
	// allowing today and letting the fixedStart use the AI time.
	if delta == 0 {
		return start
	}
	return start.AddDate(0, 0, delta)
}
