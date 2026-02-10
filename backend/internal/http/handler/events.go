package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type EventsHandler struct {
	Usecase *usecase.EventUsecase
}

func NewEventsHandler(uc *usecase.EventUsecase) *EventsHandler {
	return &EventsHandler{Usecase: uc}
}

// List events.
// @Summary Listar eventos
// @Tags Events
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListEventsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/events [get]
func (h *EventsHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	events, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	items := make([]dto.EventResponse, 0, len(events))
	for _, event := range events {
		items = append(items, toEventResponse(event))
	}

	c.JSON(http.StatusOK, dto.ListEventsResponse{Items: items, NextCursor: next})
}

// Create event.
// @Summary Criar evento
// @Tags Events
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateEventRequest true "Event payload"
// @Success 201 {object} dto.EventResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/events [post]
func (h *EventsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	event, err := h.Usecase.Create(c.Request.Context(), userID, req.Title, req.StartAt, req.EndAt, req.AllDay, req.Location)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toEventResponse(event))
}

// Update event.
// @Summary Atualizar evento
// @Tags Events
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Event ID"
// @Param body body dto.UpdateEventRequest true "Event payload"
// @Success 200 {object} dto.EventResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/events/{id} [patch]
func (h *EventsHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	event, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.EventUpdateInput{
		Title:    req.Title,
		StartAt:  req.StartAt,
		EndAt:    req.EndAt,
		AllDay:   req.AllDay,
		Location: req.Location,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toEventResponse(event))
}
