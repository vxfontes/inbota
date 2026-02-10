package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type InboxListFilter struct {
	Status *domain.InboxStatus
	Source *domain.InboxSource
}

type InboxRepository interface {
	Create(ctx context.Context, item domain.InboxItem) (domain.InboxItem, error)
	Update(ctx context.Context, item domain.InboxItem) (domain.InboxItem, error)
	Get(ctx context.Context, userID, id string) (domain.InboxItem, error)
	List(ctx context.Context, userID string, filter InboxListFilter, opts ListOptions) ([]domain.InboxItem, *string, error)
}
