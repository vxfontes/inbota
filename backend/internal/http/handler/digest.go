package handler

import (
	"inbota/backend/internal/app/digest"
	"net/http"

	"github.com/gin-gonic/gin"
)

type DigestHandler struct {
	digestService *digest.DigestService
}

func NewDigestHandler(digestService *digest.DigestService) *DigestHandler {
	return &DigestHandler{digestService: digestService}
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
