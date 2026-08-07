-- Answers the core business questions from the project plan.

USE engagetrack_data_analytics;

-- Q1: Which students have the highest engagement?
-- Engagement score = focused events - distracted events + hand-raise events, normalized per session attended. Higher = more engaged.

SELECT
    st.student_id,
    st.name,
    COUNT(DISTINCT p.session_id) AS sessions_attended,
    SUM(CASE WHEN e.event_type = 'Attention' AND e.description = 'Focused' THEN 1 ELSE 0 END) AS focused_count,
    SUM(CASE WHEN e.event_type = 'Attention' AND e.description LIKE 'Distracted%' THEN 1 ELSE 0 END) AS distracted_count,
    SUM(CASE WHEN e.event_type = 'Hand Motion' AND e.description = 'Hand Raised' THEN 1 ELSE 0 END) AS hand_raise_count,
    ROUND(
        (SUM(CASE WHEN e.event_type = 'Attention' AND e.description = 'Focused' THEN 1 ELSE 0 END)
       - SUM(CASE WHEN e.event_type = 'Attention' AND e.description LIKE 'Distracted%' THEN 1 ELSE 0 END)
       + SUM(CASE WHEN e.event_type = 'Hand Motion' AND e.description = 'Hand Raised' THEN 1 ELSE 0 END))
       / COUNT(DISTINCT p.session_id), 2
    ) AS engagement_score_per_session
FROM students st
JOIN participants p ON st.student_id = p.student_id
JOIN events e ON p.participant_id = e.participant_id
GROUP BY st.student_id, st.name
ORDER BY engagement_score_per_session DESC
LIMIT 15;

-- Q2: What are the peak usage hours?
-- Counts sessions by the hour they started.
SELECT
    HOUR(created_at) AS start_hour,
    COUNT(*) AS session_count
FROM sessions
GROUP BY HOUR(created_at)
ORDER BY session_count DESC;

-- Q3: Which event types (features/signals) are used the most?
SELECT
    event_type,
    description,
    COUNT(*) AS occurrences,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM events), 2) AS pct_of_all_events
FROM events
GROUP BY event_type, description
ORDER BY occurrences DESC;

-- Q4: How long do users stay engaged in a session (avg attendance duration)?

SELECT
    st.student_id,
    st.name,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, p.joined_at, p.left_at)), 1) AS avg_minutes_in_session,
    COUNT(DISTINCT p.session_id) AS sessions_attended
FROM students st
JOIN participants p ON st.student_id = p.student_id
GROUP BY st.student_id, st.name
ORDER BY avg_minutes_in_session ASC
LIMIT 15;

-- Q5: What percentage of students return for another session?
-- (attended more than 1 session out of all students who attended at least 1)

SELECT
    COUNT(DISTINCT CASE WHEN session_count > 1 THEN student_id END) AS returning_students,
    COUNT(DISTINCT student_id) AS total_students_who_attended,
    ROUND(
        COUNT(DISTINCT CASE WHEN session_count > 1 THEN student_id END) * 100.0
        / COUNT(DISTINCT student_id), 2
    ) AS pct_returning
FROM (
    SELECT student_id, COUNT(DISTINCT session_id) AS session_count
    FROM participants
    GROUP BY student_id
) sub;

-- Q6: How does engagement vary over time (week by week)?

SELECT
    YEARWEEK(s.created_at, 1) AS year_week,
    COUNT(DISTINCT s.session_id) AS sessions_held,
    SUM(CASE WHEN e.event_type = 'Attention' AND e.description = 'Focused' THEN 1 ELSE 0 END) AS focused_events,
    SUM(CASE WHEN e.event_type = 'Attention' AND e.description LIKE 'Distracted%' THEN 1 ELSE 0 END) AS distracted_events,
    SUM(CASE WHEN e.event_type = 'Fatigue' THEN 1 ELSE 0 END) AS fatigue_events
FROM sessions s
JOIN events e ON s.session_id = e.session_id
GROUP BY YEARWEEK(s.created_at, 1)
ORDER BY year_week;

-- Q7: Which students might be at risk of dropping off?

SELECT
    st.student_id,
    st.name,
    COUNT(DISTINCT p.session_id) AS sessions_attended,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, p.joined_at, p.left_at) <
        (SELECT AVG(TIMESTAMPDIFF(MINUTE, s.created_at, s.ended_at)) FROM sessions s WHERE s.session_id = p.session_id) * 0.7
        THEN 1 ELSE 0 END) AS early_leave_count,
    ROUND(
        SUM(CASE WHEN e.event_type IN ('Fatigue') OR (e.event_type = 'Attention' AND e.description LIKE 'Distracted%') THEN 1 ELSE 0 END)
        / COUNT(e.event_id) * 100, 1
    ) AS pct_disengaged_events
FROM students st
JOIN participants p ON st.student_id = p.student_id
JOIN events e ON p.participant_id = e.participant_id
GROUP BY st.student_id, st.name
HAVING pct_disengaged_events > 40 OR early_leave_count >= 2
ORDER BY pct_disengaged_events DESC;

-- Bonus: What was being said when fatigue/distraction spiked?
-- Ties engagement dips back to lecture content via speech_context.
SELECT
    e.speech_context,
    COUNT(*) AS disengaged_event_count
FROM events e
WHERE e.event_type = 'Fatigue'
   OR (e.event_type = 'Attention' AND e.description LIKE 'Distracted%')
GROUP BY e.speech_context
ORDER BY disengaged_event_count DESC
LIMIT 10;