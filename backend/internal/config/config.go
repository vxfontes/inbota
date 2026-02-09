package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config holds application configuration loaded from environment variables.
type Config struct {
	Env             string
	Port            int
	RequestIDHeader string
	LogLevel        string
	DatabaseURL     string
	JWTSecret       string
	AIProvider      string
	AIAPIKey        string

	ReadTimeout  time.Duration
	WriteTimeout time.Duration
	IdleTimeout  time.Duration
}

// Load reads environment variables and applies defaults.
func Load() (Config, error) {
	cfg := Config{
		Env:             getEnv("APP_ENV", "dev"),
		Port:            getEnvInt("PORT", 8080),
		RequestIDHeader: getEnv("REQUEST_ID_HEADER", "X-Request-Id"),
		LogLevel:        strings.ToLower(getEnv("LOG_LEVEL", "info")),
		DatabaseURL:     getEnv("DATABASE_URL", ""),
		JWTSecret:       getEnv("JWT_SECRET", ""),
		AIProvider:      getEnv("AI_PROVIDER", ""),
		AIAPIKey:        getEnv("AI_API_KEY", ""),
		ReadTimeout:     getEnvDuration("READ_TIMEOUT", 5*time.Second),
		WriteTimeout:    getEnvDuration("WRITE_TIMEOUT", 10*time.Second),
		IdleTimeout:     getEnvDuration("IDLE_TIMEOUT", 60*time.Second),
	}

	if cfg.Port <= 0 {
		return Config{}, errors.New("PORT must be > 0")
	}

	return cfg, nil
}

func getEnv(key, def string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return def
}

func getEnvInt(key string, def int) int {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	parsed, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return parsed
}

func getEnvDuration(key string, def time.Duration) time.Duration {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return def
	}
	return d
}

// Addr returns server address based on Port.
func (c Config) Addr() string {
	return fmt.Sprintf(":%d", c.Port)
}
