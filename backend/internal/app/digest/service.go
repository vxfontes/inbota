package digest

import (
	"bytes"
	"context"
	"fmt"
	htmltemplate "html/template"
	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/infra/mailer"
	"log/slog"
	"sort"
	"strings"
	texttemplate "text/template"
	"time"
)

const (
	digestTypeDaily      = "daily_digest"
	maxDigestPageSize    = 200
	defaultDigestSubject = "Seu dia no Inbota"
)

type DigestService struct {
	userRepo         repository.UserRepository
	notifPrefsRepo   repository.NotificationPreferencesRepository
	emailDigestRepo  repository.EmailDigestRepository
	agendaRepo       repository.AgendaRepository
	taskRepo         repository.TaskRepository
	shoppingListRepo repository.ShoppingListRepository
	shoppingItemRepo repository.ShoppingItemRepository
	mailer           mailer.Mailer
	htmlTemplate     *htmltemplate.Template
	textTemplate     *texttemplate.Template
	now              func() time.Time
	log              *slog.Logger
}

func NewDigestService(
	userRepo repository.UserRepository,
	notifPrefsRepo repository.NotificationPreferencesRepository,
	emailDigestRepo repository.EmailDigestRepository,
	agendaRepo repository.AgendaRepository,
	taskRepo repository.TaskRepository,
	shoppingListRepo repository.ShoppingListRepository,
	shoppingItemRepo repository.ShoppingItemRepository,
	mailClient mailer.Mailer,
) (*DigestService, error) {
	htmlTmpl, textTmpl, err := mailer.ParseDailyDigestTemplates()
	if err != nil {
		return nil, fmt.Errorf("parse digest templates: %w", err)
	}

	return &DigestService{
		userRepo:         userRepo,
		notifPrefsRepo:   notifPrefsRepo,
		emailDigestRepo:  emailDigestRepo,
		agendaRepo:       agendaRepo,
		taskRepo:         taskRepo,
		shoppingListRepo: shoppingListRepo,
		shoppingItemRepo: shoppingItemRepo,
		mailer:           mailClient,
		htmlTemplate:     htmlTmpl,
		textTemplate:     textTmpl,
		now:              time.Now,
		log:              slog.Default(),
	}, nil
}

type DigestData struct {
	Date             string
	HasAgenda        bool
	Agenda           []AgendaItemData
	HasReminders     bool
	Reminders        []ReminderItemData
	HasTasks         bool
	Tasks            []TaskItemData
	HasOpenTasks     bool
	OpenTasks        []TaskItemData
	HasShoppingLists bool
	ShoppingLists    []ShoppingListData
}

type AgendaItemData struct {
	Time  string
	Title string
	Flag  string
}

type ReminderItemData struct {
	Time  string
	Title string
}

type TaskItemData struct {
	DueTime string
	Title   string
}

type ShoppingListData struct {
	Title        string
	PendingCount int
}

func (s *DigestService) SetNow(nowFn func() time.Time) {
	if nowFn != nil {
		s.now = nowFn
	}
}

func (s *DigestService) SetLogger(logger *slog.Logger) {
	if logger != nil {
		s.log = logger
	}
}

