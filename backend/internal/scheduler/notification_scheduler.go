package scheduler

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/infra/push"
)

type NotificationScheduler struct {
	Prefs     repository.NotificationPreferencesRepository
	Log       repository.NotificationLogRepository
	Tokens    repository.DeviceTokenRepository
	Users     repository.UserRepository
	Reminders repository.ReminderRepository
	Events    repository.EventRepository
	Tasks     repository.TaskRepository
	Routines  repository.RoutineRepository
	FCM       *push.FCMClient
	Logger    *slog.Logger
}

func (s *NotificationScheduler) Run(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	s.Logger.Info("notification_scheduler_started")

	for {
		select {
		case <-ticker.C:
			s.scheduleUpcoming(ctx)
			s.dispatch(ctx)
		case <-ctx.Done():
			return
		}
	}
}

func (s *NotificationScheduler) scheduleUpcoming(ctx context.Context) {
	now := time.Now()

	// 1. Reminders (2h lookahead)
	reminders, err := s.Reminders.ListUpcoming(ctx, now, now.Add(2*time.Hour))
	if err == nil {
		for _, r := range reminders {
			prefs, err := s.Prefs.GetByUserID(ctx, r.UserID)
			if err != nil || !prefs.RemindersEnabled {
				continue
			}

			// At time
			if prefs.ReminderAtTime {
				s.scheduleItem(ctx, r.UserID, domain.NotificationTypeReminder, r.ID, r.Title, "Lembrete agora", r.RemindAt, nil)
			}

			// Lead times
			for _, mins := range prefs.ReminderLeadMins {
				scheduledFor := r.RemindAt.Add(time.Duration(-mins) * time.Minute)
				if scheduledFor.After(now) {
					body := fmt.Sprintf("Lembrete em %d minutos", mins)
					s.scheduleItem(ctx, r.UserID, domain.NotificationTypeReminder, r.ID, r.Title, body, &scheduledFor, &mins)
				}
			}
		}
	}

	// 2. Events (24h lookahead)
	events, err := s.Events.ListUpcoming(ctx, now, now.Add(24*time.Hour))
	if err == nil {
		for _, e := range events {
			prefs, err := s.Prefs.GetByUserID(ctx, e.UserID)
			if err != nil || !prefs.EventsEnabled {
				continue
			}

			if prefs.EventAtTime {
				s.scheduleItem(ctx, e.UserID, domain.NotificationTypeEvent, e.ID, e.Title, "Evento começando agora", e.StartAt, nil)
			}

			for _, mins := range prefs.EventLeadMins {
				scheduledFor := e.StartAt.Add(time.Duration(-mins) * time.Minute)
				if scheduledFor.After(now) {
					body := fmt.Sprintf("Evento em %d minutos", mins)
					if mins >= 1440 {
						body = "Evento amanhã"
					}
					s.scheduleItem(ctx, e.UserID, domain.NotificationTypeEvent, e.ID, e.Title, body, &scheduledFor, &mins)
				}
			}
		}
	}

	// 3. Tasks (24h lookahead)
	tasks, err := s.Tasks.ListUpcoming(ctx, now, now.Add(24*time.Hour))
	if err == nil {
		for _, t := range tasks {
			prefs, err := s.Prefs.GetByUserID(ctx, t.UserID)
			if err != nil || !prefs.TasksEnabled {
				continue
			}

			if prefs.TaskAtTime {
				s.scheduleItem(ctx, t.UserID, domain.NotificationTypeTask, t.ID, t.Title, "Tarefa vence agora", t.DueAt, nil)
			}

			for _, mins := range prefs.TaskLeadMins {
				scheduledFor := t.DueAt.Add(time.Duration(-mins) * time.Minute)
				if scheduledFor.After(now) {
					body := fmt.Sprintf("Tarefa vence em %d minutos", mins)
					if mins >= 1440 {
						body = "Tarefa vence amanhã"
					}
					s.scheduleItem(ctx, t.UserID, domain.NotificationTypeTask, t.ID, t.Title, body, &scheduledFor, &mins)
				}
			}
		}
	}

	// 4. Routines (2h lookahead)
	weekday := int(now.Weekday())
	routines, err := s.Routines.ListAllByWeekday(ctx, weekday)
	if err == nil {
		for _, r := range routines {
			prefs, err := s.Prefs.GetByUserID(ctx, r.UserID)
			if err != nil || !prefs.RoutinesEnabled {
				continue
			}

			// Parse start time today
			startTime, err := time.Parse("15:04", r.StartTime)
			if err != nil {
				continue
			}
			scheduledFor := time.Date(now.Year(), now.Month(), now.Day(), startTime.Hour(), startTime.Minute(), 0, 0, now.Location())

			if prefs.RoutineAtTime {
				s.scheduleItem(ctx, r.UserID, domain.NotificationTypeRoutine, r.ID, r.Title, "Hora da sua rotina", &scheduledFor, nil)
			}

			for _, mins := range prefs.RoutineLeadMins {
				leadScheduledFor := scheduledFor.Add(time.Duration(-mins) * time.Minute)
				if leadScheduledFor.After(now) {
					body := fmt.Sprintf("Rotina em %d minutos", mins)
					s.scheduleItem(ctx, r.UserID, domain.NotificationTypeRoutine, r.ID, r.Title, body, &leadScheduledFor, &mins)
				}
			}
		}
	}
}

