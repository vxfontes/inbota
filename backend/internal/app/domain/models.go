package domain

import (
	"encoding/json"
	"time"
)

type InboxSource string

const (
	InboxSourceManual InboxSource = "manual"
	InboxSourceShare  InboxSource = "share"
	InboxSourceOCR    InboxSource = "ocr"
)

type InboxStatus string

const (
	InboxStatusNew         InboxStatus = "NEW"
	InboxStatusProcessing  InboxStatus = "PROCESSING"
	InboxStatusSuggested   InboxStatus = "SUGGESTED"
	InboxStatusNeedsReview InboxStatus = "NEEDS_REVIEW"
	InboxStatusConfirmed   InboxStatus = "CONFIRMED"
	InboxStatusDismissed   InboxStatus = "DISMISSED"
)

type AiSuggestionType string

const (
	AiSuggestionTypeTask     AiSuggestionType = "task"
	AiSuggestionTypeReminder AiSuggestionType = "reminder"
	AiSuggestionTypeEvent    AiSuggestionType = "event"
	AiSuggestionTypeShopping AiSuggestionType = "shopping"
	AiSuggestionTypeNote     AiSuggestionType = "note"
)

type TaskStatus string

const (
	TaskStatusOpen TaskStatus = "OPEN"
	TaskStatusDone TaskStatus = "DONE"
)

type ReminderStatus string

const (
	ReminderStatusOpen ReminderStatus = "OPEN"
	ReminderStatusDone ReminderStatus = "DONE"
)

type ShoppingListStatus string

const (
	ShoppingListStatusOpen     ShoppingListStatus = "OPEN"
	ShoppingListStatusDone     ShoppingListStatus = "DONE"
	ShoppingListStatusArchived ShoppingListStatus = "ARCHIVED"
)

type User struct {
	ID          string
	Email       string
	DisplayName string
	Password    string
	Locale      string
	Timezone    string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type Flag struct {
	ID        string
	UserID    string
	Name      string
	Color     *string
	SortOrder int
	CreatedAt time.Time
	UpdatedAt time.Time
}

type Subflag struct {
	ID        string
	UserID    string
	FlagID    string
	Name      string
	SortOrder int
	CreatedAt time.Time
	UpdatedAt time.Time
}

type ContextRule struct {
	ID        string
	UserID    string
	Keyword   string
	FlagID    string
	SubflagID *string
	CreatedAt time.Time
	UpdatedAt time.Time
}

type InboxItem struct {
	ID          string
	UserID      string
	Source      InboxSource
	RawText     string
	RawMediaURL *string
	Status      InboxStatus
	LastError   *string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type AiSuggestion struct {
	ID          string
	UserID      string
	InboxItemID string
	Type        AiSuggestionType
	Title       string
	Confidence  *float64
	FlagID      *string
	SubflagID   *string
	NeedsReview bool
	PayloadJSON json.RawMessage
	CreatedAt   time.Time
}

type Task struct {
	ID                string
	UserID            string
	Title             string
	Description       *string
	Status            TaskStatus
	DueAt             *time.Time
	SourceInboxItemID *string
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type Reminder struct {
	ID                string
	UserID            string
	Title             string
	Status            ReminderStatus
	RemindAt          *time.Time
	SourceInboxItemID *string
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type Event struct {
	ID                string
	UserID            string
	Title             string
	StartAt           *time.Time
	EndAt             *time.Time
	AllDay            bool
	Location          *string
	SourceInboxItemID *string
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type ShoppingList struct {
	ID                string
	UserID            string
	Title             string
	Status            ShoppingListStatus
	SourceInboxItemID *string
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type ShoppingItem struct {
	ID        string
	UserID    string
	ListID    string
	Title     string
	Quantity  *string
	Checked   bool
	SortOrder int
	CreatedAt time.Time
	UpdatedAt time.Time
}
