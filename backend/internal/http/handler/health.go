package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type healthResponse struct {
	Status string `json:"status"`
	Time   string `json:"time"`
}

// HealthHandler returns a handler for health and readiness probes.
func HealthHandler(c *gin.Context) {
	resp := healthResponse{Status: "ok", Time: time.Now().UTC().Format(time.RFC3339)}
	c.JSON(http.StatusOK, resp)
}
