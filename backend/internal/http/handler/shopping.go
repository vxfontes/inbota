package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type ShoppingListsHandler struct {
	Usecase *usecase.ShoppingListUsecase
}

type ShoppingItemsHandler struct {
	Usecase *usecase.ShoppingItemUsecase
}

func NewShoppingListsHandler(uc *usecase.ShoppingListUsecase) *ShoppingListsHandler {
	return &ShoppingListsHandler{Usecase: uc}
}

func NewShoppingItemsHandler(uc *usecase.ShoppingItemUsecase) *ShoppingItemsHandler {
	return &ShoppingItemsHandler{Usecase: uc}
}

// List shopping lists.
// @Summary Listar listas de compras
// @Tags ShoppingLists
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListShoppingListsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/shopping-lists [get]
func (h *ShoppingListsHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	lists, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	items := make([]dto.ShoppingListResponse, 0, len(lists))
	for _, list := range lists {
		items = append(items, toShoppingListResponse(list))
	}

	c.JSON(http.StatusOK, dto.ListShoppingListsResponse{Items: items, NextCursor: next})
}

// Create shopping list.
// @Summary Criar lista de compras
// @Tags ShoppingLists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateShoppingListRequest true "Shopping list payload"
// @Success 201 {object} dto.ShoppingListResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/shopping-lists [post]
func (h *ShoppingListsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateShoppingListRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	list, err := h.Usecase.Create(c.Request.Context(), userID, req.Title, req.Status)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toShoppingListResponse(list))
}

// Update shopping list.
// @Summary Atualizar lista de compras
// @Tags ShoppingLists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Shopping list ID"
// @Param body body dto.UpdateShoppingListRequest true "Shopping list payload"
// @Success 200 {object} dto.ShoppingListResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/shopping-lists/{id} [patch]
func (h *ShoppingListsHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateShoppingListRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	list, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.ShoppingListUpdateInput{
		Title:  req.Title,
		Status: req.Status,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toShoppingListResponse(list))
}

// List shopping items by list.
// @Summary Listar itens da lista
// @Tags ShoppingItems
// @Security BearerAuth
// @Produce json
// @Param id path string true "Shopping list ID"
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListShoppingItemsResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/shopping-lists/{id}/items [get]
func (h *ShoppingItemsHandler) ListByList(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	listID := c.Param("id")
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	items, next, err := h.Usecase.ListByList(c.Request.Context(), userID, listID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	respItems := make([]dto.ShoppingItemResponse, 0, len(items))
	for _, item := range items {
		respItems = append(respItems, toShoppingItemResponse(item))
	}

	c.JSON(http.StatusOK, dto.ListShoppingItemsResponse{Items: respItems, NextCursor: next})
}

// Create shopping item.
// @Summary Criar item de compra
// @Tags ShoppingItems
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Shopping list ID"
// @Param body body dto.CreateShoppingItemRequest true "Shopping item payload"
// @Success 201 {object} dto.ShoppingItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/shopping-lists/{id}/items [post]
func (h *ShoppingItemsHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	listID := c.Param("id")

	var req dto.CreateShoppingItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	item, err := h.Usecase.Create(c.Request.Context(), userID, listID, req.Title, req.Quantity, req.Checked, req.SortOrder)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toShoppingItemResponse(item))
}

// Update shopping item.
// @Summary Atualizar item de compra
// @Tags ShoppingItems
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Shopping item ID"
// @Param body body dto.UpdateShoppingItemRequest true "Shopping item payload"
// @Success 200 {object} dto.ShoppingItemResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/shopping-items/{id} [patch]
func (h *ShoppingItemsHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateShoppingItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	item, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.ShoppingItemUpdateInput{
		Title:     req.Title,
		Quantity:  req.Quantity,
		Checked:   req.Checked,
		SortOrder: req.SortOrder,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toShoppingItemResponse(item))
}
