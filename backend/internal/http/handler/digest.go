package handler

import (
	"inbota/backend/internal/app/digest"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type DigestHandler struct {
	digestService *digest.DigestService
}

func NewDigestHandler(digestService *digest.DigestService) *DigestHandler {
	return &DigestHandler{digestService: digestService}
}

// GetDailySummary returns a consolidated daily summary for the user.
// @Summary Resumo diário público
// @Description Retorna o resumo consolidado do dia do usuário (rotinas, agenda, tarefas, compras).
// @Tags Digest
// @Produce json
// @Param email query string true "User Email"
// @Param user_id query string true "User ID"
// @Success 200 {object} digest.DigestData
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /daily-summary [get]
func (h *DigestHandler) GetDailySummary(c *gin.Context) {

	email := c.Query("email")
	userID := c.Query("user_id")

	if email == "" || userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email and user_id are required"})
		return
	}

	valid, err := h.digestService.ValidateUser(c.Request.Context(), userID, email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if !valid {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid email for this user_id"})
		return
	}

	// We'll use a fixed time for "today" in the user's local day,
	// but BuildDigestData handles time.Now() if we pass zero time or we can pass it explicitly.
	// For simplicity and since it's a "daily summary", we use the current time.
	data, err := h.digestService.BuildDigestData(c.Request.Context(), userID, time.Now())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *DigestHandler) SendTestEmail(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	err := h.digestService.SendTestDigestForUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "test digest sent"})
}
