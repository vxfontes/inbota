package handler

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/http/dto"
	"organiq/backend/internal/http/middleware"
)

type MeHandler struct {
	Users *usecase.AuthUsecase
}

func NewMeHandler(users *usecase.AuthUsecase) *MeHandler {
	return &MeHandler{Users: users}
}

// Me returns the current user profile from the JWT subject.
// @Summary Obter perfil do usuario logado
// @Tags Me
// @Security BearerAuth
// @Produce json
// @Success 200 {object} dto.AuthResponse
// @Failure 401 {object} dto.ErrorResponse
// @Router /v1/me [get]
func (h *MeHandler) Me(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	if h.Users == nil || h.Users.Users == nil {
		writeError(c, http.StatusInternalServerError, "dependency_missing")
		return
	}

	user, err := h.Users.Users.Get(c.Request.Context(), userID)
	if err != nil {
		writeUsecaseError(c, err)
		return
	}

	var resp dto.AuthResponse
	resp.User.ID = user.ID
	resp.User.Email = user.Email
	resp.User.DisplayName = user.DisplayName
	resp.User.Locale = user.Locale
	resp.User.Timezone = user.Timezone
	c.JSON(http.StatusOK, resp)
}

// DeleteMe permanently deletes the authenticated account and everything it
// owns, as required by App Store Guideline 5.1.1(v).
// @Summary Excluir a conta do usuario logado
// @Description Exclusao permanente e irreversivel. Remove a conta e todo o conteudo associado (inbox, tarefas, lembretes, eventos, listas, rotinas, flags, sugestoes, dispositivos e preferencias). Exige a senha atual como confirmacao.
// @Tags Me
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body dto.DeleteAccountRequest true "Confirmacao com a senha atual"
// @Success 204
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse
// @Failure 403 {object} dto.ErrorResponse "incorrect_password: senha de confirmacao incorreta (a sessao continua valida)"
// @Failure 429 {object} dto.ErrorResponse
// @Failure 500 {object} dto.ErrorResponse
// @Router /v1/me [delete]
func (h *MeHandler) DeleteMe(c *gin.Context) {
	userID, ok := getUserID(c)
	if !ok {
		return
	}
	if h.Users == nil {
		writeError(c, http.StatusInternalServerError, "dependency_missing")
		return
	}

	var req dto.DeleteAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, "invalid_payload")
		return
	}

	if err := h.Users.DeleteAccount(c.Request.Context(), userID, req.Password); err != nil {
		writeUsecaseError(c, err)
		return
	}

	// Audit trail for an irreversible, unrecoverable operation. Deliberately
	// only the UUID: logging the email or display name would retain the very
	// personal data the deletion exists to remove.
	slog.Info("account_deleted",
		slog.String("user_id", userID),
		slog.String("request_id", middleware.GetRequestID(c)),
	)

	c.Status(http.StatusNoContent)
}
