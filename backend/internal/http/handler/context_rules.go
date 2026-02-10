package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type ContextRulesHandler struct {
	Usecase *usecase.ContextRuleUsecase
}

func NewContextRulesHandler(uc *usecase.ContextRuleUsecase) *ContextRulesHandler {
	return &ContextRulesHandler{Usecase: uc}
}

// List context rules.
// @Summary Listar regras de contexto
// @Tags ContextRules
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListContextRulesResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/context-rules [get]
func (h *ContextRulesHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	rules, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	items := make([]dto.ContextRuleResponse, 0, len(rules))
	for _, rule := range rules {
		items = append(items, toContextRuleResponse(rule))
	}

	c.JSON(http.StatusOK, dto.ListContextRulesResponse{Items: items, NextCursor: next})
}

// Create context rule.
// @Summary Criar regra de contexto
// @Tags ContextRules
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateContextRuleRequest true "Context rule payload"
// @Success 201 {object} dto.ContextRuleResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/context-rules [post]
func (h *ContextRulesHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateContextRuleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	rule, err := h.Usecase.Create(c.Request.Context(), userID, req.Keyword, req.FlagID, req.SubflagID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toContextRuleResponse(rule))
}

// Update context rule.
// @Summary Atualizar regra de contexto
// @Tags ContextRules
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Rule ID"
// @Param body body dto.UpdateContextRuleRequest true "Context rule payload"
// @Success 200 {object} dto.ContextRuleResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/context-rules/{id} [patch]
func (h *ContextRulesHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateContextRuleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	rule, err := h.Usecase.Update(c.Request.Context(), userID, id, req.Keyword, req.FlagID, req.SubflagID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusOK, toContextRuleResponse(rule))
}

// Delete context rule.
// @Summary Remover regra de contexto
// @Tags ContextRules
// @Security BearerAuth
// @Param id path string true "Rule ID"
// @Success 204 {object} nil
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/context-rules/{id} [delete]
func (h *ContextRulesHandler) Delete(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	if err := h.Usecase.Delete(c.Request.Context(), userID, id); err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}
