package service

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

var ErrAIProviderNotConfigured = errors.New("ai_provider_not_configured")
var ErrAIInvalidResponse = errors.New("ai_invalid_response")

// AIClient performs LLM requests.
type AIClient interface {
	Complete(ctx context.Context, prompt string) (AICompletion, error)
}

// AICompletion holds the raw text returned by the provider.
type AICompletion struct {
	Content string
	Model   string
	Raw     json.RawMessage
}

type AIClientConfig struct {
	Provider   string
	BaseURL    string
	APIKey     string
	Model      string
	Timeout    time.Duration
	MaxRetries int
}

type HTTPAIClient struct {
	provider   string
	baseURL    string
	apiKey     string
	model      string
	maxRetries int
	client     *http.Client
}

func NewHTTPAIClient(cfg AIClientConfig) (*HTTPAIClient, error) {
	if cfg.BaseURL == "" {
		return nil, ErrAIProviderNotConfigured
	}
	if cfg.APIKey == "" {
		return nil, ErrAIProviderNotConfigured
	}
	if cfg.Model == "" {
		return nil, errors.New("ai_model_required")
	}
	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = 15 * time.Second
	}
	maxRetries := cfg.MaxRetries
	if maxRetries < 0 {
		maxRetries = 0
	}
	return &HTTPAIClient{
		provider:   cfg.Provider,
		baseURL:    cfg.BaseURL,
		apiKey:     cfg.APIKey,
		model:      cfg.Model,
		maxRetries: maxRetries,
		client:     &http.Client{Timeout: timeout},
	}, nil
}

func (c *HTTPAIClient) Complete(ctx context.Context, prompt string) (AICompletion, error) {
	payload := chatCompletionRequest{
		Model: c.model,
		Messages: []chatMessage{
			{
				Role: "system",
				Content: "You are a strict JSON extractor. " +
					"Reply with only one valid JSON object and no extra text.",
			},
			{Role: "user", Content: prompt},
		},
		Temperature: 0,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return AICompletion{}, err
	}

	var lastErr error
	for attempt := 0; attempt <= c.maxRetries; attempt++ {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL, bytes.NewReader(body))
		if err != nil {
			return AICompletion{}, err
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+c.apiKey)

		resp, err := c.client.Do(req)
		if err != nil {
			lastErr = err
			if attempt < c.maxRetries {
				backoff(attempt)
				continue
			}
			return AICompletion{}, err
		}

		respBody, readErr := io.ReadAll(resp.Body)
		_ = resp.Body.Close()
		if readErr != nil {
			lastErr = readErr
			if attempt < c.maxRetries {
				backoff(attempt)
				continue
			}
			return AICompletion{}, readErr
		}

		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			lastErr = fmt.Errorf("ai_http_status_%d", resp.StatusCode)
			if attempt < c.maxRetries && resp.StatusCode >= 500 {
				backoff(attempt)
				continue
			}
			return AICompletion{}, lastErr
		}

		completion, err := decodeChatCompletion(respBody)
		if err != nil {
			return AICompletion{}, err
		}
		return completion, nil
	}

	if lastErr == nil {
		lastErr = ErrAIInvalidResponse
	}
	return AICompletion{}, lastErr
}

type chatCompletionRequest struct {
	Model       string        `json:"model"`
	Messages    []chatMessage `json:"messages"`
	Temperature float64       `json:"temperature"`
}

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatCompletionResponse struct {
	Model   string `json:"model"`
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

func decodeChatCompletion(raw []byte) (AICompletion, error) {
	var resp chatCompletionResponse
	if err := json.Unmarshal(raw, &resp); err != nil {
		return AICompletion{}, err
	}
	if len(resp.Choices) == 0 {
		return AICompletion{}, ErrAIInvalidResponse
	}
	content := resp.Choices[0].Message.Content
	if content == "" {
		return AICompletion{}, ErrAIInvalidResponse
	}
	return AICompletion{Content: content, Model: resp.Model, Raw: raw}, nil
}

func backoff(attempt int) {
	if attempt <= 0 {
		return
	}
	base := 200 * time.Millisecond
	sleep := time.Duration(attempt*attempt) * base
	if sleep > 2*time.Second {
		sleep = 2 * time.Second
	}
	time.Sleep(sleep)
}