func (s *DigestService) BuildDigestData(ctx context.Context, userID string, targetDate time.Time) (DigestData, error) {
	if targetDate.IsZero() {
		targetDate = s.now()
	}
	loc := targetDate.Location()

	data := DigestData{
		Date: targetDate.Format("02/01/2006"),
	}

	startOfDay := time.Date(targetDate.Year(), targetDate.Month(), targetDate.Day(), 0, 0, 0, 0, loc)
	endOfDay := startOfDay.Add(24 * time.Hour)

	agendaItems, err := s.agendaRepo.List(ctx, userID, repository.ListOptions{Limit: maxDigestPageSize})
	if err != nil {
		return DigestData{}, fmt.Errorf("list agenda: %w", err)
	}

	for _, item := range agendaItems {
		scheduledAt := item.ScheduledAt.In(loc)
		if scheduledAt.Before(startOfDay) || !scheduledAt.Before(endOfDay) {
			continue
		}

		flag := ""
		if item.FlagName != nil {
			flag = *item.FlagName
		}

		data.Agenda = append(data.Agenda, AgendaItemData{
			Time:  scheduledAt.Format("15:04"),
			Title: item.Title,
			Flag:  flag,
		})

		if item.ItemType == "reminder" {
			data.Reminders = append(data.Reminders, ReminderItemData{
				Time:  scheduledAt.Format("15:04"),
				Title: item.Title,
			})
		}
	}

	tasks, err := s.listAllTasks(ctx, userID)
	if err != nil {
		return DigestData{}, fmt.Errorf("list tasks: %w", err)
	}

	for _, t := range tasks {
		if t.Status != domain.TaskStatusOpen {
			continue
		}
		if t.DueAt == nil {
			data.OpenTasks = append(data.OpenTasks, TaskItemData{Title: t.Title})
			continue
		}
		dueAt := t.DueAt.In(loc)
		if dueAt.Before(startOfDay) || !dueAt.Before(endOfDay) {
			continue
		}
		data.Tasks = append(data.Tasks, TaskItemData{
			DueTime: dueAt.Format("15:04"),
			Title:   t.Title,
		})
	}

	lists, err := s.listAllShoppingLists(ctx, userID)
	if err != nil {
		return DigestData{}, fmt.Errorf("list shopping lists: %w", err)
	}

	for _, list := range lists {
		if list.Status != domain.ShoppingListStatusOpen {
			continue
		}

		items, err := s.listAllShoppingItems(ctx, userID, list.ID)
		if err != nil {
			return DigestData{}, fmt.Errorf("list shopping items for list %s: %w", list.ID, err)
		}

		pendingCount := 0
		for _, item := range items {
			if !item.Checked {
				pendingCount++
			}
		}
		if pendingCount == 0 {
			continue
		}

		data.ShoppingLists = append(data.ShoppingLists, ShoppingListData{
			Title:        list.Title,
			PendingCount: pendingCount,
		})
	}

	sort.Slice(data.Tasks, func(i, j int) bool {
		return data.Tasks[i].DueTime < data.Tasks[j].DueTime
	})
	sort.Slice(data.Reminders, func(i, j int) bool {
		return data.Reminders[i].Time < data.Reminders[j].Time
	})

	data.HasAgenda = len(data.Agenda) > 0
	data.HasReminders = len(data.Reminders) > 0
	data.HasTasks = len(data.Tasks) > 0
	data.HasOpenTasks = len(data.OpenTasks) > 0
	data.HasShoppingLists = len(data.ShoppingLists) > 0

	return data, nil
}

func (s *DigestService) ProcessPendingDigests(ctx context.Context) error {
	prefs, err := s.notifPrefsRepo.ListEnabled(ctx)
	if err != nil {
		return err
	}

	nowUTC := s.now().UTC()

	for _, p := range prefs {
		if p.DailyDigestHour < 0 || p.DailyDigestHour > 23 {
			s.log.Warn("invalid_daily_digest_hour", slog.String("user_id", p.UserID), slog.Int("hour", p.DailyDigestHour))
			continue
		}

		user, err := s.userRepo.Get(ctx, p.UserID)
		if err != nil {
			s.log.Error("digest_user_load_failed", slog.String("user_id", p.UserID), slog.String("error", err.Error()))
			continue
		}

		tz, err := time.LoadLocation(user.Timezone)
		if err != nil {
			s.log.Warn("digest_invalid_user_timezone", slog.String("user_id", user.ID), slog.String("timezone", user.Timezone))
			tz = time.UTC
		}

		userNow := nowUTC.In(tz)
		if userNow.Hour() < p.DailyDigestHour {
			continue
		}

		if err := s.SendDigest(ctx, user, userNow); err != nil {
			s.log.Error("digest_send_failed", slog.String("user_id", user.ID), slog.String("error", err.Error()))
		}
	}

	return nil
}

func (s *DigestService) SendDigest(ctx context.Context, user domain.User, date time.Time) error {
	return s.sendDigest(ctx, user, date, true)
}

func (s *DigestService) SendTestDigest(ctx context.Context, user domain.User, date time.Time) error {
	return s.sendDigest(ctx, user, date, false)
}

func (s *DigestService) SendTestDigestForUserID(ctx context.Context, userID string) error {
	if strings.TrimSpace(userID) == "" {
		return fmt.Errorf("user id is empty")
	}

	user, err := s.userRepo.Get(ctx, userID)
	if err != nil {
		return err
	}

	tz, err := time.LoadLocation(user.Timezone)
	if err != nil {
		tz = time.UTC
	}

	return s.SendTestDigest(ctx, user, s.now().In(tz))
}

