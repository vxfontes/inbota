package handler

import (
	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/http/dto"
)

func toFlagResponse(flag domain.Flag) dto.FlagResponse {
	return dto.FlagResponse{
		ID:        flag.ID,
		Name:      flag.Name,
		Color:     flag.Color,
		SortOrder: flag.SortOrder,
		CreatedAt: flag.CreatedAt,
		UpdatedAt: flag.UpdatedAt,
	}
}

func toSubflagResponse(subflag domain.Subflag) dto.SubflagResponse {
	return dto.SubflagResponse{
		ID:        subflag.ID,
		FlagID:    subflag.FlagID,
		Name:      subflag.Name,
		SortOrder: subflag.SortOrder,
		CreatedAt: subflag.CreatedAt,
		UpdatedAt: subflag.UpdatedAt,
	}
}

func toContextRuleResponse(rule domain.ContextRule) dto.ContextRuleResponse {
	return dto.ContextRuleResponse{
		ID:        rule.ID,
		Keyword:   rule.Keyword,
		FlagID:    rule.FlagID,
		SubflagID: rule.SubflagID,
		CreatedAt: rule.CreatedAt,
		UpdatedAt: rule.UpdatedAt,
	}
}

func toSuggestionResponse(suggestion domain.AiSuggestion) dto.AiSuggestionResponse {
	return dto.AiSuggestionResponse{
		ID:          suggestion.ID,
		Type:        string(suggestion.Type),
		Title:       suggestion.Title,
		Confidence:  suggestion.Confidence,
		FlagID:      suggestion.FlagID,
		SubflagID:   suggestion.SubflagID,
		NeedsReview: suggestion.NeedsReview,
		Payload:     suggestion.PayloadJSON,
		CreatedAt:   suggestion.CreatedAt,
	}
}

func toInboxItemResponse(item domain.InboxItem, suggestion *domain.AiSuggestion) dto.InboxItemResponse {
	var suggestionResp *dto.AiSuggestionResponse
	if suggestion != nil {
		s := toSuggestionResponse(*suggestion)
		suggestionResp = &s
	}
	return dto.InboxItemResponse{
		ID:          item.ID,
		Source:      string(item.Source),
		RawText:     item.RawText,
		RawMediaURL: item.RawMediaURL,
		Status:      string(item.Status),
		LastError:   item.LastError,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
		Suggestion:  suggestionResp,
	}
}

func toTaskResponse(task domain.Task) dto.TaskResponse {
	return dto.TaskResponse{
		ID:                task.ID,
		Title:             task.Title,
		Description:       task.Description,
		Status:            string(task.Status),
		DueAt:             task.DueAt,
		SourceInboxItemID: task.SourceInboxItemID,
		CreatedAt:         task.CreatedAt,
		UpdatedAt:         task.UpdatedAt,
	}
}

func toReminderResponse(reminder domain.Reminder) dto.ReminderResponse {
	return dto.ReminderResponse{
		ID:                reminder.ID,
		Title:             reminder.Title,
		Status:            string(reminder.Status),
		RemindAt:          reminder.RemindAt,
		SourceInboxItemID: reminder.SourceInboxItemID,
		CreatedAt:         reminder.CreatedAt,
		UpdatedAt:         reminder.UpdatedAt,
	}
}

func toEventResponse(event domain.Event) dto.EventResponse {
	return dto.EventResponse{
		ID:                event.ID,
		Title:             event.Title,
		StartAt:           event.StartAt,
		EndAt:             event.EndAt,
		AllDay:            event.AllDay,
		Location:          event.Location,
		SourceInboxItemID: event.SourceInboxItemID,
		CreatedAt:         event.CreatedAt,
		UpdatedAt:         event.UpdatedAt,
	}
}

func toShoppingListResponse(list domain.ShoppingList) dto.ShoppingListResponse {
	return dto.ShoppingListResponse{
		ID:                list.ID,
		Title:             list.Title,
		Status:            string(list.Status),
		SourceInboxItemID: list.SourceInboxItemID,
		CreatedAt:         list.CreatedAt,
		UpdatedAt:         list.UpdatedAt,
	}
}

func toShoppingItemResponse(item domain.ShoppingItem) dto.ShoppingItemResponse {
	return dto.ShoppingItemResponse{
		ID:        item.ID,
		ListID:    item.ListID,
		Title:     item.Title,
		Quantity:  item.Quantity,
		Checked:   item.Checked,
		SortOrder: item.SortOrder,
		CreatedAt: item.CreatedAt,
		UpdatedAt: item.UpdatedAt,
	}
}
