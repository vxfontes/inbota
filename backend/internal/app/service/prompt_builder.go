package service

import (
	"fmt"
	"strings"
	"time"
)

type ContextItem struct {
	FlagID      string
	FlagName    string
	SubflagID   *string
	SubflagName *string
}

type RuleItem struct {
	Keyword   string
	FlagID    string
	SubflagID *string
}

type ContextHint struct {
	FlagID    string
	SubflagID *string
	Reason    string
}

type PromptInput struct {
	RawText  string
	Locale   string
	Timezone string
	Now      time.Time
	Contexts []ContextItem
	Rules    []RuleItem
	Hint     *ContextHint
}

type PromptBuilder struct{}

func NewPromptBuilder() *PromptBuilder {
	return &PromptBuilder{}
}

func (b *PromptBuilder) Build(input PromptInput) string {
	var sb strings.Builder
	writeLine(&sb, "You are an information extraction engine.")
	writeLine(&sb, "Return ONLY a valid JSON object. No markdown, no extra text.")
	writeLine(&sb, "Use RFC3339 timestamps.")
	writeLine(&sb, fmt.Sprintf("Locale: %s", strings.TrimSpace(input.Locale)))
	writeLine(&sb, fmt.Sprintf("Timezone: %s", strings.TrimSpace(input.Timezone)))
	if !input.Now.IsZero() {
		writeLine(&sb, fmt.Sprintf("Now: %s", input.Now.UTC().Format(time.RFC3339)))
	}
	writeLine(&sb, "Raw text:")
	writeLine(&sb, quoteBlock(input.RawText))

	if len(input.Contexts) > 0 {
		writeLine(&sb, "Available contexts:")
		for _, ctx := range input.Contexts {
			line := fmt.Sprintf("- flagId=%s name=%s", ctx.FlagID, ctx.FlagName)
			if ctx.SubflagID != nil && ctx.SubflagName != nil {
				line += fmt.Sprintf(" subflagId=%s name=%s", *ctx.SubflagID, *ctx.SubflagName)
			}
			writeLine(&sb, line)
		}
	}

	if len(input.Rules) > 0 {
		writeLine(&sb, "Context rules (keyword -> context):")
		for _, rule := range input.Rules {
			line := fmt.Sprintf("- \"%s\" -> flagId=%s", rule.Keyword, rule.FlagID)
			if rule.SubflagID != nil {
				line += fmt.Sprintf(" subflagId=%s", *rule.SubflagID)
			}
			writeLine(&sb, line)
		}
	}

	if input.Hint != nil {
		line := fmt.Sprintf("Hinted context: flagId=%s", input.Hint.FlagID)
		if input.Hint.SubflagID != nil {
			line += fmt.Sprintf(" subflagId=%s", *input.Hint.SubflagID)
		}
		if input.Hint.Reason != "" {
			line += fmt.Sprintf(" (reason: %s)", input.Hint.Reason)
		}
		writeLine(&sb, line)
	}

	writeLine(&sb, "Output JSON schema:")
	writeLine(&sb, `{"type":"task|reminder|event|shopping|note","title":"string","confidence":0.0,"context":{"flagId":"string","subflagId":"string|null"},"needs_review":true,"payload":{...}}`)
	writeLine(&sb, "Payload by type:")
	writeLine(&sb, "- task: {\"dueAt\": \"RFC3339|null\"}")
	writeLine(&sb, "- reminder: {\"at\": \"RFC3339\"}")
	writeLine(&sb, "- event: {\"start\": \"RFC3339\", \"end\": \"RFC3339\", \"allDay\": true}")
	writeLine(&sb, "- shopping: {\"items\": [{\"title\": \"string\", \"quantity\": \"string|null\"}]}")
	writeLine(&sb, "- note: {\"content\": \"string\"}")
	writeLine(&sb, "Rules:")
	writeLine(&sb, "- Use needs_review=true when unsure.")
	writeLine(&sb, "- If type=event then end must be >= start.")
	writeLine(&sb, "- If type=shopping then items must be non-empty.")
	writeLine(&sb, "- If type=reminder then payload.at must exist.")

	return sb.String()
}

func writeLine(sb *strings.Builder, line string) {
	sb.WriteString(line)
	sb.WriteByte('\n')
}

func quoteBlock(text string) string {
	trimmed := strings.TrimSpace(text)
	if trimmed == "" {
		return "\"\""
	}
	return "\"" + strings.ReplaceAll(trimmed, "\"", "\\\"") + "\""
}
