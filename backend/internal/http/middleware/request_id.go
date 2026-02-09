package middleware

import (
	"crypto/rand"
	"encoding/hex"

	"github.com/gin-gonic/gin"
)

const requestIDKey = "request_id"

// RequestID ensures a request ID is present.
func RequestID(headerName string) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader(headerName)
		if requestID == "" {
			requestID = newRequestID()
		}
		c.Set(requestIDKey, requestID)
		c.Writer.Header().Set(headerName, requestID)
		c.Next()
	}
}

// GetRequestID returns the request ID from gin context, if any.
func GetRequestID(c *gin.Context) string {
	if v, ok := c.Get(requestIDKey); ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

func newRequestID() string {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return ""
	}
	return hex.EncodeToString(b[:])
}
