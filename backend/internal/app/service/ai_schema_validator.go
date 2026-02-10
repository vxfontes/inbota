package service

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

var ErrAISchemaInvalid = errors.New("ai_schema_invalid")

// AIOutput is the expected structure from the LLM.
type AIOutput struct {
	Type        string          `json:"type"`
	Title       string          `json:"title"`
	Confidence  *float64        `json:"confidence,omitempty"`
	Context     *AIContext      `json:"context,omitempty"`
	NeedsReview bool            `json:"needs_review"`
	Payload     json.RawMessage `json:"payload"`
}

type AIContext struct {
	FlagID    *string `json:"flagId,omitempty"`
	SubflagID *string `json:"subflagId,omitempty"`
}

type TaskPayload struct {
	DueAt *time.Time
}

type ReminderPayload struct {
	At time.Time
}

type EventPayload struct {
	Start  time.Time
	End    *time.Time
	AllDay bool
}

type ShoppingItemPayload struct {
	Title    string
	Quantity *string
}

type ShoppingPayload struct {
	Items []ShoppingItemPayload
}

type NotePayload struct {
	Content string
}

type ValidatedOutput struct {
	Output  AIOutput
	Payload any
}

type AiSchemaValidator struct{}

func NewAiSchemaValidator() *AiSchemaValidator {
	return &AiSchemaValidator{}
}

func (v *AiSchemaValidator) Validate(raw []byte) (ValidatedOutput, error) {
	output, err := decodeStrictOutput(raw)
	if err != nil {
		return ValidatedOutput{}, err
	}

	if output.Title == "" {
		return ValidatedOutput{}, fmt.Errorf("%w: title_required", ErrAISchemaInvalid)
	}
	if output.Confidence != nil {
		if *output.Confidence < 0 || *output.Confidence > 1 {
			return ValidatedOutput{}, fmt.Errorf("%w: confidence_out_of_range", ErrAISchemaInvalid)
		}
	}

	payload, err := v.validatePayload(output.Type, output.Payload)
	if err != nil {
		return ValidatedOutput{}, err
	}

	return ValidatedOutput{Output: output, Payload: payload}, nil
}

func decodeStrictOutput(raw []byte) (AIOutput, error) {
	var rawMap map[string]json.RawMessage
	if err := json.Unmarshal(raw, &rawMap); err != nil {
		return AIOutput{}, fmt.Errorf("%w: %s", ErrAISchemaInvalid, err.Error())
	}
	if _, ok := rawMap["type"]; !ok {
		return AIOutput{}, fmt.Errorf("%w: type_required", ErrAISchemaInvalid)
	}
	if _, ok := rawMap["title"]; !ok {
		return AIOutput{}, fmt.Errorf("%w: title_required", ErrAISchemaInvalid)
	}
	if _, ok := rawMap["needs_review"]; !ok {
		return AIOutput{}, fmt.Errorf("%w: needs_review_required", ErrAISchemaInvalid)
	}
	if _, ok := rawMap["payload"]; !ok {
		return AIOutput{}, fmt.Errorf("%w: payload_required", ErrAISchemaInvalid)
	}

	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	var output AIOutput
	if err := dec.Decode(&output); err != nil {
		return AIOutput{}, fmt.Errorf("%w: %s", ErrAISchemaInvalid, err.Error())
	}
	if output.Type == "" {
		return AIOutput{}, fmt.Errorf("%w: type_required", ErrAISchemaInvalid)
	}
	return output, nil
}

func (v *AiSchemaValidator) validatePayload(typ string, payload json.RawMessage) (any, error) {
	switch typ {
	case "task":
		return parseTaskPayload(payload)
	case "reminder":
		return parseReminderPayload(payload)
	case "event":
		return parseEventPayload(payload)
	case "shopping":
		return parseShoppingPayload(payload)
	case "note":
		return parseNotePayload(payload)
	default:
		return nil, fmt.Errorf("%w: invalid_type", ErrAISchemaInvalid)
	}
}

