-- STEP 1: Rename descriptions to match your app

-- "Hand Detected" → "Hand Raised"
UPDATE events 
SET description = 'Hand Raised' 
WHERE description = 'Hand Detected';

-- "Blinking rate high" → "Blinking"
UPDATE events 
SET description = 'Blinking' 
WHERE description = 'Blinking rate high';

-- "Yawning detected" → "Yawning"
UPDATE events 
SET description = 'Yawning' 
WHERE description = 'Yawning detected';

-- All "Distracted (...)" → just "Distracted"
UPDATE events 
SET description = 'Distracted' 
WHERE description LIKE 'Distracted%';

-- STEP 2: Delete anything that doesn't match your 5 types

DELETE FROM events
WHERE description NOT IN (
    'Focused',
    'Distracted',
    'Hand Raised',
    'Yawning',
    'Blinking'
);

-- STEP 3: Verify — this should match your desired output exactly

SELECT 
    event_type,
    description,
    COUNT(*) AS count
FROM events
GROUP BY event_type, description
ORDER BY event_type, count DESC;