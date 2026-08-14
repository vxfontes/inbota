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

// DeleteAccount permanently removes the authenticated user's account and
// everything they own, as required by App Store Guideline 5.1.1(v).
//
// It is deliberately a single repository call: every table referencing
// organiq.users(id) declares ON DELETE CASCADE, and Postgres applies a
// statement together with its cascades atomically. So there is no
// transaction here on purpose -- no closure means no way to accidentally
// reach for a second pooled connection while holding one.
//
// device_tokens is covered by that same cascade. The notification scheduler
// keeps no per-user state in memory (it caches only templates and config) and
// re-reads active tokens from the database for every notification, so a
// deleted account can never be pushed to.
//
// The JWT proves who is asking; the password proves they meant it. bcrypt
// runs before the DELETE and outside any transaction, because it burns
// ~100ms of CPU and must never hold a pooled connection while doing so.
func (uc *AuthUsecase) DeleteAccount(ctx context.Context, userID, password string) error {
	if uc.Users == nil || uc.Auth == nil {
		return ErrDependencyMissing
	}
	if strings.TrimSpace(userID) == "" || password == "" {
		return ErrMissingRequiredFields
	}

	user, err := uc.Users.Get(ctx, userID)
	if err != nil {
		// A valid JWT pointing at a row that no longer exists means the account
		// is already gone. That is an authentication problem, not a server
		// error, and the client is right to drop the token over it.
		if errors.Is(err, postgres.ErrUserNotFound) {
			return ErrInvalidCredentials
		}
		return err
	}

	if err := uc.Auth.ComparePassword(user.Password, password); err != nil {
		// Not ErrInvalidCredentials: the session is valid, only the
		// re-confirmation failed. Clients must not log the user out for a typo.
		return ErrIncorrectPassword
	}

	if err := uc.Users.Delete(ctx, userID); err != nil {
		if errors.Is(err, postgres.ErrUserNotFound) {
			return ErrInvalidCredentials
		}
		return err
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
