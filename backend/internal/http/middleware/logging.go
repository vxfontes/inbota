package middleware

import (
	"log/slog"
	"time"

	"github.com/gin-gonic/gin"
)

// Logging logs request/response info.
func Logging(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		duration := time.Since(start)

		requestID := GetRequestID(c)
		log.Info("request",
			slog.String("method", c.Request.Method),
			slog.String("path", c.Request.URL.Path),
			slog.Int("status", c.Writer.Status()),
			slog.Int("bytes", c.Writer.Size()),
			slog.Duration("duration", duration),
			slog.String("request_id", requestID),
		)
	}
}
