package repository

import (
	"context"

	"organiq/backend/internal/app/domain"
)

type UserRepository interface {
	Create(ctx context.Context, user domain.User) (domain.User, error)
	Get(ctx context.Context, id string) (domain.User, error)
	FindByEmail(ctx context.Context, email string) (domain.User, error)
	// Delete removes the user row. Every table that references users(id) does
	// so with ON DELETE CASCADE, so this also removes everything the user owns.
	Delete(ctx context.Context, id string) error
}
