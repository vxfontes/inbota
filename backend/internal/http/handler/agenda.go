package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type AgendaHandler struct {
	Events    *usecase.EventUsecase
	Tasks     *usecase.TaskUsecase
	Reminders *usecase.ReminderUsecase
}

func NewAgendaHandler(events *usecase.EventUsecase, tasks *usecase.TaskUsecase, reminders *usecase.ReminderUsecase) *AgendaHandler {
	return &AgendaHandler{
		Events:    events,
		Tasks:     tasks,
		Reminders: reminders,
	}
}

// List agenda items.
// @Summary Listar agenda consolidada
// @Tags Agenda
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite por tipo (events/tasks/reminders). Max 200."
// @Success 200 {object} dto.AgendaResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/agenda [get]
func (h *AgendaHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	if h.Events == nil || h.Tasks == nil || h.Reminders == nil {
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

	events, _, err := h.Events.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	tasks, _, err := h.Tasks.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	reminders, _, err := h.Reminders.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	eventItems := make([]dto.EventResponse, 0, len(events))
	for _, event := range events {
		if event.StartAt == nil {
			continue
		}
		eventItems = append(eventItems, toEventResponse(event, nil))
	}

	taskItems := make([]dto.TaskResponse, 0, len(tasks))
	for _, task := range tasks {
		if task.DueAt == nil {
			continue
		}
		taskItems = append(taskItems, toTaskResponse(task, nil, nil, nil))
	}

	reminderItems := make([]dto.ReminderResponse, 0, len(reminders))
	for _, reminder := range reminders {
		if reminder.RemindAt == nil {
			continue
		}
		reminderItems = append(reminderItems, toReminderResponse(reminder, nil))
	}

	c.JSON(http.StatusOK, dto.AgendaResponse{
		Events:    eventItems,
		Tasks:     taskItems,
		Reminders: reminderItems,
	})
}
