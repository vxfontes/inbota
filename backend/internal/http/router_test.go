package http_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/service"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/config"
	apphttp "organiq/backend/internal/http"
	"organiq/backend/internal/http/handler"
	"organiq/backend/internal/infra/postgres"
)

// These tests exercise DELETE /v1/me through the real router: real auth
// middleware, real rate limiter, real JSON binding, real error mapping. Only
// the user repository is stubbed.
//
// They exist because the status code is the contract. App Store Guideline
// 5.1.1(v) review hits the wrong-password path, and the Flutter client has a
// global interceptor that logs the user out on any 401 from an authenticated
// request. If this route ever answers 401 instead of 403 for a bad password,
// the reviewer sees an account deletion screen that silently logs them out
// instead of showing an error. Nothing below the HTTP layer can catch that
// regression, which is why these assert on the wire and not on sentinels.

const (
	testJWTSecret = "router-test-secret"
	testUserID    = "11111111-1111-1111-1111-111111111111"
	testPassword  = "senha-correta-123"
)

type deleteAccountUserRepo struct {
	getFn   func(ctx context.Context, id string) (domain.User, error)
	deleted []string
}

func (r *deleteAccountUserRepo) Create(context.Context, domain.User) (domain.User, error) {
	return domain.User{}, errors.New("not implemented")
}

func (r *deleteAccountUserRepo) Get(ctx context.Context, id string) (domain.User, error) {
	if r.getFn != nil {
		return r.getFn(ctx, id)
	}
	return domain.User{}, errors.New("not implemented")
}

func (r *deleteAccountUserRepo) FindByEmail(context.Context, string) (domain.User, error) {
	return domain.User{}, errors.New("not implemented")
}

func (r *deleteAccountUserRepo) Delete(_ context.Context, id string) error {
	r.deleted = append(r.deleted, id)
	return nil
}

// liveUserRepo returns a repo whose account exists and whose password is
// testPassword. bcrypt reads the cost out of the hash, so MinCost verifies
// exactly like a production hash without burning ~100ms per call.
func liveUserRepo(t *testing.T) *deleteAccountUserRepo {
	t.Helper()
	hash, err := bcrypt.GenerateFromPassword([]byte(testPassword), bcrypt.MinCost)
	if err != nil {
		t.Fatalf("hashing test password: %v", err)
	}
	return &deleteAccountUserRepo{
		getFn: func(_ context.Context, id string) (domain.User, error) {
			return domain.User{
				ID:          id,
				Email:       "descartavel@example.com",
				DisplayName: "Conta Descartavel",
				Password:    string(hash),
				Locale:      "pt-BR",
				Timezone:    "America/Sao_Paulo",
			}, nil
		},
	}
}

// newTestRouter builds the production router with a stubbed user repository and
// mints a real JWT for it. Each call gets a fresh engine, so the rate limiter
// (which keeps its counters in a closure) starts empty per test.
func newTestRouter(t *testing.T, users *deleteAccountUserRepo) (*gin.Engine, string) {
	t.Helper()
	gin.SetMode(gin.TestMode)

	auth := service.NewAuthService(testJWTSecret, time.Hour)
	handlers := &handler.APIHandlers{
		Me: handler.NewMeHandler(&usecase.AuthUsecase{Users: users, Auth: auth}),
	}
	cfg := config.Config{JWTSecret: testJWTSecret, RequestIDHeader: "X-Request-Id"}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))

	token, err := auth.SignToken(testUserID)
	if err != nil {
		t.Fatalf("signing test token: %v", err)
	}
	return apphttp.NewRouter(cfg, log, nil, handlers), token
}

func doRequest(t *testing.T, engine *gin.Engine, method, path, token, body string) *httptest.ResponseRecorder {
	t.Helper()
	var reader io.Reader
	if body != "" {
		reader = strings.NewReader(body)
	}
	req := httptest.NewRequest(method, path, reader)
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	rec := httptest.NewRecorder()
	engine.ServeHTTP(rec, req)
	return rec
}

// decodeError reads the error envelope as a raw map so the assertions bind to
// the JSON key names clients actually switch on, not to a Go struct that would
// happily unmarshal a renamed field into the same place.
func decodeError(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decoding error body %q: %v", rec.Body.String(), err)
	}
	if _, ok := payload["code"]; ok {
		t.Fatalf("error envelope must use the key \"error\", found \"code\" in %q", rec.Body.String())
	}
	if requestID, _ := payload["requestId"].(string); requestID == "" {
		t.Errorf("expected a non-empty requestId in %q", rec.Body.String())
	}
	return payload
}

func TestDeleteMeReturns204AndDeletesTheAccount(t *testing.T) {
	users := liveUserRepo(t)
	engine, token := newTestRouter(t, users)

	rec := doRequest(t, engine, http.MethodDelete, "/v1/me", token, `{"password":"`+testPassword+`"}`)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d with body %q", rec.Code, rec.Body.String())
	}
	if rec.Body.Len() != 0 {
		t.Errorf("expected an empty body on 204, got %q", rec.Body.String())
	}
	if len(users.deleted) != 1 || users.deleted[0] != testUserID {
		t.Errorf("expected the JWT subject to be deleted once, got %v", users.deleted)
	}
}

