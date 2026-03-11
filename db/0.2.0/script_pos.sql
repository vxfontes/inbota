-- ajustes de acentuação

UPDATE inbota.home_insight_templates
SET
    title_template = 'Horários pendentes',
    summary_template = '{{untimed_count}} ainda sem horário.',
    footer_template = 'Defina os horários para se organizar melhor.'
WHERE id = 'bea16b16-fc6f-405a-a6f2-78b2b7a369e1';

UPDATE inbota.home_insight_templates
SET
    title_template = 'Faltam horários',
    summary_template = '{{untimed_count}} compromisso(s) ainda sem horário.',
    footer_template = 'Defina os horários para se organizar melhor.'
WHERE id = 'fa1c0e0e-842c-4349-8701-462e85770fe5';

UPDATE inbota.home_insight_templates
SET
    title_template = 'Melhor momento',
    summary_template = '{{start}} - {{end}} para fazer algo em paz.',
    footer_template = '{{footer_dynamic}}'
WHERE id = '549f4e59-3c8c-40b0-8e1e-1fd55d162e67';

UPDATE inbota.home_insight_templates
SET
    title_template = 'Bom tempo livre',
    summary_template = '{{start}} - {{end}} está disponível.',
    footer_template = 'Dá para resolver algo importante.'
WHERE id = 'f111fc84-70d6-49ee-be0f-4cc7504bfac5';

UPDATE inbota.home_insight_templates
SET
    title_template = 'Tempo livre',
    summary_template = '{{start}} - {{end}} ({{duration}} min livres).',
    footer_template = 'Que tal adiantar algo às {{start}}?'
WHERE id = '61426fe5-cbf2-4451-af11-c73fb44130c4';

UPDATE inbota.home_insight_templates
SET
    title_template = 'Dia mais corrido',
    summary_template = 'Maior tempo livre hoje é {{start}} - {{end}}.',
    footer_template = 'Tente aproveitar pequenas pausas.'
WHERE id = '4bc004a3-dfff-4896-be80-4e9ed9cbb422';

UPDATE inbota.home_insight_templates
SET
    title_template = 'Dia encerrando',
    summary_template = 'Hoje já não há muito tempo útil.',
    footer_template = 'Planeje o dia de amanhã.'
WHERE id = 'ca3fed24-3c4a-4635-a521-34365d878e9f';