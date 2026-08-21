package usecase

import (
	"context"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/app/service"
)

// applyValidatedSuggestionTx turns one validated AI output into a real entity,
// inside the caller's transaction.
//
// Each case runs the entity usecase on a COPY whose repository is swapped for the
// transactional one. That copy must also have NotificationCopy zeroed: Create
// spawns a goroutine that calls <Entity>.UpdateNotificationCopy on a background
// context, and on the copy that repository is the *sql.Tx. The goroutine would
// then write through the transaction concurrently with it -- and, because
// GenerateCopy is a real AI round-trip, usually after Commit as well. That is what
// produced the 500 "driver: bad connection" on multi-clause input: 70% with two
// entities in one transaction, 100% with three or more. The guard inside Create
// (`if uc.NotificationCopy != nil`) makes the goroutine simply not exist here.
// The copy is regenerated after the transaction commits, over the pool, by
// InboxUsecase.scheduleNotificationCopy.
//
// Shopping has no case below because it is written repo-level (tx.ShoppingLists /
// tx.ShoppingItems) with no usecase and no goroutine -- which is why it was the
// only type that never failed.
func (uc *InboxUsecase) applyValidatedSuggestionTx(ctx context.Context, tx repository.TxRepositories, userID string, item domain.InboxItem, vout service.ValidatedOutput) (ConfirmResult, error) {
	typ, ok := parseSuggestionType(vout.Output.Type)
	if !ok || typ == domain.AiSuggestionTypeNote {
		return ConfirmResult{}, ErrInvalidType
	}

	switch typ {
	case domain.AiSuggestionTypeTask:
		if tx.Tasks == nil || uc.TasksUsecase == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.TaskPayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		taskUC := *uc.TasksUsecase
		taskUC.Tasks = tx.Tasks
		taskUC.NotificationCopy = nil
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		task, err := taskUC.Create(ctx, userID, vout.Output.Title, nil, nil, p.DueAt, fID, sfID, &item.ID)
		if err != nil {
			return ConfirmResult{}, err
		}
		return ConfirmResult{Type: typ, Task: &task}, nil

	case domain.AiSuggestionTypeReminder:
		if tx.Reminders == nil || uc.RemindersUsecase == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.ReminderPayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		remUC := *uc.RemindersUsecase
		remUC.Reminders = tx.Reminders
		remUC.NotificationCopy = nil
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		reminder, err := remUC.Create(ctx, userID, vout.Output.Title, nil, &p.At, fID, sfID, &item.ID)
		if err != nil {
			return ConfirmResult{}, err
		}
		return ConfirmResult{Type: typ, Reminder: &reminder}, nil

	case domain.AiSuggestionTypeEvent:
		if tx.Events == nil || uc.EventsUsecase == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.EventPayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		eventUC := *uc.EventsUsecase
		eventUC.Events = tx.Events
		eventUC.NotificationCopy = nil
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		event, err := eventUC.Create(ctx, userID, vout.Output.Title, &p.Start, p.End, &p.AllDay, nil, fID, sfID, &item.ID)
		if err != nil {
			return ConfirmResult{}, err
		}
		return ConfirmResult{Type: typ, Event: &event}, nil

	case domain.AiSuggestionTypeRoutine:
		if uc.RoutinesUsecase == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.RoutinePayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		routineUC := *uc.RoutinesUsecase
		routineUC.Routines = tx.Routines
		routineUC.NotificationCopy = nil
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		routine, err := routineUC.Create(ctx, userID, RoutineInput{
			Title:             vout.Output.Title,
			RecurrenceType:    p.RecurrenceType,
			Weekdays:          p.Weekdays,
			StartTime:         p.StartTime,
			EndTime:           p.EndTime,
			WeekOfMonth:       p.WeekOfMonth,
			DayOfMonth:        p.DayOfMonth,
			StartsOn:          p.StartsOn,
			EndsOn:            p.EndsOn,
			FlagID:            fID,
			SubflagID:         sfID,
			SourceInboxItemID: &item.ID,
		})
		if err != nil {
			return ConfirmResult{}, err
		}
		return ConfirmResult{Type: typ, Routine: &routine}, nil

	case domain.AiSuggestionTypeShopping:
		// Shopping stays repo-level.
		if tx.ShoppingLists == nil || tx.ShoppingItems == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.ShoppingPayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		list := domain.ShoppingList{UserID: userID, Title: vout.Output.Title, SourceInboxItemID: &item.ID}
		createdList, err := tx.ShoppingLists.Create(ctx, list)
		if err != nil {
			return ConfirmResult{}, err
		}
		createdItems := make([]domain.ShoppingItem, 0, len(p.Items))
		for idx, shopItem := range p.Items {
			si := domain.ShoppingItem{UserID: userID, ListID: createdList.ID, Title: shopItem.Title, Quantity: shopItem.Quantity, Checked: false, SortOrder: idx}
			createdItem, err := tx.ShoppingItems.Create(ctx, si)
			if err != nil {
				return ConfirmResult{}, err
			}
			createdItems = append(createdItems, createdItem)
		}
		return ConfirmResult{Type: typ, ShoppingList: &createdList, ShoppingItems: createdItems}, nil
	default:
		return ConfirmResult{}, ErrInvalidType
	}
}

