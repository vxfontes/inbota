package postgres

import (
	"context"
	"database/sql"
	"errors"

	"inbota/backend/internal/app/domain"
)

var ErrUserNotFound = errors.New("user_not_found")

type UserRepository struct {
	db *DB
}

func NewUserRepository(db *DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, user domain.User) (domain.User, error) {
	row := r.db.QueryRowContext(ctx, `
		INSERT INTO inbota.users (email, display_name, password, locale, timezone)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
	`, user.Email, user.DisplayName, user.Password, user.Locale, user.Timezone)

	var id string
	if err := row.Scan(&id); err != nil {
		return domain.User{}, err
	}
	user.ID = id
	return user, nil
}

func (r *UserRepository) FindByEmail(ctx context.Context, email string) (domain.User, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, email, display_name, password, locale, timezone
		FROM inbota.users
		WHERE email = $1
		LIMIT 1
	`, email)

	var user domain.User
	if err := row.Scan(&user.ID, &user.Email, &user.DisplayName, &user.Password, &user.Locale, &user.Timezone); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return domain.User{}, ErrUserNotFound
		}
		return domain.User{}, err
	}
	return user, nil
}
