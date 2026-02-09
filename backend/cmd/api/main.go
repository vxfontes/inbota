package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/config"
	inbotahttp "inbota/backend/internal/http"
	"inbota/backend/internal/infra/postgres"
	"inbota/backend/internal/observability"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		panic(err)
	}

	log := observability.NewLogger(cfg.LogLevel)
	slog.SetDefault(log)

	if cfg.Env == "prod" {
		gin.SetMode(gin.ReleaseMode)
	}

	ctx := context.Background()
	var db *postgres.DB
	if cfg.DatabaseURL != "" {
		var err error
		db, err = postgres.NewDB(ctx, cfg.DatabaseURL)
		if err != nil {
			log.Error("db_connect_error", slog.String("error", err.Error()))
			os.Exit(1)
		}
		log.Info("db_connected")
	}

	handler := inbotahttp.NewRouter(cfg, log, db)

	srv := &http.Server{
		Addr:         cfg.Addr(),
		Handler:      handler,
		ReadTimeout:  cfg.ReadTimeout,
		WriteTimeout: cfg.WriteTimeout,
		IdleTimeout:  cfg.IdleTimeout,
	}

	go func() {
		log.Info("server_start", slog.String("addr", cfg.Addr()))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Error("server_error", slog.String("error", err.Error()))
		}
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGINT, syscall.SIGTERM)
	<-shutdown

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	log.Info("server_shutdown")
	if err := srv.Shutdown(ctx); err != nil {
		log.Error("server_shutdown_error", slog.String("error", err.Error()))
	}
	if db != nil {
		_ = db.Close()
	}
}