func (s *NotificationScheduler) scheduleItem(ctx context.Context, userID string, nType domain.NotificationType, refID string, title, body string, scheduledFor *time.Time, leadMins *int) {
	if scheduledFor == nil {
		return
	}

	exists, err := s.Log.Exists(ctx, refID, leadMins)
	if err != nil || exists {
		return
	}

	_, err = s.Log.Create(ctx, domain.NotificationLog{
		UserID:       userID,
		Type:         nType,
		ReferenceID:  refID,
		Title:        title,
		Body:         body,
		LeadMins:     leadMins,
		Status:       domain.NotificationStatusPending,
		ScheduledFor: *scheduledFor,
	})
	if err != nil {
		s.Logger.Error("schedule_error", slog.String("error", err.Error()), slog.String("ref_id", refID))
	}
}

func (s *NotificationScheduler) dispatch(ctx context.Context) {
	now := time.Now()
	pending, err := s.Log.ListPending(ctx, now)
	if err != nil {
		return
	}

	for _, l := range pending {
		s.dispatchOne(ctx, l)
	}
}

func (s *NotificationScheduler) dispatchOne(ctx context.Context, l domain.NotificationLog) {
	// 1. Get user tokens
	tokens, err := s.Tokens.ListByUserID(ctx, l.UserID)
	if err != nil || len(tokens) == 0 {
		return
	}

	// 2. Check quiet hours
	prefs, err := s.Prefs.GetByUserID(ctx, l.UserID)
	if err == nil && prefs.QuietHoursEnabled && prefs.QuietStart != nil && prefs.QuietEnd != nil {
		user, err := s.Users.Get(ctx, l.UserID)
		if err == nil {
			loc, err := time.LoadLocation(user.Timezone)
			if err == nil {
				nowUser := time.Now().In(loc)
				if s.isInsideQuietHours(nowUser, *prefs.QuietStart, *prefs.QuietEnd) {
					// Postpone to end of quiet hours
					s.postpone(ctx, l, *prefs.QuietEnd, loc)
					return
				}
			}
		}
	}

	// 3. Send
	data := map[string]string{
		"type":         string(l.Type),
		"reference_id": l.ReferenceID,
		"log_id":       l.ID,
	}
	if l.LeadMins != nil {
		data["lead_mins"] = fmt.Sprintf("%d", *l.LeadMins)
	}

	success := false
	for _, t := range tokens {
		err := s.FCM.Send(ctx, t.Token, l.Title, l.Body, data)
		if err == nil {
			success = true
		} else {
			s.Logger.Warn("fcm_send_error", slog.String("error", err.Error()), slog.String("token", t.Token))
			if push.IsTokenInvalid(err) {
				_ = s.Tokens.Deactivate(ctx, t.Token)
			}
		}
	}

	if success {
		_ = s.Log.UpdateStatus(ctx, l.ID, domain.NotificationStatusSent, nil)
	} else {
		msg := "failed to send to all devices"
		_ = s.Log.UpdateStatus(ctx, l.ID, domain.NotificationStatusFailed, &msg)
	}
}

func (s *NotificationScheduler) isInsideQuietHours(t time.Time, start, end string) bool {
	// start, end are "HH:MM"
	startTime, _ := time.Parse("15:04", start)
	endTime, _ := time.Parse("15:04", end)

	nowMinutes := t.Hour()*60 + t.Minute()
	startMinutes := startTime.Hour()*60 + startTime.Minute()
	endMinutes := endTime.Hour()*60 + endTime.Minute()

	if startMinutes < endMinutes {
		return nowMinutes >= startMinutes && nowMinutes < endMinutes
	}
	// Over midnight
	return nowMinutes >= startMinutes || nowMinutes < endMinutes
}

func (s *NotificationScheduler) postpone(ctx context.Context, l domain.NotificationLog, quietEnd string, loc *time.Location) {
	endTime, _ := time.Parse("15:04", quietEnd)
	now := time.Now().In(loc)
	scheduledFor := time.Date(now.Year(), now.Month(), now.Day(), endTime.Hour(), endTime.Minute(), 0, 0, loc)
	if scheduledFor.Before(now) {
		scheduledFor = scheduledFor.Add(24 * time.Hour)
	}

	_ = s.Log.UpdateScheduledFor(ctx, l.ID, scheduledFor.UTC())
	s.Logger.Info("notification_postponed", slog.String("id", l.ID), slog.Time("new_scheduled_for", scheduledFor))
}
