package handler

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type HealthResponse struct {
	Status string `json:"status"`
	Time   string `json:"time"`
}

type Checker interface {
	Check(ctx context.Context) error
}

// HealthHandler returns a handler for liveness probes.
// @Summary Healthcheck (liveness)
// @Produce json
// @Success 200 {object} HealthResponse
// @Router /healthz [get]
func HealthHandler(c *gin.Context) {
	resp := HealthResponse{Status: "ok", Time: time.Now().UTC().Format(time.RFC3339)}
	c.JSON(http.StatusOK, resp)
}

// ReadinessHandler checks external deps when provided.
// @Summary Readiness
// @Produce json
// @Success 200 {object} HealthResponse
// @Failure 503 {object} HealthResponse
// @Router /readyz [get]
func ReadinessHandler(checkers ...Checker) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		for _, checker := range checkers {
			if checker == nil {
				continue
			}
			if err := checker.Check(ctx); err != nil {
				resp := HealthResponse{Status: "unready", Time: time.Now().UTC().Format(time.RFC3339)}
				c.JSON(http.StatusServiceUnavailable, resp)
				return
			}
		}
		resp := HealthResponse{Status: "ok", Time: time.Now().UTC().Format(time.RFC3339)}
		c.JSON(http.StatusOK, resp)
	}
}
