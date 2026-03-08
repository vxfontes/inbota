package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type InboxListFilter struct {
	Status *domain.InboxStatus
	Source *domain.InboxSource
}

type InboxWithSuggestion struct {
	domain.InboxItem
	SuggestionID         *string  `db:"suggestion_id"`
	SuggestionType       *string  `db:"suggestion_type"`
	SuggestionTitle      *string  `db:"suggestion_title"`
	SuggestionConfidence *float64 `db:"suggestion_confidence"`
	PayloadJSON          []byte   `db:"payload_json"`
}

type InboxRepository interface {
	Create(ctx context.Context, item domain.InboxItem) (domain.InboxItem, error)
	Update(ctx context.Context, item domain.InboxItem) (domain.InboxItem, error)
	Get(ctx context.Context, userID, id string) (domain.InboxItem, error)
	GetByIDs(ctx context.Context, userID string, ids []string) ([]domain.InboxItem, error)
	List(ctx context.Context, userID string, filter InboxListFilter, opts ListOptions) ([]domain.InboxItem, *string, error)
	ListWithSuggestion(ctx context.Context, userID string, filter InboxListFilter, opts ListOptions) ([]InboxWithSuggestion, *string, error)
	GetWithSuggestion(ctx context.Context, userID, id string) (InboxWithSuggestion, error)
}
