package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"inbota/backend/internal/app/repository"
	"inbota/backend/internal/app/usecase"
)

type AuthHandler struct {
	Usecase *usecase.AuthUsecase
}

type authRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"displayName"`
	Locale      string `json:"locale"`
	Timezone    string `json:"timezone"`
}

type authResponse struct {
	Token string `json:"token"`
	User  struct {
		ID          string `json:"id"`
		Email       string `json:"email"`
		DisplayName string `json:"displayName"`
		Locale      string `json:"locale"`
		Timezone    string `json:"timezone"`
	} `json:"user"`
}

func NewAuthHandler(uc *usecase.AuthUsecase) *AuthHandler {
	return &AuthHandler{Usecase: uc}
}

func (h *AuthHandler) Signup(c *gin.Context) {
	var req authRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_payload"})
		return
	}

	user, token, err := h.Usecase.Signup(c.Request.Context(), req.Email, req.Password, req.DisplayName, req.Locale, req.Timezone)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	resp := toAuthResponse(user, token)
	c.JSON(http.StatusCreated, resp)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req authRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_payload"})
		return
	}

	user, token, err := h.Usecase.Login(c.Request.Context(), req.Email, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid_credentials"})
		return
	}

	resp := toAuthResponse(user, token)
	c.JSON(http.StatusOK, resp)
}

func toAuthResponse(user repository.User, token string) authResponse {
	var resp authResponse
	resp.Token = token
	resp.User.ID = user.ID
	resp.User.Email = user.Email
	resp.User.DisplayName = user.DisplayName
	resp.User.Locale = user.Locale
	resp.User.Timezone = user.Timezone
	return resp
}
