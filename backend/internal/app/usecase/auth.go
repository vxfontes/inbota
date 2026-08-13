package usecase

import (
	"context"
	"errors"
	"strings"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/app/service"
	"organiq/backend/internal/infra/postgres"
)

var ErrInvalidCredentials = errors.New("invalid_credentials")

// AuthUsecase handles signup/login flows.
type AuthUsecase struct {
	Users             repository.UserRepository
	Auth              *service.AuthService
	NotificationPrefs repository.NotificationPreferencesRepository
	Flags             repository.FlagRepository
	TxRunner          repository.AuthTxRunner
}

// defaultFlagNames are seeded for every new account so the app never starts
// completely empty. Kept short and generic on purpose (pt-BR): the goal is a
// starting point, not pre-configuring the user's life. Users can rename or
// delete any of these afterwards; deleting a flag is a normal app action.
var defaultFlagNames = []string{"Pessoal", "Trabalho", "Casa"}

func (uc *AuthUsecase) Signup(ctx context.Context, email, password, displayName, locale, timezone string) (domain.User, string, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	displayName = strings.TrimSpace(displayName)
	locale = strings.TrimSpace(locale)
	timezone = strings.TrimSpace(timezone)
	if email == "" || password == "" || displayName == "" || locale == "" || timezone == "" {
		return domain.User{}, "", ErrMissingRequiredFields
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

	userInput := domain.User{
		Email:       email,
		DisplayName: displayName,
		Password:    hash,
		Locale:      locale,
		Timezone:    timezone,
	}

	var created domain.User

	doSignup := func(ctx context.Context, users repository.UserRepository, prefs repository.NotificationPreferencesRepository, flags repository.FlagRepository) error {
		var err error
		created, err = users.Create(ctx, userInput)
		if err != nil {
			if errors.Is(err, postgres.ErrEmailAlreadyExists) {
				return ErrEmailAlreadyExists
			}
			return err
		}

		defaultPrefs := domain.NotificationPreferences{
			UserID:            created.ID,
			RemindersEnabled:  true,
			ReminderAtTime:    true,
			ReminderLeadMins:  []int{5, 15},
			EventsEnabled:     true,
			EventAtTime:       true,
			EventLeadMins:     []int{15, 60, 1440},
			TasksEnabled:      true,
			TaskAtTime:        true,
			TaskLeadMins:      []int{60, 1440},
			RoutinesEnabled:   true,
			RoutineAtTime:     true,
			RoutineLeadMins:   []int{15},
			QuietHoursEnabled: false,
		}
		if err := prefs.Upsert(ctx, defaultPrefs); err != nil {
			return err
		}

		return seedDefaultFlags(ctx, flags, created.ID)
	}

	if uc.TxRunner != nil {
		if err := uc.TxRunner.WithAuthTx(ctx, func(tx repository.AuthTxRepositories) error {
			return doSignup(ctx, tx.Users, tx.NotificationPrefs, tx.Flags)
		}); err != nil {
			return domain.User{}, "", err
		}
	} else {
		if err := doSignup(ctx, uc.Users, uc.NotificationPrefs, uc.Flags); err != nil {
			return domain.User{}, "", err
		}
	}

	token, err := uc.Auth.SignToken(created.ID)
	if err != nil {
		return domain.User{}, "", err
	}
	return created, token, nil
}

// seedDefaultFlags creates the starter set of flags for a brand-new user.
// It must only ever be called from Signup (never from Login), otherwise
// existing accounts would accumulate duplicate flags on every login.
func seedDefaultFlags(ctx context.Context, flags repository.FlagRepository, userID string) error {
	for i, name := range defaultFlagNames {
		if _, err := flags.Create(ctx, domain.Flag{
			UserID:    userID,
			Name:      name,
			SortOrder: i,
		}); err != nil {
			return err
		}
	}
	return nil
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
