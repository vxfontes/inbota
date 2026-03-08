package repository

import (
	"context"
	"time"
)

type AgendaItem struct {
	ItemType     string    `db:"item_type"`
	ID           string    `db:"id"`
	UserID       string    `db:"user_id"`
	Title        string    `db:"title"`
	Status       string    `db:"status"`
	ScheduledAt  time.Time `db:"scheduled_at"`
	FlagName     *string   `db:"flag_name"`
	FlagColor    *string   `db:"flag_color"`
	SubflagName  *string   `db:"subflag_name"`
	SubflagColor *string   `db:"subflag_color"`
}

type AgendaRepository interface {
	List(ctx context.Context, userID string, opts ListOptions) ([]AgendaItem, error)
}
