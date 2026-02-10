// @title Inbota API
// @version 0.1
// @description API do MVP Inbota.
// @BasePath /
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Formato: Bearer <token>
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

	_ "inbota/backend/docs"
	"inbota/backend/internal/app/service"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/config"
	inbotahttp "inbota/backend/internal/http"
	"inbota/backend/internal/http/handler"
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

	var authHandler *handler.AuthHandler
	var apiHandlers *handler.APIHandlers
	if db != nil {
		if cfg.JWTSecret == "" {
			log.Error("jwt_secret_missing")
			os.Exit(1)
		}
		userRepo := postgres.NewUserRepository(db)
		authSvc := service.NewAuthService(cfg.JWTSecret, usecase.DefaultTokenTTL)
		authUC := &usecase.AuthUsecase{Users: userRepo, Auth: authSvc}
		authHandler = handler.NewAuthHandler(authUC)

		flagRepo := postgres.NewFlagRepository(db)
		subflagRepo := postgres.NewSubflagRepository(db)
		ruleRepo := postgres.NewContextRuleRepository(db)
		inboxRepo := postgres.NewInboxRepository(db)
		suggestionRepo := postgres.NewAiSuggestionRepository(db)
		taskRepo := postgres.NewTaskRepository(db)
		reminderRepo := postgres.NewReminderRepository(db)
		eventRepo := postgres.NewEventRepository(db)
		shoppingListRepo := postgres.NewShoppingListRepository(db)
		shoppingItemRepo := postgres.NewShoppingItemRepository(db)

		flagUC := &usecase.FlagUsecase{Flags: flagRepo}
		subflagUC := &usecase.SubflagUsecase{Subflags: subflagRepo}
		ruleUC := &usecase.ContextRuleUsecase{Rules: ruleRepo}
		taskUC := &usecase.TaskUsecase{Tasks: taskRepo}
		reminderUC := &usecase.ReminderUsecase{Reminders: reminderRepo}
		eventUC := &usecase.EventUsecase{Events: eventRepo}
		shoppingListUC := &usecase.ShoppingListUsecase{Lists: shoppingListRepo}
		shoppingItemUC := &usecase.ShoppingItemUsecase{Items: shoppingItemRepo}

		inboxUC := &usecase.InboxUsecase{
			Users:           userRepo,
			Inbox:           inboxRepo,
			Suggestions:     suggestionRepo,
			Flags:           flagRepo,
			Subflags:        subflagRepo,
			ContextRules:    ruleRepo,
			Tasks:           taskRepo,
			Reminders:       reminderRepo,
			Events:          eventRepo,
			ShoppingLists:   shoppingListRepo,
			ShoppingItems:   shoppingItemRepo,
			PromptBuilder:   service.NewPromptBuilder(),
			SchemaValidator: service.NewAiSchemaValidator(),
			RuleMatcher:     service.NewContextRuleMatcher(),
		}

		apiHandlers = &handler.APIHandlers{
			Flags:         handler.NewFlagsHandler(flagUC),
			Subflags:      handler.NewSubflagsHandler(subflagUC),
			ContextRules:  handler.NewContextRulesHandler(ruleUC),
			Inbox:         handler.NewInboxHandler(inboxUC),
			Tasks:         handler.NewTasksHandler(taskUC),
			Reminders:     handler.NewRemindersHandler(reminderUC),
			Events:        handler.NewEventsHandler(eventUC),
			ShoppingLists: handler.NewShoppingListsHandler(shoppingListUC),
			ShoppingItems: handler.NewShoppingItemsHandler(shoppingItemUC),
		}
	}

	router := inbotahttp.NewRouter(cfg, log, authHandler, apiHandlers, db)

	srv := &http.Server{
		Addr:         cfg.Addr(),
		Handler:      router,
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
