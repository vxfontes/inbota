package usecase

import (
	"context"
	"errors"
	"strings"
	"time"

	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/app/service"
	"inbota/backend/internal/infra/postgres"
)

var ErrInvalidCredentials = errors.New("invalid_credentials")

// AuthUsecase handles signup/login flows.
type AuthUsecase struct {
	Users repository.UserRepository
	Auth  *service.AuthService
}

func (uc *AuthUsecase) Signup(ctx context.Context, email, password, displayName, locale, timezone string) (repository.User, string, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	if email == "" || password == "" {
		return repository.User{}, "", errors.New("email_password_required")
	}

	hash, err := uc.Auth.HashPassword(password)
	if err != nil {
		return repository.User{}, "", err
	}

	user := repository.User{
		Email:       email,
		DisplayName: displayName,
		Password:    hash,
		Locale:      locale,
		Timezone:    timezone,
	}
	created, err := uc.Users.Create(ctx, user)
	if err != nil {
		return repository.User{}, "", err
	}

	token, err := uc.Auth.SignToken(created.ID)
	if err != nil {
		return repository.User{}, "", err
	}
	return created, token, nil
}

func (uc *AuthUsecase) Login(ctx context.Context, email, password string) (repository.User, string, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	if email == "" || password == "" {
		return repository.User{}, "", ErrInvalidCredentials
	}

	user, err := uc.Users.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, postgres.ErrUserNotFound) {
			return repository.User{}, "", ErrInvalidCredentials
		}
		return repository.User{}, "", err
	}

	if err := uc.Auth.ComparePassword(user.Password, password); err != nil {
		return repository.User{}, "", ErrInvalidCredentials
	}

	token, err := uc.Auth.SignToken(user.ID)
	if err != nil {
		return repository.User{}, "", err
	}
	return user, token, nil
}

// Default token TTL for MVP.
const DefaultTokenTTL = 30 * 24 * time.Hour