func (uc *InboxUsecase) applyValidatedSuggestionNoTx(ctx context.Context, userID string, item domain.InboxItem, vout service.ValidatedOutput) (ConfirmResult, error) {
	// Best-effort fallback. In production, TxRunner should be configured.
	typ, ok := parseSuggestionType(vout.Output.Type)
	if !ok || typ == domain.AiSuggestionTypeNote {
		return ConfirmResult{}, ErrInvalidType
	}

	switch typ {
	case domain.AiSuggestionTypeTask:
		if uc.TasksUsecase == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.TaskPayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		task, err := uc.TasksUsecase.Create(ctx, userID, vout.Output.Title, nil, nil, p.DueAt, fID, sfID, &item.ID)
		if err != nil {
			return ConfirmResult{}, err
		}
		return ConfirmResult{Type: typ, Task: &task}, nil
	case domain.AiSuggestionTypeReminder:
		if uc.RemindersUsecase == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.ReminderPayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		reminder, err := uc.RemindersUsecase.Create(ctx, userID, vout.Output.Title, nil, &p.At, fID, sfID, &item.ID)
		if err != nil {
			return ConfirmResult{}, err
		}
		return ConfirmResult{Type: typ, Reminder: &reminder}, nil
	case domain.AiSuggestionTypeEvent:
		if uc.EventsUsecase == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.EventPayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		event, err := uc.EventsUsecase.Create(ctx, userID, vout.Output.Title, &p.Start, p.End, &p.AllDay, nil, fID, sfID, &item.ID)
		if err != nil {
			return ConfirmResult{}, err
		}
		return ConfirmResult{Type: typ, Event: &event}, nil
	case domain.AiSuggestionTypeRoutine:
		if uc.RoutinesUsecase == nil {
			return ConfirmResult{}, ErrDependencyMissing
		}
		p, ok := vout.Payload.(service.RoutinePayload)
		if !ok {
			return ConfirmResult{}, ErrInvalidPayload
		}
		var fID, sfID *string
		if vout.Output.Context != nil {
			fID = normalizeOptionalString(vout.Output.Context.FlagID)
			sfID = normalizeOptionalString(vout.Output.Context.SubflagID)
		}
		routine, err := uc.RoutinesUsecase.Create(ctx, userID, RoutineInput{
			Title:             vout.Output.Title,
			RecurrenceType:    p.RecurrenceType,
			Weekdays:          p.Weekdays,
			StartTime:         p.StartTime,
			EndTime:           p.EndTime,
			WeekOfMonth:       p.WeekOfMonth,
			DayOfMonth:        p.DayOfMonth,
			StartsOn:          p.StartsOn,
			EndsOn:            p.EndsOn,
			FlagID:            fID,
			SubflagID:         sfID,
			SourceInboxItemID: &item.ID,
		})
		if err != nil {
			return ConfirmResult{}, err
		}
		return ConfirmResult{Type: typ, Routine: &routine}, nil
	case domain.AiSuggestionTypeShopping:
		// Keep existing non-tx behavior.
		return ConfirmResult{}, ErrDependencyMissing
	default:
		return ConfirmResult{}, ErrInvalidType
	}
}
