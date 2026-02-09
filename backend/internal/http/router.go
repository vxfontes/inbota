package http

import (
	"log/slog"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/config"
	"inbota/backend/internal/http/handler"
	"inbota/backend/internal/http/middleware"
)

// NewRouter wires handlers and middleware.
func NewRouter(cfg config.Config, log *slog.Logger) *gin.Engine {
	engine := gin.New()
	engine.Use(gin.Recovery())
	engine.Use(middleware.RequestID(cfg.RequestIDHeader))
	engine.Use(middleware.Logging(log))

	engine.GET("/healthz", handler.HealthHandler)
	engine.GET("/readyz", handler.HealthHandler)

	return engine
}