func parseTaskPayload(payload json.RawMessage) (TaskPayload, error) {
	var raw struct {
		DueAt *string `json:"dueAt"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return TaskPayload{}, err
	}

	var dueAt *time.Time
	if raw.DueAt != nil {
		parsed, err := parseRFC3339(*raw.DueAt)
		if err != nil {
			return TaskPayload{}, err
		}
		dueAt = &parsed
	}
	return TaskPayload{DueAt: dueAt}, nil
}

func parseReminderPayload(payload json.RawMessage) (ReminderPayload, error) {
	var raw struct {
		At *string `json:"at"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return ReminderPayload{}, err
	}
	if raw.At == nil || strings.TrimSpace(*raw.At) == "" {
		return ReminderPayload{}, fmt.Errorf("%w: reminder_at_required", ErrAISchemaInvalid)
	}
	parsed, err := parseRFC3339(*raw.At)
	if err != nil {
		return ReminderPayload{}, err
	}
	return ReminderPayload{At: parsed}, nil
}

func parseEventPayload(payload json.RawMessage) (EventPayload, error) {
	var raw struct {
		Start  *string `json:"start"`
		End    *string `json:"end"`
		AllDay *bool   `json:"allDay"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return EventPayload{}, err
	}
	if raw.Start == nil || strings.TrimSpace(*raw.Start) == "" {
		return EventPayload{}, fmt.Errorf("%w: event_start_required", ErrAISchemaInvalid)
	}
	start, err := parseRFC3339(*raw.Start)
	if err != nil {
		return EventPayload{}, err
	}
	var endPtr *time.Time
	if raw.End != nil && strings.TrimSpace(*raw.End) != "" {
		end, err := parseRFC3339(*raw.End)
		if err != nil {
			return EventPayload{}, err
		}
		if end.Before(start) {
			return EventPayload{}, fmt.Errorf("%w: event_end_before_start", ErrAISchemaInvalid)
		}
		endPtr = &end
	}

	allDay := false
	if raw.AllDay != nil {
		allDay = *raw.AllDay
	}
	return EventPayload{Start: start, End: endPtr, AllDay: allDay}, nil
}

func parseShoppingPayload(payload json.RawMessage) (ShoppingPayload, error) {
	var raw struct {
		Items []struct {
			Title    string  `json:"title"`
			Quantity *string `json:"quantity"`
		} `json:"items"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return ShoppingPayload{}, err
	}
	if len(raw.Items) == 0 {
		return ShoppingPayload{}, fmt.Errorf("%w: shopping_items_required", ErrAISchemaInvalid)
	}

	items := make([]ShoppingItemPayload, 0, len(raw.Items))
	for _, item := range raw.Items {
		if strings.TrimSpace(item.Title) == "" {
			return ShoppingPayload{}, fmt.Errorf("%w: shopping_item_title_required", ErrAISchemaInvalid)
		}
		items = append(items, ShoppingItemPayload{Title: item.Title, Quantity: item.Quantity})
	}

	return ShoppingPayload{Items: items}, nil
}

func parseNotePayload(payload json.RawMessage) (NotePayload, error) {
	var raw struct {
		Content string `json:"content"`
	}
	if err := decodeStrict(payload, &raw); err != nil {
		return NotePayload{}, err
	}
	if strings.TrimSpace(raw.Content) == "" {
		return NotePayload{}, fmt.Errorf("%w: note_content_required", ErrAISchemaInvalid)
	}
	return NotePayload{Content: raw.Content}, nil
}

func decodeStrict(payload json.RawMessage, target any) error {
	dec := json.NewDecoder(bytes.NewReader(payload))
	dec.DisallowUnknownFields()
	if err := dec.Decode(target); err != nil {
		return fmt.Errorf("%w: %s", ErrAISchemaInvalid, err.Error())
	}
	return nil
}

func parseRFC3339(value string) (time.Time, error) {
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		if parsedNano, errNano := time.Parse(time.RFC3339Nano, value); errNano == nil {
			return parsedNano, nil
		}
		return time.Time{}, fmt.Errorf("%w: invalid_timestamp", ErrAISchemaInvalid)
	}
	return parsed, nil
}
