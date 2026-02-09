package repository

import "context"

type User struct {
	ID           string
	Email        string
	DisplayName  string
	Password     string
	Locale       string
	Timezone     string
}

type UserRepository interface {
	Create(ctx context.Context, user User) (User, error)
	FindByEmail(ctx context.Context, email string) (User, error)
}
