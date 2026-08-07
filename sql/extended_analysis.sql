--   Track A (Q9-Q12, Q16-Q17): classroom engagement, for lecturers
--   Track B (Q13-Q15): product/platform usage, for the EngageTrack team

USE engagetrack_data_analytics;

-- Q9: Which lecturers have the most engaged classes?
-- Avg focused vs distracted/fatigue rate across all sessions each lecturer ran.

SELECT
    l.lecturer_id,
    l.name,
    COUNT(DISTINCT s.session_id) AS sessions_taught,
    SUM(CASE WHEN e.description = 'Focused' THEN 1 ELSE 0 END) AS focused_count,
    SUM(CASE WHEN e.description = 'Distracted' THEN 1 ELSE 0 END) AS distracted_count,
    SUM(CASE WHEN e.event_type = 'Fatigue' THEN 1 ELSE 0 END) AS fatigue_count,
    ROUND(
        SUM(CASE WHEN e.description = 'Focused' THEN 1 ELSE 0 END) * 100.0 / COUNT(e.event_id), 1
    ) AS pct_focused
FROM lecturers l
JOIN sessions s ON l.lecturer_id = s.lecturer_id
JOIN events e ON s.session_id = e.session_id
GROUP BY l.lecturer_id, l.name
ORDER BY pct_focused DESC;

-- Q10: Do longer sessions correlate with more fatigue?
-- Buckets sessions by duration, shows fatigue rate per bucket.

SELECT
    CASE
        WHEN s.duration_minutes <= 45 THEN '<=45 min'
        WHEN s.duration_minutes <= 90 THEN '46-90 min'
        WHEN s.duration_minutes <= 150 THEN '91-150 min'
        ELSE '150+ min'
    END AS duration_bucket,
    COUNT(DISTINCT s.session_id) AS session_count,
    ROUND(
        SUM(CASE WHEN e.event_type = 'Fatigue' THEN 1 ELSE 0 END) * 100.0 / COUNT(e.event_id), 1
    ) AS pct_fatigue_events
FROM sessions s
JOIN events e ON s.session_id = e.session_id
WHERE s.duration_minutes IS NOT NULL
GROUP BY duration_bucket
ORDER BY MIN(s.duration_minutes);

-- Q11: Distraction rate by minutes elapsed since session start.
-- Do students zone out ~30 minutes in?

SELECT
    FLOOR(TIMESTAMPDIFF(MINUTE, s.created_at, e.timestamp) / 15) * 15 AS minutes_into_session,
    COUNT(*) AS total_events,
    ROUND(SUM(CASE WHEN e.description = 'Distracted' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_distracted
FROM sessions s
JOIN events e ON s.session_id = e.session_id
WHERE TIMESTAMPDIFF(MINUTE, s.created_at, e.timestamp) >= 0
GROUP BY minutes_into_session
ORDER BY minutes_into_session;

-- Q12: Which students improved over time?

WITH student_session_order AS (
    SELECT DISTINCT
        p.student_id,
        p.session_id,
        s.created_at,
        NTILE(2) OVER (PARTITION BY p.student_id ORDER BY s.created_at) AS half
    FROM participants p
    JOIN sessions s ON p.session_id = s.session_id
),
scored AS (
    SELECT
        sso.student_id,
        sso.half,
        SUM(CASE WHEN e.description = 'Focused' THEN 1 ELSE 0 END)
      - SUM(CASE WHEN e.description = 'Distracted' THEN 1 ELSE 0 END) AS net_score
    FROM student_session_order sso
    JOIN participants p ON sso.student_id = p.student_id AND sso.session_id = p.session_id
    JOIN events e ON p.participant_id = e.participant_id
    GROUP BY sso.student_id, sso.half
)
SELECT
    st.student_id,
    st.name,
    MAX(CASE WHEN half = 1 THEN net_score END) AS early_net_score,
    MAX(CASE WHEN half = 2 THEN net_score END) AS later_net_score,
    MAX(CASE WHEN half = 2 THEN net_score END) - MAX(CASE WHEN half = 1 THEN net_score END) AS improvement
FROM scored
JOIN students st ON scored.student_id = st.student_id
GROUP BY st.student_id, st.name
HAVING early_net_score IS NOT NULL AND later_net_score IS NOT NULL
ORDER BY improvement DESC
LIMIT 15;

-- Q13: Which lecturers use the platform most? (session count = power users)

SELECT
    l.lecturer_id,
    l.name,
    l.department,
    COUNT(s.session_id) AS sessions_run,
    SUM(s.duration_minutes) AS total_minutes_taught
FROM lecturers l
LEFT JOIN sessions s ON l.lecturer_id = s.lecturer_id
GROUP BY l.lecturer_id, l.name, l.department
ORDER BY sessions_run DESC;

-- ============================================================
-- Q14: Average session duration trend over time (weekly).
-- ============================================================
SELECT
    YEARWEEK(created_at, 1) AS year_week,
    COUNT(*) AS sessions_held,
    ROUND(AVG(duration_minutes), 1) AS avg_duration_minutes
FROM sessions
WHERE duration_minutes IS NOT NULL
GROUP BY YEARWEEK(created_at, 1)
ORDER BY year_week;

-- Q15: Which department uses EngageTrack most?

SELECT
    l.department,
    COUNT(DISTINCT l.lecturer_id) AS lecturers_in_dept,
    COUNT(s.session_id) AS sessions_run,
    ROUND(COUNT(s.session_id) * 1.0 / COUNT(DISTINCT l.lecturer_id), 1) AS avg_sessions_per_lecturer
FROM lecturers l
LEFT JOIN sessions s ON l.lecturer_id = s.lecturer_id
GROUP BY l.department
ORDER BY sessions_run DESC;

-- Q16: Engagement arc — does focus drop as a session progresses,
-- normalized to % of the way through each session (not absolute minutes)?

SELECT
    CASE
        WHEN pct_elapsed < 25 THEN '0-25%'
        WHEN pct_elapsed < 50 THEN '25-50%'
        WHEN pct_elapsed < 75 THEN '50-75%'
        ELSE '75-100%'
    END AS session_quartile,
    COUNT(*) AS total_events,
    ROUND(SUM(CASE WHEN description = 'Focused' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_focused,
    ROUND(SUM(CASE WHEN description = 'Distracted' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_distracted
FROM (
    SELECT
        e.description,
        (TIMESTAMPDIFF(SECOND, s.created_at, e.timestamp) * 100.0
         / NULLIF(TIMESTAMPDIFF(SECOND, s.created_at, s.ended_at), 0)) AS pct_elapsed
    FROM sessions s
    JOIN events e ON s.session_id = e.session_id
    WHERE s.ended_at IS NOT NULL
) sub
WHERE pct_elapsed BETWEEN 0 AND 100
GROUP BY session_quartile
ORDER BY session_quartile;

-- Q17: Which sessions had the worst engagement?
-- Ranks sessions by % of events that were Distracted or Fatigue-type.

SELECT
    s.session_id,
    s.session_name,
    l.name AS lecturer_name,
    s.created_at,
    COUNT(e.event_id) AS total_events,
    ROUND(
        SUM(CASE WHEN e.description = 'Distracted' OR e.event_type = 'Fatigue' THEN 1 ELSE 0 END) * 100.0
        / COUNT(e.event_id), 1
    ) AS pct_disengaged
FROM sessions s
JOIN lecturers l ON s.lecturer_id = l.lecturer_id
JOIN events e ON s.session_id = e.session_id
GROUP BY s.session_id, s.session_name, l.name, s.created_at
ORDER BY pct_disengaged DESC
LIMIT 10;