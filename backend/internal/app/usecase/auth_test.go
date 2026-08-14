package usecase

import (
	"context"
	"errors"
	"testing"
	"time"

	"golang.org/x/crypto/bcrypt"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/service"
	"organiq/backend/internal/infra/postgres"
)

type userRepoStub struct {
	getFn    func(ctx context.Context, id string) (domain.User, error)
	deleteFn func(ctx context.Context, id string) error
	deleted  []string
}

func (s *userRepoStub) Create(context.Context, domain.User) (domain.User, error) {
	return domain.User{}, errors.New("not implemented")
}

func (s *userRepoStub) Get(ctx context.Context, id string) (domain.User, error) {
	if s.getFn != nil {
		return s.getFn(ctx, id)
	}
	return domain.User{}, errors.New("not implemented")
}

func (s *userRepoStub) FindByEmail(context.Context, string) (domain.User, error) {
	return domain.User{}, errors.New("not implemented")
}

func (s *userRepoStub) Delete(ctx context.Context, id string) error {
	s.deleted = append(s.deleted, id)
	if s.deleteFn != nil {
		return s.deleteFn(ctx, id)
	}
	return nil
}

// hashFor produces a bcrypt hash at MinCost. CompareHashAndPassword reads the
// cost out of the hash itself, so this verifies exactly like a production hash
// without burning ~100ms per test.
func hashFor(t *testing.T, password string) string {
	t.Helper()
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.MinCost)
	if err != nil {
		t.Fatalf("hashing test password: %v", err)
	}
	return string(hash)
}

func newDeleteAccountUsecase(users *userRepoStub) *AuthUsecase {
	return &AuthUsecase{
		Users: users,
		Auth:  service.NewAuthService("test-secret", time.Hour),
	}
}

func TestDeleteAccountRemovesUserWhenPasswordMatches(t *testing.T) {
	const userID = "11111111-1111-1111-1111-111111111111"

	users := &userRepoStub{
		getFn: func(_ context.Context, id string) (domain.User, error) {
			if id != userID {
				t.Fatalf("expected lookup for %s, got %s", userID, id)
			}
			return domain.User{ID: userID, Password: hashFor(t, "senha-correta")}, nil
		},
	}

	if err := newDeleteAccountUsecase(users).DeleteAccount(context.Background(), userID, "senha-correta"); err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}

	if len(users.deleted) != 1 || users.deleted[0] != userID {
		t.Fatalf("expected exactly one delete of %s, got %v", userID, users.deleted)
	}
}

func TestDeleteAccountRejectsWrongPasswordWithoutDeleting(t *testing.T) {
	users := &userRepoStub{
		getFn: func(context.Context, string) (domain.User, error) {
			return domain.User{ID: "user-1", Password: hashFor(t, "senha-correta")}, nil
		},
	}

	err := newDeleteAccountUsecase(users).DeleteAccount(context.Background(), "user-1", "senha-errada")
	if !errors.Is(err, ErrIncorrectPassword) {
		t.Fatalf("expected ErrIncorrectPassword, got %v", err)
	}

	if len(users.deleted) != 0 {
		t.Fatalf("account must survive a wrong password, but Delete ran for %v", users.deleted)
	}
}

func TestDeleteAccountRequiresPasswordBeforeTouchingTheDatabase(t *testing.T) {
	users := &userRepoStub{
		getFn: func(context.Context, string) (domain.User, error) {
			t.Fatal("must not read the user before validating the payload")
			return domain.User{}, nil
		},
	}

	err := newDeleteAccountUsecase(users).DeleteAccount(context.Background(), "user-1", "")
	if !errors.Is(err, ErrMissingRequiredFields) {
		t.Fatalf("expected ErrMissingRequiredFields, got %v", err)
	}

	if len(users.deleted) != 0 {
		t.Fatalf("expected no delete, got %v", users.deleted)
	}
}

// A wrong password and an already-deleted account must NOT collapse into the
// same error. The app's HTTP client logs the user out on 401, so mapping a
// typo to ErrInvalidCredentials would kick a live account back to the login
// screen with no message. This test locks that distinction against regression.
func TestDeleteAccountDistinguishesWrongPasswordFromMissingAccount(t *testing.T) {
	wrongPassword := &userRepoStub{
		getFn: func(context.Context, string) (domain.User, error) {
			return domain.User{ID: "user-1", Password: hashFor(t, "senha-correta")}, nil
		},
	}
	wrongPasswordErr := newDeleteAccountUsecase(wrongPassword).DeleteAccount(context.Background(), "user-1", "senha-errada")

	missingAccount := &userRepoStub{
		getFn: func(context.Context, string) (domain.User, error) {
			return domain.User{}, postgres.ErrUserNotFound
		},
	}
	missingAccountErr := newDeleteAccountUsecase(missingAccount).DeleteAccount(context.Background(), "user-1", "qualquer-senha")

	if !errors.Is(wrongPasswordErr, ErrIncorrectPassword) {
		t.Fatalf("wrong password must be ErrIncorrectPassword (403), got %v", wrongPasswordErr)
	}
	if errors.Is(wrongPasswordErr, ErrInvalidCredentials) {
		t.Fatal("wrong password must never be ErrInvalidCredentials: that logs the user out of a live account")
	}
	if !errors.Is(missingAccountErr, ErrInvalidCredentials) {
		t.Fatalf("already-deleted account must be ErrInvalidCredentials (401), got %v", missingAccountErr)
	}
	if len(missingAccount.deleted) != 0 {
		t.Fatalf("expected no delete for a missing account, got %v", missingAccount.deleted)
	}
}

// The row can vanish between the read and the DELETE (concurrent double
// delete). That is the already-gone case, not a 500.
func TestDeleteAccountTreatsVanishedRowAsInvalidCredentials(t *testing.T) {
	users := &userRepoStub{
		getFn: func(context.Context, string) (domain.User, error) {
			return domain.User{ID: "user-1", Password: hashFor(t, "senha-correta")}, nil
		},
		deleteFn: func(context.Context, string) error {
			return postgres.ErrUserNotFound
		},
	}

	err := newDeleteAccountUsecase(users).DeleteAccount(context.Background(), "user-1", "senha-correta")
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials, got %v", err)
	}
}

func TestDeleteAccountPropagatesRepositoryFailure(t *testing.T) {
	dbDown := errors.New("connection refused")

	users := &userRepoStub{
		getFn: func(context.Context, string) (domain.User, error) {
			return domain.User{ID: "user-1", Password: hashFor(t, "senha-correta")}, nil
		},
		deleteFn: func(context.Context, string) error {
			return dbDown
		},
	}

	err := newDeleteAccountUsecase(users).DeleteAccount(context.Background(), "user-1", "senha-correta")
	if !errors.Is(err, dbDown) {
		t.Fatalf("expected the repository failure to propagate, got %v", err)
	}
}

func TestDeleteAccountRequiresDependencies(t *testing.T) {
	uc := &AuthUsecase{}
	if err := uc.DeleteAccount(context.Background(), "user-1", "senha"); !errors.Is(err, ErrDependencyMissing) {
		t.Fatalf("expected ErrDependencyMissing, got %v", err)
	}
}
