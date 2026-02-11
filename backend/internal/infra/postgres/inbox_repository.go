package postgres

import (
	"context"
	"database/sql"
	"strconv"
	"strings"

	"github.com/lib/pq"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type InboxRepository struct {
	db dbtx
}

func NewInboxRepository(db *DB) *InboxRepository {
	return &InboxRepository{db: db}
}

func NewInboxRepositoryTx(tx *sql.Tx) *InboxRepository {
	return &InboxRepository{db: tx}
}

func (r *InboxRepository) Create(ctx context.Context, item domain.InboxItem) (domain.InboxItem, error) {
	if item.Status == "" {
		item.Status = domain.InboxStatusNew
	}
	if item.Source == "" {
		item.Source = domain.InboxSourceManual
	}

	row := r.db.QueryRowContext(ctx, `
		INSERT INTO inbota.inbox_items (user_id, source, raw_text, raw_media_url, status, last_error)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`, item.UserID, string(item.Source), item.RawText, item.RawMediaURL, string(item.Status), item.LastError)

	if err := row.Scan(&item.ID, &item.CreatedAt, &item.UpdatedAt); err != nil {
		return domain.InboxItem{}, err
	}
	return item, nil
}

func (r *InboxRepository) Update(ctx context.Context, item domain.InboxItem) (domain.InboxItem, error) {
	row := r.db.QueryRowContext(ctx, `
		UPDATE inbota.inbox_items
		SET source = $1, raw_text = $2, raw_media_url = $3, status = $4, last_error = $5, updated_at = now()
		WHERE id = $6 AND user_id = $7
		RETURNING created_at, updated_at
	`, string(item.Source), item.RawText, item.RawMediaURL, string(item.Status), item.LastError, item.ID, item.UserID)

	if err := row.Scan(&item.CreatedAt, &item.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.InboxItem{}, ErrNotFound
		}
		return domain.InboxItem{}, err
	}
	return item, nil
}

func (r *InboxRepository) Get(ctx context.Context, userID, id string) (domain.InboxItem, error) {
	row := r.db.QueryRowContext(ctx, `
		SELECT id, user_id, source, raw_text, raw_media_url, status, last_error, created_at, updated_at
		FROM inbota.inbox_items
		WHERE id = $1 AND user_id = $2
		LIMIT 1
	`, id, userID)

	var source string
	var status string
	var rawMedia sql.NullString
	var lastError sql.NullString
	var item domain.InboxItem
	if err := row.Scan(&item.ID, &item.UserID, &source, &item.RawText, &rawMedia, &status, &lastError, &item.CreatedAt, &item.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return domain.InboxItem{}, ErrNotFound
		}
		return domain.InboxItem{}, err
	}
	item.Source = domain.InboxSource(source)
	item.Status = domain.InboxStatus(status)
	item.RawMediaURL = stringPtrFromNull(rawMedia)
	item.LastError = stringPtrFromNull(lastError)
	return item, nil
}

func (r *InboxRepository) GetByIDs(ctx context.Context, userID string, ids []string) ([]domain.InboxItem, error) {
	if len(ids) == 0 {
		return []domain.InboxItem{}, nil
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT id, user_id, source, raw_text, raw_media_url, status, last_error, created_at, updated_at
		FROM inbota.inbox_items
		WHERE user_id = $1 AND id = ANY($2)
	`, userID, pq.Array(ids))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.InboxItem, 0)
	for rows.Next() {
		var source string
		var status string
		var rawMedia sql.NullString
		var lastError sql.NullString
		var item domain.InboxItem
		if err := rows.Scan(&item.ID, &item.UserID, &source, &item.RawText, &rawMedia, &status, &lastError, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, err
		}
		item.Source = domain.InboxSource(source)
		item.Status = domain.InboxStatus(status)
		item.RawMediaURL = stringPtrFromNull(rawMedia)
		item.LastError = stringPtrFromNull(lastError)
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *InboxRepository) List(ctx context.Context, userID string, filter repository.InboxListFilter, opts repository.ListOptions) ([]domain.InboxItem, *string, error) {
	limit, offset, err := limitOffset(opts)
	if err != nil {
		return nil, nil, err
	}

	clauses := []string{"user_id = $1"}
	args := []any{userID}
	argIndex := 2

	if filter.Status != nil {
		clauses = append(clauses, "status = $"+itoa(argIndex))
		args = append(args, string(*filter.Status))
		argIndex++
	}
	if filter.Source != nil {
		clauses = append(clauses, "source = $"+itoa(argIndex))
		args = append(args, string(*filter.Source))
		argIndex++
	}

	args = append(args, limit, offset)
	limitIndex := argIndex
	offsetIndex := argIndex + 1

	query := `
		SELECT id, user_id, source, raw_text, raw_media_url, status, last_error, created_at, updated_at
		FROM inbota.inbox_items
		WHERE ` + strings.Join(clauses, " AND ") + `
		ORDER BY created_at DESC
		LIMIT $` + itoa(limitIndex) + ` OFFSET $` + itoa(offsetIndex)

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	items := make([]domain.InboxItem, 0)
	for rows.Next() {
		var source string
		var status string
		var rawMedia sql.NullString
		var lastError sql.NullString
		var item domain.InboxItem
		if err := rows.Scan(&item.ID, &item.UserID, &source, &item.RawText, &rawMedia, &status, &lastError, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, nil, err
		}
		item.Source = domain.InboxSource(source)
		item.Status = domain.InboxStatus(status)
		item.RawMediaURL = stringPtrFromNull(rawMedia)
		item.LastError = stringPtrFromNull(lastError)
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, err
	}

	next := nextOffsetCursor(offset, len(items), limit)
	return items, next, nil
}

func itoa(value int) string {
	return strconv.Itoa(value)
}