// The path an App Store reviewer takes: open account deletion, type the wrong
// password. It must answer 403 with a code distinct from the signup-policy
// "invalid_password", and the account must survive.
func TestDeleteMeReturns403OnIncorrectPasswordAndKeepsAccountAlive(t *testing.T) {
	users := liveUserRepo(t)
	engine, token := newTestRouter(t, users)

	rec := doRequest(t, engine, http.MethodDelete, "/v1/me", token, `{"password":"senha-errada"}`)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d with body %q", rec.Code, rec.Body.String())
	}
	payload := decodeError(t, rec)
	if got := payload["error"]; got != "incorrect_password" {
		t.Errorf("expected error \"incorrect_password\", got %v", got)
	}
	if len(users.deleted) != 0 {
		t.Fatalf("a wrong password must never delete anything, got %v", users.deleted)
	}

	// The session must still work: the whole reason this is 403 and not 401 is
	// that the user stays logged in after a typo.
	alive := doRequest(t, engine, http.MethodGet, "/v1/me", token, "")
	if alive.Code != http.StatusOK {
		t.Fatalf("expected the account to still be reachable with 200, got %d with body %q", alive.Code, alive.Body.String())
	}
}

// A token whose account no longer exists is a dead session: this one DOES have
// to answer 401 so the client discards the token and returns to login.
func TestDeleteMeReturns401WhenAccountAlreadyGone(t *testing.T) {
	users := &deleteAccountUserRepo{
		getFn: func(context.Context, string) (domain.User, error) {
			return domain.User{}, postgres.ErrUserNotFound
		},
	}
	engine, token := newTestRouter(t, users)

	rec := doRequest(t, engine, http.MethodDelete, "/v1/me", token, `{"password":"`+testPassword+`"}`)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d with body %q", rec.Code, rec.Body.String())
	}
	if got := decodeError(t, rec)["error"]; got != "invalid_credentials" {
		t.Errorf("expected error \"invalid_credentials\", got %v", got)
	}
	if len(users.deleted) != 0 {
		t.Errorf("nothing should be deleted when the account is already gone, got %v", users.deleted)
	}
}

func TestDeleteMeReturns400WhenPasswordIsMissing(t *testing.T) {
	cases := map[string]string{
		"empty object":   `{}`,
		"empty password": `{"password":""}`,
		"no body":        ``,
		"malformed json": `{"password":`,
	}

	for name, body := range cases {
		t.Run(name, func(t *testing.T) {
			users := liveUserRepo(t)
			engine, token := newTestRouter(t, users)

			rec := doRequest(t, engine, http.MethodDelete, "/v1/me", token, body)

			if rec.Code != http.StatusBadRequest {
				t.Fatalf("expected 400, got %d with body %q", rec.Code, rec.Body.String())
			}
			if got := decodeError(t, rec)["error"]; got != "invalid_payload" {
				t.Errorf("expected error \"invalid_payload\", got %v", got)
			}
			if len(users.deleted) != 0 {
				t.Errorf("a rejected payload must never delete anything, got %v", users.deleted)
			}
		})
	}
}

func TestDeleteMeRequiresAuthentication(t *testing.T) {
	users := liveUserRepo(t)
	engine, _ := newTestRouter(t, users)

	rec := doRequest(t, engine, http.MethodDelete, "/v1/me", "", `{"password":"`+testPassword+`"}`)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 without a token, got %d with body %q", rec.Code, rec.Body.String())
	}
	if len(users.deleted) != 0 {
		t.Errorf("an unauthenticated request must never delete anything, got %v", users.deleted)
	}
}

// A wrong password answers 403 while a right one deletes, which makes this
// route a password oracle exactly like login. The limiter is wired in
// router.go, so only a request through the router can prove it is there.
func TestDeleteMeIsRateLimited(t *testing.T) {
	users := liveUserRepo(t)
	engine, token := newTestRouter(t, users)

	for attempt := 1; attempt <= 5; attempt++ {
		rec := doRequest(t, engine, http.MethodDelete, "/v1/me", token, `{"password":"senha-errada"}`)
		if rec.Code != http.StatusForbidden {
			t.Fatalf("attempt %d: expected 403 while under the limit, got %d", attempt, rec.Code)
		}
	}

	rec := doRequest(t, engine, http.MethodDelete, "/v1/me", token, `{"password":"senha-errada"}`)
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("expected 429 on the 6th attempt, got %d with body %q", rec.Code, rec.Body.String())
	}
	if got := decodeError(t, rec)["error"]; got != "rate_limited" {
		t.Errorf("expected error \"rate_limited\", got %v", got)
	}
}
