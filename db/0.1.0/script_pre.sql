-- Home optimization objects (v0.1.0)

CREATE TABLE IF NOT EXISTS inbota.home_insight_templates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category text NOT NULL,
    title_template text NOT NULL,
    summary_template text NOT NULL,
    footer_template text NOT NULL,
    is_focus boolean NOT NULL DEFAULT false,
    min_gap_minutes int,
    priority int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_home_insight_templates_category_priority
    ON inbota.home_insight_templates (category, priority DESC);

CREATE OR REPLACE VIEW inbota.vw_home_timeline_today AS
SELECT
    'event'::text AS item_type,
    id,
    user_id,
    title,
    location AS subtitle,
    start_at AS scheduled_time,
    end_at AS end_scheduled_time,
    false AS is_completed,
    created_at
FROM inbota.events
WHERE start_at::date = CURRENT_DATE
UNION ALL
SELECT
    'task'::text AS item_type,
    id,
    user_id,
    title,
    description AS subtitle,
    due_at AS scheduled_time,
    NULL::timestamptz AS end_scheduled_time,
    (status = 'DONE') AS is_completed,
    created_at
FROM inbota.tasks
WHERE due_at::date = CURRENT_DATE
UNION ALL
SELECT
    'reminder'::text AS item_type,
    id,
    user_id,
    title,
    NULL::text AS subtitle,
    remind_at AS scheduled_time,
    NULL::timestamptz AS end_scheduled_time,
    (status = 'DONE') AS is_completed,
    created_at
FROM inbota.reminders
WHERE remind_at::date = CURRENT_DATE;