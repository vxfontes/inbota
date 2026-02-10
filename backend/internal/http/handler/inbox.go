package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type InboxHandler struct {
	Usecase *usecase.InboxUsecase
}

func NewInboxHandler(uc *usecase.InboxUsecase) *InboxHandler {
	return &InboxHandler{Usecase: uc}
}

// List inbox items.
// @Summary Listar inbox items
// @Tags Inbox
// @Security BearerAuth
// @Produce json
// @Param status query string false "Status"
// @Param source query string false "Source"
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListInboxItemsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/inbox-items [get]
func (h *InboxHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	input := usecase.InboxListInput{
		Status: stringPtr(c.Query("status")),
		Source: stringPtr(c.Query("source")),
	}
	if input.Status != nil && *input.Status == "" {
		input.Status = nil
	}
	if input.Source != nil && *input.Source == "" {
		input.Source = nil
	}

	results, next, err := h.Usecase.ListInboxItems(c.Request.Context(), userID, input, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	items := make([]dto.InboxItemResponse, 0, len(results))
	for _, result := range results {
		items = append(items, toInboxItemResponse(result.Item, result.Suggestion))
	}

	c.JSON(http.StatusOK, dto.ListInboxItemsResponse{Items: items, NextCursor: next})
}

// Create inbox item.
// @Summary Criar inbox item
// @Tags Inbox
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateInboxItemRequest true "Inbox payload"
// @Success 201 {object} dto.InboxItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/inbox-items [post]
func (h *InboxHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateInboxItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	var source *string
	if req.Source != "" {
		source = &req.Source
	}
	item, err := h.Usecase.CreateInboxItem(c.Request.Context(), userID, source, req.RawText, req.RawMediaURL)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toInboxItemResponse(item, nil))
}

// Get inbox item.
// @Summary Obter inbox item
// @Tags Inbox
// @Security BearerAuth
// @Produce json
// @Param id path string true "Inbox item ID"
// @Success 200 {object} dto.InboxItemResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/inbox-items/{id} [get]
func (h *InboxHandler) Get(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	result, err := h.Usecase.GetInboxItem(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toInboxItemResponse(result.Item, result.Suggestion))
}

// Reprocess inbox item.
// @Summary Reprocessar inbox item
// @Tags Inbox
// @Security BearerAuth
// @Produce json
// @Param id path string true "Inbox item ID"
// @Success 200 {object} dto.InboxItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/inbox-items/{id}/reprocess [post]
func (h *InboxHandler) Reprocess(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	result, err := h.Usecase.ReprocessInboxItem(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toInboxItemResponse(result.Item, result.Suggestion))
}

// Confirm inbox item.
// @Summary Confirmar inbox item
// @Tags Inbox
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Inbox item ID"
// @Param body body dto.ConfirmInboxItemRequest true "Confirm payload"
// @Success 200 {object} dto.ConfirmInboxItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/inbox-items/{id}/confirm [post]
func (h *InboxHandler) Confirm(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.ConfirmInboxItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	result, err := h.Usecase.ConfirmInboxItem(c.Request.Context(), userID, id, usecase.ConfirmInboxInput{
		Type:      req.Type,
		Title:     req.Title,
		FlagID:    req.FlagID,
		SubflagID: req.SubflagID,
		Payload:   req.Payload,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	resp := dto.ConfirmInboxItemResponse{Type: string(result.Type)}
	if result.Task != nil {
		task := toTaskResponse(*result.Task)
		resp.Task = &task
	}
	if result.Reminder != nil {
		reminder := toReminderResponse(*result.Reminder)
		resp.Reminder = &reminder
	}
	if result.Event != nil {
		event := toEventResponse(*result.Event)
		resp.Event = &event
	}
	if result.ShoppingList != nil {
		list := toShoppingListResponse(*result.ShoppingList)
		resp.ShoppingList = &list
	}
	if len(result.ShoppingItems) > 0 {
		items := make([]dto.ShoppingItemResponse, 0, len(result.ShoppingItems))
		for _, item := range result.ShoppingItems {
			items = append(items, toShoppingItemResponse(item))
		}
		resp.ShoppingItems = items
	}

	c.JSON(http.StatusOK, resp)
}

// Dismiss inbox item.
// @Summary Descartar inbox item
// @Tags Inbox
// @Security BearerAuth
// @Produce json
// @Param id path string true "Inbox item ID"
// @Success 200 {object} dto.InboxItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/inbox-items/{id}/dismiss [post]
func (h *InboxHandler) Dismiss(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	item, err := h.Usecase.DismissInboxItem(c.Request.Context(), userID, id)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toInboxItemResponse(item, nil))
}

func stringPtr(value string) *string {
	return &value
}