func (s *DigestService) sendDigest(ctx context.Context, user domain.User, date time.Time, trackDelivery bool) error {
	email := strings.TrimSpace(user.Email)
	if email == "" {
		return fmt.Errorf("user email is empty")
	}
	if date.IsZero() {
		date = s.now()
	}

	var digestRecord *domain.EmailDigest
	if trackDelivery {
		digestRecord = &domain.EmailDigest{
			UserID:     user.ID,
			DigestDate: date,
			Type:       digestTypeDaily,
			Status:     domain.EmailDigestStatusPending,
		}

		created, err := s.emailDigestRepo.Create(ctx, digestRecord)
		if err != nil {
			return err
		}
		if !created {
			return nil
		}
	}

	data, err := s.BuildDigestData(ctx, user.ID, date)
	if err != nil {
		return s.failDigest(ctx, digestRecord, err)
	}

	htmlBody, textBody, err := s.renderDigest(data)
	if err != nil {
		return s.failDigest(ctx, digestRecord, err)
	}

	msgID, err := s.mailer.Send(ctx, mailer.SendRequest{
		To:      []string{email},
		Subject: buildDigestSubject(date),
		Html:    htmlBody,
		Text:    textBody,
	})
	if err != nil {
		return s.failDigest(ctx, digestRecord, err)
	}

	if digestRecord == nil {
		return nil
	}

	sentAt := s.now().UTC()
	digestRecord.Status = domain.EmailDigestStatusSuccess
	digestRecord.SentAt = &sentAt
	digestRecord.ProviderID = &msgID
	return s.emailDigestRepo.Update(ctx, digestRecord)
}

func (s *DigestService) renderDigest(data DigestData) (string, string, error) {
	var html bytes.Buffer
	if err := s.htmlTemplate.Execute(&html, data); err != nil {
		return "", "", fmt.Errorf("render digest html: %w", err)
	}

	var text bytes.Buffer
	if err := s.textTemplate.Execute(&text, data); err != nil {
		return "", "", fmt.Errorf("render digest text: %w", err)
	}

	return html.String(), text.String(), nil
}

func (s *DigestService) failDigest(ctx context.Context, digestRecord *domain.EmailDigest, cause error) error {
	if digestRecord == nil {
		return cause
	}

	digestRecord.Status = domain.EmailDigestStatusFailed
	msg := cause.Error()
	digestRecord.ErrorMsg = &msg

	if err := s.emailDigestRepo.Update(ctx, digestRecord); err != nil {
		return fmt.Errorf("%w (and failed to persist digest error: %v)", cause, err)
	}
	return cause
}

func (s *DigestService) listAllTasks(ctx context.Context, userID string) ([]domain.Task, error) {
	cursor := ""
	all := make([]domain.Task, 0)

	for {
		items, next, err := s.taskRepo.List(ctx, userID, repository.ListOptions{Limit: maxDigestPageSize, Cursor: cursor})
		if err != nil {
			return nil, err
		}
		all = append(all, items...)

		if next == nil || *next == "" {
			return all, nil
		}
		cursor = *next
	}
}

func (s *DigestService) listAllShoppingLists(ctx context.Context, userID string) ([]domain.ShoppingList, error) {
	cursor := ""
	all := make([]domain.ShoppingList, 0)

	for {
		items, next, err := s.shoppingListRepo.List(ctx, userID, repository.ListOptions{Limit: maxDigestPageSize, Cursor: cursor})
		if err != nil {
			return nil, err
		}
		all = append(all, items...)

		if next == nil || *next == "" {
			return all, nil
		}
		cursor = *next
	}
}

func (s *DigestService) listAllShoppingItems(ctx context.Context, userID, listID string) ([]domain.ShoppingItem, error) {
	cursor := ""
	all := make([]domain.ShoppingItem, 0)

	for {
		items, next, err := s.shoppingItemRepo.ListByList(ctx, userID, listID, repository.ListOptions{Limit: maxDigestPageSize, Cursor: cursor})
		if err != nil {
			return nil, err
		}
		all = append(all, items...)

		if next == nil || *next == "" {
			return all, nil
		}
		cursor = *next
	}
}

func buildDigestSubject(date time.Time) string {
	if date.IsZero() {
		return defaultDigestSubject
	}
	return fmt.Sprintf("%s — %s (%s)", defaultDigestSubject, date.Format("02/01"), weekdayPTBR(date.Weekday()))
}

func weekdayPTBR(w time.Weekday) string {
	switch w {
	case time.Monday:
		return "Segunda"
	case time.Tuesday:
		return "Terça"
	case time.Wednesday:
		return "Quarta"
	case time.Thursday:
		return "Quinta"
	case time.Friday:
		return "Sexta"
	case time.Saturday:
		return "Sábado"
	case time.Sunday:
		return "Domingo"
	default:
		return ""
	}
}
