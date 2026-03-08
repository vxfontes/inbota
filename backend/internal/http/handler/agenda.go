package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type AgendaHandler struct {
	Agenda *usecase.AgendaUsecase
}

func NewAgendaHandler(
	agenda *usecase.AgendaUsecase,
) *AgendaHandler {
	return &AgendaHandler{
		Agenda: agenda,
	}
}

// List agenda items.
// @Summary Listar agenda consolidada
// @Tags Agenda
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite de itens. Max 1000."
// @Success 200 {object} dto.AgendaResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/agenda [get]
func (h *AgendaHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	if h.Agenda == nil {
		writeUsecaseError(c, usecase.ErrDependencyMissing)
		return
	}

	limit := 200
	if limitStr := c.Query("limit"); limitStr != "" {
		parsed, err := strconv.Atoi(limitStr)
		if err != nil || parsed < 0 {
			writeError(c, http.StatusBadRequest, "invalid_limit")
			return
		}
		limit = parsed
	}
	opts := repository.ListOptions{Limit: limit}

	items, err := h.Agenda.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	eventItems := make([]dto.EventResponse, 0)
	taskItems := make([]dto.TaskResponse, 0)
	reminderItems := make([]dto.ReminderResponse, 0)

	for _, item := range items {
		var flag *dto.FlagObject
		if item.FlagName != nil {
			flag = &dto.FlagObject{
				Name:  *item.FlagName,
				Color: item.FlagColor,
			}
		}
		var subflag *dto.SubflagObject
		if item.SubflagName != nil {
			subflag = &dto.SubflagObject{
				Name:  *item.SubflagName,
				Color: item.SubflagColor,
			}
		}

		scheduledAt := item.ScheduledAt

		switch item.ItemType {
		case "event":
			eventItems = append(eventItems, dto.EventResponse{
				ID:      item.ID,
				Title:   item.Title,
				StartAt: &scheduledAt,
				Flag:    flag,
				Subflag: subflag,
			})
		case "task":
			taskItems = append(taskItems, dto.TaskResponse{
				ID:      item.ID,
				Title:   item.Title,
				Status:  item.Status,
				DueAt:   &scheduledAt,
				Flag:    flag,
				Subflag: subflag,
			})
		case "reminder":
			reminderItems = append(reminderItems, dto.ReminderResponse{
				ID:       item.ID,
				Title:    item.Title,
				Status:   item.Status,
				RemindAt: &scheduledAt,
				Flag:     flag,
				Subflag:  subflag,
			})
		}
	}

	c.JSON(http.StatusOK, dto.AgendaResponse{
		Events:    eventItems,
		Tasks:     taskItems,
		Reminders: reminderItems,
	})
}
