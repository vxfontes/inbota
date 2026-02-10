package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type RemindersHandler struct {
	Usecase *usecase.ReminderUsecase
}

func NewRemindersHandler(uc *usecase.ReminderUsecase) *RemindersHandler {
	return &RemindersHandler{Usecase: uc}
}

// List reminders.
// @Summary Listar lembretes
// @Tags Reminders
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListRemindersResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/reminders [get]
func (h *RemindersHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	reminders, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	items := make([]dto.ReminderResponse, 0, len(reminders))
	for _, reminder := range reminders {
		items = append(items, toReminderResponse(reminder))
	}

	c.JSON(http.StatusOK, dto.ListRemindersResponse{Items: items, NextCursor: next})
}

// Create reminder.
// @Summary Criar lembrete
// @Tags Reminders
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateReminderRequest true "Reminder payload"
// @Success 201 {object} dto.ReminderResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/reminders [post]
func (h *RemindersHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	reminder, err := h.Usecase.Create(c.Request.Context(), userID, req.Title, req.Status, req.RemindAt)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toReminderResponse(reminder))
}

// Update reminder.
// @Summary Atualizar lembrete
// @Tags Reminders
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Reminder ID"
// @Param body body dto.UpdateReminderRequest true "Reminder payload"
// @Success 200 {object} dto.ReminderResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/reminders/{id} [patch]
func (h *RemindersHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	reminder, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.ReminderUpdateInput{
		Title:    req.Title,
		Status:   req.Status,
		RemindAt: req.RemindAt,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toReminderResponse(reminder))
}
