package handler

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type healthResponse struct {
	Status string `json:"status"`
	Time   string `json:"time"`
}

type Checker interface {
	Check(ctx context.Context) error
}

// HealthHandler returns a handler for liveness probes.
func HealthHandler(c *gin.Context) {
	resp := healthResponse{Status: "ok", Time: time.Now().UTC().Format(time.RFC3339)}
	c.JSON(http.StatusOK, resp)
}

// ReadinessHandler checks external deps when provided.
func ReadinessHandler(checkers ...Checker) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		for _, checker := range checkers {
			if checker == nil {
				continue
			}
			if err := checker.Check(ctx); err != nil {
				resp := healthResponse{Status: "unready", Time: time.Now().UTC().Format(time.RFC3339)}
				c.JSON(http.StatusServiceUnavailable, resp)
				return
			}
		}
		resp := healthResponse{Status: "ok", Time: time.Now().UTC().Format(time.RFC3339)}
		c.JSON(http.StatusOK, resp)
	}
}
