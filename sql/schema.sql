-- EngageTrack SQL Analytics — schema.sql
-- Database: engagetrack_data_analytics

CREATE TABLE lecturers (
    lecturer_id      VARCHAR(10) PRIMARY KEY,
    name             VARCHAR(100) NOT NULL,
    department       VARCHAR(100),
    joined_platform  DATETIME
);

CREATE TABLE students (
    student_id  VARCHAR(10) PRIMARY KEY,
    name        VARCHAR(100) NOT NULL
);

CREATE TABLE sessions (
    session_id        VARCHAR(12) PRIMARY KEY,
    lecturer_id       VARCHAR(10) NOT NULL,
    lecturer_name     VARCHAR(100),
    session_name      VARCHAR(200),
    created_at        DATETIME NOT NULL,
    ended_at          DATETIME,
    status            VARCHAR(20),
    duration_minutes  INT,
    FOREIGN KEY (lecturer_id) REFERENCES lecturers(lecturer_id)
);

CREATE TABLE participants (
    participant_id  VARCHAR(12) PRIMARY KEY,
    session_id      VARCHAR(12) NOT NULL,
    student_id      VARCHAR(10) NOT NULL,
    student_name    VARCHAR(100),
    joined_at       DATETIME,
    left_at         DATETIME,
    FOREIGN KEY (session_id) REFERENCES sessions(session_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE events (
    event_id        VARCHAR(14) PRIMARY KEY,
    session_id      VARCHAR(12) NOT NULL,
    participant_id  VARCHAR(12) NOT NULL,
    student_id      VARCHAR(10) NOT NULL,
    student_name    VARCHAR(100),
    timestamp       DATETIME NOT NULL,
    event_type      VARCHAR(20),
    description     VARCHAR(100),
    speech_context   TEXT,
    FOREIGN KEY (session_id) REFERENCES sessions(session_id),
    FOREIGN KEY (participant_id) REFERENCES participants(participant_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE transcriptions (
    transcription_id  VARCHAR(14) PRIMARY KEY,
    session_id        VARCHAR(12) NOT NULL,
    timestamp         DATETIME NOT NULL,
    speaker           VARCHAR(100),
    text              TEXT,
    FOREIGN KEY (session_id) REFERENCES sessions(session_id)
);