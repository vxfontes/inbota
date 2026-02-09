package postgres

import (
	"context"
	"database/sql"
	"time"

	_ "github.com/lib/pq"
)

type DB struct {
	*sql.DB
}

// NewDB opens a Postgres connection pool.
func NewDB(ctx context.Context, dsn string) (*DB, error) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(30 * time.Minute)

	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}

	return &DB{DB: db}, nil
}

// Check pings the database.
func (db *DB) Check(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 1*time.Second)
	defer cancel()
	return db.PingContext(ctx)
}
