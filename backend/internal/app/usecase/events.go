package usecase

import (
	"context"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type EventUsecase struct {
	Events repository.EventRepository
}

type EventUpdateInput struct {
	Title    *string
	StartAt  *time.Time
	EndAt    *time.Time
	AllDay   *bool
	Location *string
}

func (uc *EventUsecase) Create(ctx context.Context, userID, title string, startAt, endAt *time.Time, allDay *bool, location *string) (domain.Event, error) {
	title = normalizeString(title)
	if userID == "" || title == "" {
		return domain.Event{}, ErrMissingRequiredFields
	}
	if startAt != nil && endAt != nil && endAt.Before(*startAt) {
		return domain.Event{}, ErrInvalidTimeRange
	}

	event := domain.Event{
		UserID:   userID,
		Title:    title,
		StartAt:  startAt,
		EndAt:    endAt,
		AllDay:   false,
		Location: normalizeOptionalString(location),
	}
	if allDay != nil {
		event.AllDay = *allDay
	}

	return uc.Events.Create(ctx, event)
}

func (uc *EventUsecase) Update(ctx context.Context, userID, id string, input EventUpdateInput) (domain.Event, error) {
	if userID == "" || id == "" {
		return domain.Event{}, ErrMissingRequiredFields
	}
	event, err := uc.Events.Get(ctx, userID, id)
	if err != nil {
		return domain.Event{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.Event{}, ErrMissingRequiredFields
		}
		event.Title = trimmed
	}
	if input.StartAt != nil {
		event.StartAt = input.StartAt
	}
	if input.EndAt != nil {
		event.EndAt = input.EndAt
	}
	if event.StartAt != nil && event.EndAt != nil && event.EndAt.Before(*event.StartAt) {
		return domain.Event{}, ErrInvalidTimeRange
	}
	if input.AllDay != nil {
		event.AllDay = *input.AllDay
	}
	if input.Location != nil {
		event.Location = normalizeOptionalString(input.Location)
	}

	return uc.Events.Update(ctx, event)
}

func (uc *EventUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Events.Delete(ctx, userID, id)
}

func (uc *EventUsecase) Get(ctx context.Context, userID, id string) (domain.Event, error) {
	if userID == "" || id == "" {
		return domain.Event{}, ErrMissingRequiredFields
	}
	return uc.Events.Get(ctx, userID, id)
}

func (uc *EventUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Event, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Events.List(ctx, userID, opts)
}
