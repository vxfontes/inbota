package usecase

import (
	"context"
	"time"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type TaskUsecase struct {
	Tasks repository.TaskRepository
}

type TaskUpdateInput struct {
	Title       *string
	Description *string
	Status      *string
	DueAt       *time.Time
}

func (uc *TaskUsecase) Create(ctx context.Context, userID, title string, description *string, status *string, dueAt *time.Time) (domain.Task, error) {
	title = normalizeString(title)
	if userID == "" || title == "" {
		return domain.Task{}, ErrMissingRequiredFields
	}

	task := domain.Task{
		UserID:      userID,
		Title:       title,
		Description: description,
	}

	if status != nil {
		parsed, ok := parseTaskStatus(*status)
		if !ok {
			return domain.Task{}, ErrInvalidStatus
		}
		task.Status = parsed
	}
	task.DueAt = dueAt

	return uc.Tasks.Create(ctx, task)
}

func (uc *TaskUsecase) Update(ctx context.Context, userID, id string, input TaskUpdateInput) (domain.Task, error) {
	if userID == "" || id == "" {
		return domain.Task{}, ErrMissingRequiredFields
	}
	task, err := uc.Tasks.Get(ctx, userID, id)
	if err != nil {
		return domain.Task{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.Task{}, ErrMissingRequiredFields
		}
		task.Title = trimmed
	}
	if input.Description != nil {
		task.Description = input.Description
	}
	if input.Status != nil {
		parsed, ok := parseTaskStatus(*input.Status)
		if !ok {
			return domain.Task{}, ErrInvalidStatus
		}
		task.Status = parsed
	}
	if input.DueAt != nil {
		task.DueAt = input.DueAt
	}

	return uc.Tasks.Update(ctx, task)
}

func (uc *TaskUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Tasks.Delete(ctx, userID, id)
}

func (uc *TaskUsecase) Get(ctx context.Context, userID, id string) (domain.Task, error) {
	if userID == "" || id == "" {
		return domain.Task{}, ErrMissingRequiredFields
	}
	return uc.Tasks.Get(ctx, userID, id)
}

func (uc *TaskUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Task, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Tasks.List(ctx, userID, opts)
}
