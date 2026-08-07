"""
EngageTrack Synthetic Data Generator
=====================================
This script generates realistic synthetic data for the EngageTrack
classroom engagement analytics project.

Tables generated:
- lecturers.csv      : 10 lecturers/admins
- students.csv       : 80 unique students
- sessions.csv       : 50 class sessions
- participants.csv   : 700 student-session join records
- events.csv         : ~8,600 engagement signals
- transcriptions.csv : 1,230 timestamped speech entries

"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os

# Set seed for reproducibility
random.seed(42)
np.random.seed(42)

# ============================================
# CONFIGURATION
# ============================================
N_LECTURERS = 10
N_SESSIONS = 50
N_STUDENTS = 80
DATE_RANGE_START = datetime(2025, 9, 1)
DATE_RANGE_END = datetime(2025, 11, 30)

# ============================================
# DATA POOLS
# ============================================
LECTURER_FIRST_NAMES = ["Dr. Amina", "Prof. James", "Dr. Chioma", "Prof. Ibrahim",
                        "Dr. Fatima", "Prof. Kunle", "Dr. Ngozi", "Prof. Ahmed",
                        "Dr. Zara", "Prof. David"]
LECTURER_LAST_NAMES = ["Okafor", "Smith", "Adeyemi", "Mohammed", "Bello",
                       "Nwosu", "Okonkwo", "Abubakar", "Hassan", "Johnson"]

STUDENT_FIRST_NAMES = ["Alice", "Bob", "Charlie", "Diana", "Evan", "Fiona", "George", "Hannah",
                       "Ian", "Julia", "Kevin", "Linda", "Michael", "Nina", "Oscar", "Paula",
                       "Quinn", "Rachel", "Sam", "Tina", "Umar", "Vera", "Wale", "Xena",
                       "Yusuf", "Zara", "Ade", "Bisi", "Chidi", "Dara", "Emeka", "Funmi",
                       "Gbenga", "Halima", "Ifeanyi", "Jide", "Kemi", "Lola", "Musa", "Nkechi",
                       "Olu", "Patience", "Qudus", "Rashida", "Sani", "Tolu", "Uche", "Victor",
                       "Wunmi", "Xavier", "Yemi", "Zainab", "Abdul", "Blessing", "Chinwe", "Dayo",
                       "Esther", "Femi", "Gloria", "Habib", "Idris", "Joy", "Kazeem", "Lami",
                       "Maryam", "Nnamdi", "Obi", "Peace", "Quadri", "Rukayat", "Segun", "Temitope",
                       "Umaru", "Vivian", "Williams", "Yakubu", "Zubair"]

COURSE_NAMES = [
    "Introduction to Python Programming",
    "Data Structures and Algorithms",
    "Database Management Systems",
    "Software Engineering Principles",
    "Web Development Fundamentals",
    "Machine Learning Basics",
    "Computer Networks",
    "Operating Systems",
    "Cybersecurity Essentials",
    "Cloud Computing",
    "Mobile App Development",
    "Artificial Intelligence",
    "Big Data Analytics",
    "DevOps Practices",
    "UI/UX Design"
]

EVENT_TYPES = ["Attention", "Hand Motion", "Fatigue"]
ATTENTION_DESCRIPTIONS = ["Focused", "Distracted (looking sideways and up)",
                          "Distracted (looking sideways and down)", "Distracted (looking away)"]
HAND_DESCRIPTIONS = ["Hand Detected", "Hand Not Detected"]
FATIGUE_DESCRIPTIONS = ["Yawning detected", "Blinking rate high", "Drowsy", "Eyes closed"]

SPEECH_CONTEXTS = [
    "Today we will discuss loops and conditionals",
    "Can anyone explain what a variable is",
    "Let's look at this example together",
    "The assignment is due next Friday",
    "Please pay attention to this section",
    "Any questions so far",
    "This concept is very important for the exam",
    "Let me show you how this works in practice",
    "Group discussion starts now",
    "Please open your IDEs and follow along",
    "The database schema looks like this",
    "Remember to commit your changes regularly",
    "Let's take a five minute break",
    "Who can tell me the difference between SQL and NoSQL",
    "This is the final topic for today",
    "Please submit your work before leaving",
    "The API endpoint returns a JSON response",
    "Let's debug this code together",
    "Make sure to test your functions",
    "The project requirements are on the portal"
]

# ============================================
# 1. GENERATE LECTURERS
# ============================================
lecturers = []
for i in range(N_LECTURERS):
    lecturer_id = f"LEC{str(i+1).zfill(3)}"
    name = f"{LECTURER_FIRST_NAMES[i]} {LECTURER_LAST_NAMES[i]}"
    email = f"{name.lower().replace('dr. ', '').replace('prof. ', '').replace(' ', '.')}@university.edu.ng"
    dept = random.choice(["Computer Science", "Software Engineering", "Information Technology", "Data Science"])
    joined_platform = DATE_RANGE_START - timedelta(days=random.randint(30, 180))
    lecturers.append({
        "lecturer_id": lecturer_id,
        "name": name,
        "email": email,
        "department": dept,
        "joined_platform": joined_platform.strftime("%Y-%m-%d %H:%M:%S")
    })

df_lecturers = pd.DataFrame(lecturers)

# ============================================
# 2. GENERATE STUDENTS
# ============================================
students = []
for i in range(N_STUDENTS):
    student_id = f"STU{str(i+1).zfill(3)}"
    name = STUDENT_FIRST_NAMES[i % len(STUDENT_FIRST_NAMES)]
    if i >= len(STUDENT_FIRST_NAMES):
        name += f" {LECTURER_LAST_NAMES[i % len(LECTURER_LAST_NAMES)]}"
    else:
        name += f" {random.choice(LECTURER_LAST_NAMES)}"

    profiles = ["high_engaged", "moderate", "low_engaged", "erratic"]
    profile_weights = [0.25, 0.40, 0.20, 0.15]
    engagement_profile = random.choices(profiles, weights=profile_weights)[0]

    students.append({
        "student_id": student_id,
        "name": name,
        "engagement_profile": engagement_profile,
        "email": f"{name.lower().replace(' ', '.')}@student.university.edu.ng"
    })

df_students = pd.DataFrame(students)

# ============================================
# 3. GENERATE SESSIONS
# ============================================
sessions = []
for i in range(N_SESSIONS):
    lecturer = random.choice(lecturers)
    days_offset = random.randint(0, (DATE_RANGE_END - DATE_RANGE_START).days)
    session_date = DATE_RANGE_START + timedelta(days=days_offset)
    start_hour = random.randint(8, 16)
    start_minute = random.choice([0, 15, 30, 45])
    created_at = session_date.replace(hour=start_hour, minute=start_minute, second=0)
    duration_minutes = random.choice([45, 60, 75, 90, 120, 150, 180])
    ended_at = created_at + timedelta(minutes=duration_minutes)

    if session_date.date() >= datetime(2025, 11, 20).date() and random.random() < 0.3:
        status = "ongoing" if random.random() < 0.7 else "cancelled"
    else:
        status = "completed"

    course = random.choice(COURSE_NAMES)
    session_name = f"{course} - Week {random.randint(1, 12)}"

    sessions.append({
        "session_id": f"SES{str(i+1).zfill(6)}",
        "lecturer_id": lecturer["lecturer_id"],
        "lecturer_name": lecturer["name"],
        "session_name": session_name,
        "created_at": created_at.strftime("%Y-%m-%d %H:%M:%S"),
        "ended_at": ended_at.strftime("%Y-%m-%d %H:%M:%S") if status != "ongoing" else None,
        "status": status,
        "duration_minutes": duration_minutes if status != "ongoing" else None
    })

df_sessions = pd.DataFrame(sessions)
df_sessions = df_sessions.sort_values("created_at").reset_index(drop=True)
for i in range(len(df_sessions)):
    df_sessions.at[i, "session_id"] = f"SES{str(i+1).zfill(6)}"

# ============================================
# 4. GENERATE PARTICIPANTS
# ============================================
participants = []
participant_id_counter = 1

for _, session in df_sessions.iterrows():
    session_id = session["session_id"]
    session_created = datetime.strptime(session["created_at"], "%Y-%m-%d %H:%M:%S")
    session_ended = datetime.strptime(session["ended_at"], "%Y-%m-%d %H:%M:%S") if session["ended_at"] else None
    duration = session["duration_minutes"] if session["duration_minutes"] else 60

    n_participants = random.randint(3, 25)
    session_students = random.sample(students, min(n_participants, len(students)))

    for student in session_students:
        join_delay = random.randint(0, 10)
        joined_at = session_created + timedelta(minutes=join_delay)

        leave_early_prob = 0.15 if student["engagement_profile"] in ["low_engaged", "erratic"] else 0.05

        if session_ended:
            if random.random() < leave_early_prob:
                min_stay = 5
                max_leave = max(min_stay + 1, int((session_ended - joined_at).total_seconds() / 60) - 5)
                if max_leave > min_stay:
                    left_early_minutes = random.randint(min_stay, max_leave)
                    left_at = joined_at + timedelta(minutes=left_early_minutes)
                else:
                    left_at = session_ended
            else:
                left_at = session_ended
        else:
            left_at = joined_at + timedelta(minutes=duration)

        participants.append({
            "participant_id": f"PAR{str(participant_id_counter).zfill(6)}",
            "session_id": session_id,
            "student_id": student["student_id"],
            "student_name": student["name"],
            "joined_at": joined_at.strftime("%Y-%m-%d %H:%M:%S"),
            "left_at": left_at.strftime("%Y-%m-%d %H:%M:%S") if left_at else None,
            "engagement_profile": student["engagement_profile"]
        })
        participant_id_counter += 1

df_participants = pd.DataFrame(participants)

# ============================================
# 5. GENERATE EVENTS
# ============================================
events = []
event_id_counter = 1

for _, participant in df_participants.iterrows():
    session_id = participant["session_id"]
    student_id = participant["student_id"]
    student_name = participant["student_name"]
    profile = participant["engagement_profile"]

    joined = datetime.strptime(participant["joined_at"], "%Y-%m-%d %H:%M:%S")
    left = datetime.strptime(participant["left_at"], "%Y-%m-%d %H:%M:%S") if participant["left_at"] else joined + timedelta(minutes=60)
    session_duration = (left - joined).total_seconds() / 60

    if profile == "high_engaged":
        base_events = random.randint(8, 15)
    elif profile == "moderate":
        base_events = random.randint(5, 12)
    elif profile == "low_engaged":
        base_events = random.randint(3, 8)
    else:
        base_events = random.randint(6, 14)

    n_events = max(3, int(base_events * (session_duration / 60)))

    for _ in range(n_events):
        max_offset = int((left - joined).total_seconds())
        if max_offset <= 0:
            max_offset = 60
        offset_seconds = random.randint(0, max_offset)
        event_time = joined + timedelta(seconds=offset_seconds)

        if profile == "high_engaged":
            event_type = random.choices(["Attention", "Hand Motion", "Fatigue"], weights=[0.50, 0.35, 0.15])[0]
        elif profile == "moderate":
            event_type = random.choices(["Attention", "Hand Motion", "Fatigue"], weights=[0.55, 0.25, 0.20])[0]
        elif profile == "low_engaged":
            event_type = random.choices(["Attention", "Hand Motion", "Fatigue"], weights=[0.40, 0.15, 0.45])[0]
        else:
            event_type = random.choices(["Attention", "Hand Motion", "Fatigue"], weights=[0.45, 0.30, 0.25])[0]

        if event_type == "Attention":
            if profile == "high_engaged":
                desc = random.choices(ATTENTION_DESCRIPTIONS, weights=[0.75, 0.10, 0.10, 0.05])[0]
            elif profile == "moderate":
                desc = random.choices(ATTENTION_DESCRIPTIONS, weights=[0.50, 0.25, 0.15, 0.10])[0]
            elif profile == "low_engaged":
                desc = random.choices(ATTENTION_DESCRIPTIONS, weights=[0.20, 0.30, 0.30, 0.20])[0]
            else:
                desc = random.choices(ATTENTION_DESCRIPTIONS, weights=[0.35, 0.25, 0.25, 0.15])[0]
        elif event_type == "Hand Motion":
            desc = random.choices(HAND_DESCRIPTIONS, weights=[0.70, 0.30])[0]
        else:
            if profile == "low_engaged":
                desc = random.choices(FATIGUE_DESCRIPTIONS, weights=[0.35, 0.30, 0.25, 0.10])[0]
            else:
                desc = random.choices(FATIGUE_DESCRIPTIONS, weights=[0.25, 0.35, 0.25, 0.15])[0]

        speech = random.choice(SPEECH_CONTEXTS)

        events.append({
            "event_id": f"EVT{str(event_id_counter).zfill(8)}",
            "session_id": session_id,
            "participant_id": participant["participant_id"],
            "student_id": student_id,
            "student_name": student_name,
            "timestamp": event_time.strftime("%Y-%m-%d %H:%M:%S"),
            "event_type": event_type,
            "description": desc,
            "speech_context": speech
        })
        event_id_counter += 1

df_events = pd.DataFrame(events)

# ============================================
# 6. GENERATE TRANSCRIPTIONS
# ============================================
transcriptions = []
transcription_id_counter = 1

for _, session in df_sessions.iterrows():
    session_id = session["session_id"]
    session_created = datetime.strptime(session["created_at"], "%Y-%m-%d %H:%M:%S")
    session_ended = datetime.strptime(session["ended_at"], "%Y-%m-%d %H:%M:%S") if session["ended_at"] else session_created + timedelta(minutes=60)
    duration = (session_ended - session_created).total_seconds() / 60
    n_transcript_entries = max(5, int(duration / 4))

    session_participants = df_participants[df_participants["session_id"] == session_id]["student_name"].tolist()
    lecturer_name = session["lecturer_name"]
    speakers = [lecturer_name] + session_participants[:min(5, len(session_participants))]

    transcript_texts = [
        "Good morning everyone, let's begin today's class",
        "Can someone summarize what we covered last week",
        "That's correct, well done",
        "Please pay attention to this important concept",
        "Any questions before we move on",
        "Let's look at a practical example",
        "The deadline for the assignment is next Friday",
        "Make sure to review the reading material",
        "This will be on the exam, so take notes",
        "Let's take a short break and continue",
        "Who wants to share their screen",
        "That's an interesting question",
        "Let me clarify that point",
        "Everyone following so far",
        "Great participation today",
        "We'll continue this topic in the next class",
        "Please submit your work on the portal",
        "Remember to check your email for updates",
        "The quiz will be open book",
        "Let's wrap up for today, see you next time"
    ]

    for i in range(n_transcript_entries):
        offset = random.randint(0, int((session_ended - session_created).total_seconds()))
        ts = session_created + timedelta(seconds=offset)
        speaker = random.choice(speakers) if speakers else lecturer_name
        text = random.choice(transcript_texts)

        transcriptions.append({
            "transcription_id": f"TRN{str(transcription_id_counter).zfill(8)}",
            "session_id": session_id,
            "timestamp": ts.strftime("%Y-%m-%d %H:%M:%S"),
            "speaker": speaker,
            "text": text
        })
        transcription_id_counter += 1

df_transcriptions = pd.DataFrame(transcriptions)
df_transcriptions = df_transcriptions.sort_values(["session_id", "timestamp"]).reset_index(drop=True)

# ============================================
# SAVE ALL CSVs
# ============================================
output_dir = "engagement_analytics_data/"
os.makedirs(output_dir, exist_ok=True)

df_lecturers.to_csv(f"{output_dir}lecturers.csv", index=False)
df_sessions.to_csv(f"{output_dir}sessions.csv", index=False)
df_students.to_csv(f"{output_dir}students.csv", index=False)
df_participants.to_csv(f"{output_dir}participants.csv", index=False)
df_events.to_csv(f"{output_dir}events.csv", index=False)
df_transcriptions.to_csv(f"{output_dir}transcriptions.csv", index=False)

print("=" * 50)
print("SYNTHETIC DATA GENERATION COMPLETE")
print("=" * 50)
print(f"lecturers.csv       : {len(df_lecturers):>6} rows")
print(f"sessions.csv        : {len(df_sessions):>6} rows")
print(f"students.csv        : {len(df_students):>6} rows")
print(f"participants.csv    : {len(df_participants):>6} rows")
print(f"events.csv          : {len(df_events):>6} rows")
print(f"transcriptions.csv  : {len(df_transcriptions):>6} rows")
print("=" * 50)
print(f"\nAll files saved to: {output_dir}")
