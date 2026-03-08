package postgres

import (
	"context"
	"database/sql"

	"inbota/backend/internal/app/repository"
)

type AgendaRepository struct {
	db dbtx
}

func NewAgendaRepository(db *DB) *AgendaRepository {
	return &AgendaRepository{db: db}
}

func (r *AgendaRepository) List(ctx context.Context, userID string, opts repository.ListOptions) ([]repository.AgendaItem, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, err
	}

	query := `
		SELECT item_type, id, user_id, title, status, scheduled_at, flag_name, flag_color, subflag_name, subflag_color
		FROM inbota.view_agenda_consolidada
		WHERE user_id = $1
		ORDER BY scheduled_at
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]repository.AgendaItem, 0)
	for rows.Next() {
		var item repository.AgendaItem
		var flagName, flagColor, subflagName, subflagColor sql.NullString
		if err := rows.Scan(
			&item.ItemType, &item.ID, &item.UserID, &item.Title, &item.Status, &item.ScheduledAt,
			&flagName, &flagColor, &subflagName, &subflagColor,
		); err != nil {
			return nil, err
		}
		item.FlagName = stringPtrFromNull(flagName)
		item.FlagColor = stringPtrFromNull(flagColor)
		item.SubflagName = stringPtrFromNull(subflagName)
		item.SubflagColor = stringPtrFromNull(subflagColor)
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}
