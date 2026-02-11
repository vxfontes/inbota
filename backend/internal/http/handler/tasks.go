package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/usecase"
	"inbota/backend/internal/http/dto"
)

type TasksHandler struct {
	Usecase *usecase.TaskUsecase
	Inbox   *usecase.InboxUsecase
}

func NewTasksHandler(uc *usecase.TaskUsecase, inbox *usecase.InboxUsecase) *TasksHandler {
	return &TasksHandler{Usecase: uc, Inbox: inbox}
}

// List tasks.
// @Summary Listar tarefas
// @Tags Tasks
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Limite"
// @Param cursor query string false "Cursor"
// @Success 200 {object} dto.ListTasksResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/tasks [get]
func (h *TasksHandler) List(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	opts, ok := parseListOptions(c)
	if !ok {
		return
	}

	tasks, next, err := h.Usecase.List(c.Request.Context(), userID, opts)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	sourceIDs := make([]string, 0)
	for _, task := range tasks {
		if task.SourceInboxItemID != nil {
			sourceIDs = append(sourceIDs, *task.SourceInboxItemID)
		}
	}

	sourcesByID := make(map[string]domain.InboxItem)
	if h.Inbox != nil {
		ids := uniqueStrings(sourceIDs)
		if len(ids) > 0 {
			items, err := h.Inbox.GetInboxItemsByIDs(c.Request.Context(), userID, ids)
			if err != nil {
				writeUsecaseError(c, err)
				return
			}
			sourcesByID = items
		}
	}

	items := make([]dto.TaskResponse, 0, len(tasks))
	for _, task := range tasks {
		var source *domain.InboxItem
		if task.SourceInboxItemID != nil {
			if item, ok := sourcesByID[*task.SourceInboxItemID]; ok {
				source = &item
			}
		}
		items = append(items, toTaskResponse(task, source))
	}

	c.JSON(http.StatusOK, dto.ListTasksResponse{Items: items, NextCursor: next})
}

// Create task.
// @Summary Criar tarefa
// @Tags Tasks
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.CreateTaskRequest true "Task payload"
// @Success 201 {object} dto.TaskResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/tasks [post]
func (h *TasksHandler) Create(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}

	var req dto.CreateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	task, err := h.Usecase.Create(c.Request.Context(), userID, req.Title, req.Description, req.Status, req.DueAt)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toTaskResponse(task, nil))
}

// Update task.
// @Summary Atualizar tarefa
// @Tags Tasks
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Task ID"
// @Param body body dto.UpdateTaskRequest true "Task payload"
// @Success 200 {object} dto.TaskResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /v1/tasks/{id} [patch]
func (h *TasksHandler) Update(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	id := c.Param("id")

	var req dto.UpdateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	task, err := h.Usecase.Update(c.Request.Context(), userID, id, usecase.TaskUpdateInput{
		Title:       req.Title,
		Description: req.Description,
		Status:      req.Status,
		DueAt:       req.DueAt,
	})
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var source *domain.InboxItem
	if h.Inbox != nil && task.SourceInboxItemID != nil {
		res, err := h.Inbox.GetInboxItem(c.Request.Context(), userID, *task.SourceInboxItemID)
		if err != nil {
			writeUsecaseError(c, err)
			return
		}
		source = &res.Item
	}

	c.JSON(http.StatusOK, toTaskResponse(task, source))
}
