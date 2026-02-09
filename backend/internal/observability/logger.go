package observability

import (
	"log/slog"
	"os"
	"strings"
)

// NewLogger returns a JSON slog logger configured with the given level.
func NewLogger(level string) *slog.Logger {
	lvl := slog.LevelInfo
	switch strings.ToLower(level) {
	case "debug":
		lvl = slog.LevelDebug
	case "info":
		lvl = slog.LevelInfo
	case "warn", "warning":
		lvl = slog.LevelWarn
	case "error":
		lvl = slog.LevelError
	}

	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: lvl})
	return slog.New(handler)
}
