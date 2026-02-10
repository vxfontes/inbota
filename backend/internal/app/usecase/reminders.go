package usecase

import (
	"context"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type ReminderUsecase struct {
	Reminders repository.ReminderRepository
}

type ReminderUpdateInput struct {
	Title    *string
	Status   *string
	RemindAt *time.Time
}

func (uc *ReminderUsecase) Create(ctx context.Context, userID, title string, status *string, remindAt *time.Time) (domain.Reminder, error) {
	title = normalizeString(title)
	if userID == "" || title == "" {
		return domain.Reminder{}, ErrMissingRequiredFields
	}

	reminder := domain.Reminder{
		UserID:   userID,
		Title:    title,
		RemindAt: remindAt,
	}

	if status != nil {
		parsed, ok := parseReminderStatus(*status)
		if !ok {
			return domain.Reminder{}, ErrInvalidStatus
		}
		reminder.Status = parsed
	}

	return uc.Reminders.Create(ctx, reminder)
}

func (uc *ReminderUsecase) Update(ctx context.Context, userID, id string, input ReminderUpdateInput) (domain.Reminder, error) {
	if userID == "" || id == "" {
		return domain.Reminder{}, ErrMissingRequiredFields
	}
	reminder, err := uc.Reminders.Get(ctx, userID, id)
	if err != nil {
		return domain.Reminder{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.Reminder{}, ErrMissingRequiredFields
		}
		reminder.Title = trimmed
	}
	if input.Status != nil {
		parsed, ok := parseReminderStatus(*input.Status)
		if !ok {
			return domain.Reminder{}, ErrInvalidStatus
		}
		reminder.Status = parsed
	}
	if input.RemindAt != nil {
		reminder.RemindAt = input.RemindAt
	}

	return uc.Reminders.Update(ctx, reminder)
}

func (uc *ReminderUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Reminders.Delete(ctx, userID, id)
}

func (uc *ReminderUsecase) Get(ctx context.Context, userID, id string) (domain.Reminder, error) {
	if userID == "" || id == "" {
		return domain.Reminder{}, ErrMissingRequiredFields
	}
	return uc.Reminders.Get(ctx, userID, id)
}

func (uc *ReminderUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Reminder, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Reminders.List(ctx, userID, opts)
}
