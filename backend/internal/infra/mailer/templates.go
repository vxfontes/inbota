package mailer

import (
	"embed"
	"fmt"
	htmltemplate "html/template"
	texttemplate "text/template"
)

//go:embed templates/*.html templates/*.txt
var templatesFS embed.FS

func ParseDailyDigestTemplates() (*htmltemplate.Template, *texttemplate.Template, error) {
	htmlTmpl, err := htmltemplate.ParseFS(templatesFS, "templates/daily_digest.html")
	if err != nil {
		return nil, nil, fmt.Errorf("parse html template: %w", err)
	}

	// O corpo em texto puro do e-mail NÃO pode usar html/template: o escaping
	// contextual de HTML converte '&', '<', '>', '"' e '\'' em entidades
	// (&amp; &lt; &gt; &#34; &#39;), corrompendo títulos de tarefas/eventos
	// digitados pelo usuário (ex.: apóstrofos, "&", etc.) no e-mail de texto.
	textTmpl, err := texttemplate.ParseFS(templatesFS, "templates/daily_digest.txt")
	if err != nil {
		return nil, nil, fmt.Errorf("parse text template: %w", err)
	}

	return htmlTmpl, textTmpl, nil
}