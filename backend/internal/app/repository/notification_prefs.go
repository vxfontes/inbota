package repository

import (
	"context"

	"inbota/backend/internal/app/domain"
)

type NotificationPreferencesRepository interface {
	GetByUserID(ctx context.Context, userID string) (domain.NotificationPreferences, error)
	Upsert(ctx context.Context, prefs domain.NotificationPreferences) error
	ListEnabled(ctx context.Context) ([]domain.NotificationPreferences, error)
}
