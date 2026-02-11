package usecase

import (
	"context"
	"errors"
	"strings"
	"time"

	"inbota/backend/internal/app/domain"
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

func (uc *AuthUsecase) Signup(ctx context.Context, email, password, displayName, locale, timezone string) (domain.User, string, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	displayName = strings.TrimSpace(displayName)
	locale = strings.TrimSpace(locale)
	timezone = strings.TrimSpace(timezone)
	if email == "" || password == "" || displayName == "" || locale == "" || timezone == "" {
		return domain.User{}, "", errors.New("missing_required_fields")
	}
	if !validateEmail(email) {
		return domain.User{}, "", ErrInvalidEmail
	}
	if !validatePassword(password) {
		return domain.User{}, "", ErrInvalidPassword
	}
	if !validateDisplayName(displayName) {
		return domain.User{}, "", ErrInvalidDisplayName
	}

	hash, err := uc.Auth.HashPassword(password)
	if err != nil {
		return domain.User{}, "", err
	}

	user := domain.User{
		Email:       email,
		DisplayName: displayName,
		Password:    hash,
		Locale:      locale,
		Timezone:    timezone,
	}
	created, err := uc.Users.Create(ctx, user)
	if err != nil {
		return domain.User{}, "", err
	}

	token, err := uc.Auth.SignToken(created.ID)
	if err != nil {
		return domain.User{}, "", err
	}
	return created, token, nil
}

func (uc *AuthUsecase) Login(ctx context.Context, email, password string) (domain.User, string, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	if email == "" || password == "" {
		return domain.User{}, "", ErrInvalidCredentials
	}

	user, err := uc.Users.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, postgres.ErrUserNotFound) {
			return domain.User{}, "", ErrInvalidCredentials
		}
		return domain.User{}, "", err
	}

	if err := uc.Auth.ComparePassword(user.Password, password); err != nil {
		return domain.User{}, "", ErrInvalidCredentials
	}

	token, err := uc.Auth.SignToken(user.ID)
	if err != nil {
		return domain.User{}, "", err
	}
	return user, token, nil
}

// Default token TTL for MVP.
const DefaultTokenTTL = 30 * 24 * time.Hour
