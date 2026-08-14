package usecase

import "errors"

var (
	ErrMissingRequiredFields = errors.New("missing_required_fields")
	ErrInvalidStatus         = errors.New("invalid_status")
	ErrInvalidType           = errors.New("invalid_type")
	ErrInvalidPlatform       = errors.New("invalid_platform")
	ErrInvalidSource         = errors.New("invalid_source")
	ErrInvalidPayload        = errors.New("invalid_payload")
	ErrInvalidTimeRange      = errors.New("invalid_time_range")
	ErrDependencyMissing     = errors.New("dependency_missing")
	ErrInvalidEmail          = errors.New("invalid_email")
	ErrInvalidPassword       = errors.New("invalid_password")
	ErrInvalidDisplayName    = errors.New("invalid_display_name")
	// ErrIncorrectPassword means a password re-confirmation on an already
	// authenticated request did not match the stored hash. It is deliberately
	// NOT ErrInvalidPassword (which means the password fails the signup policy
	// and maps to 400) and NOT ErrInvalidCredentials (which maps to 401 and
	// makes clients drop the session). The JWT here is valid; only the
	// confirmation failed, so this maps to 403 and the user stays logged in.
	ErrIncorrectPassword = errors.New("incorrect_password")
	ErrRoutineOverlap        = errors.New("routine_overlap")
	ErrEmailAlreadyExists    = errors.New("email_already_exists")
)
