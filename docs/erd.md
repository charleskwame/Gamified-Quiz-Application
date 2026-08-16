# Gamified Quiz App — Entity Relationship Diagrams

> Generated from `lib/models/`, `lib/services/`, and `firestore.rules`.

## 1. Logical ERD

Entities and relationships (source: `docs/erd_logical.mmd`).

```mermaid
erDiagram
    USER ||--o{ RANK_HISTORY : "has (subcollection)"
    USER ||--o| PUBLIC_PROFILE : "mirrored (same uid)"
    USER }o--o{ BADGE : "unlocks (badges: List<String>)"
    USER }o--o{ INCORRECT_QUESTION : "contributes to"
    QUESTION ||--o{ INCORRECT_QUESTION : "tracked in"

    USER {
        string id PK "users/{uid}"
        string displayName
        string email
        bool emailVerified
        int score "XP - drives level"
        int quizCoins "secondary currency"
        int shieldCount "power-up inventory"
        int skipCount
        int pauseTimerCount
        int computerArchitecturePoints
        int caAnswered
        int caCorrect
        int computerNetworkingPoints
        int cnAnswered
        int cnCorrect
        int softwareEngineeringPoints
        int seAnswered
        int seCorrect
        int questionsCorrect
        int questionsAnswered
        int streakNumber
        array badges "unlocked badge ids"
        array selectedBadges "displayed badges"
        string avatarUrl
        map avatarDetails
        timestamp createdAt
    }

    PUBLIC_PROFILE {
        string userId PK "publicProfiles/{uid}"
        string displayName
        int score
        int computerArchitecturePoints
        int computerNetworkingPoints
        int softwareEngineeringPoints
        int streakNumber
        array badges
        array selectedBadges
        string avatarUrl
        timestamp createdAt
        timestamp updatedAt
    }

    RANK_HISTORY {
        string id PK "users/{uid}/rankHistory/{id}"
        string rank "A/B/C/D/E/F/S"
        string category
        float percentage
        timestamp timestamp
    }

    BADGE {
        string id PK "e.g. first_steps, streak_master"
        string name
        string description
        string unlockRule "code-defined check"
    }

    QUESTION {
        string id PK "collection keyed by category"
        string questionText
        array options
        string correctAnswer
        string explanation
        string category
    }

    INCORRECT_QUESTION {
        string questionId PK
        int number_of_wrong "global counter"
    }
```

## 2. Physical Firestore Collections

Source: `docs/erd_firestore.mmd`.

```mermaid
erDiagram
    USERS ||--o{ RANK_HISTORY : "subcollection"
    USERS ||--o| PUBLIC_PROFILES : "same doc id = uid"
    USERS }o--o{ CA_INCORRECT : "contributes to"
    USERS }o--o{ CN_INCORRECT : "contributes to"
    USERS }o--o{ SE_INCORRECT : "contributes to"
    CA_QUESTIONS ||--o{ CA_INCORRECT : ""
    CN_QUESTIONS ||--o{ CN_INCORRECT : ""
    SE_QUESTIONS ||--o{ SE_INCORRECT : ""

    USERS {
        string id PK "users/{uid}"
        string displayName
        string email
        bool emailVerified
        int score
        int quizCoins
        int shieldCount
        int skipCount
        int pauseTimerCount
        int computerArchitecturePoints
        int caAnswered
        int caCorrect
        int computerNetworkingPoints
        int cnAnswered
        int cnCorrect
        int softwareEngineeringPoints
        int seAnswered
        int seCorrect
        int questionsCorrect
        int questionsAnswered
        int streakNumber
        array badges
        array selectedBadges
        string avatarUrl
        map avatarDetails
        timestamp createdAt
    }

    RANK_HISTORY {
        string id PK "users/{uid}/rankHistory/{id}"
        string rank
        string category
        number percentage
        timestamp timestamp
    }

    PUBLIC_PROFILES {
        string id PK "publicProfiles/{uid}"
        string displayName
        int score
        int computerArchitecturePoints
        int computerNetworkingPoints
        int softwareEngineeringPoints
        int streakNumber
        array badges
        array selectedBadges
        string avatarUrl
        timestamp createdAt
        timestamp updatedAt
    }

    CA_QUESTIONS {
        string id PK "computer_architecture_questions/{qid}"
        string questionText
        array options
        string correctAnswer
        string explanation
        string category
    }

    CN_QUESTIONS {
        string id PK "computer_networking_questions/{qid}"
        string questionText
        array options
        string correctAnswer
        string explanation
        string category
    }

    SE_QUESTIONS {
        string id PK "software_engineering_questions/{qid}"
        string questionText
        array options
        string correctAnswer
        string explanation
        string category
    }

    CA_INCORRECT {
        string id PK "computer_architecture_questions_gotten_incorrectly/{qid}"
        string questionId
        int number_of_wrong
    }

    CN_INCORRECT {
        string id PK "computer_networking_questions_gotten_incorrectly/{qid}"
        string questionId
        int number_of_wrong
    }

    SE_INCORRECT {
        string id PK "software_engineering_questions_gotten_incorrectly/{qid}"
        string questionId
        int number_of_wrong
    }
```

## Key notes

- **`users` ↔ `publicProfiles`** — 1:1 by shared document ID (`uid`). `users` is private (email, power-up inventory, per-category stats); `publicProfiles` is a publicly-readable leaderboard mirror.
- **`rankHistory`** is a Firestore **subcollection** under each user: `users/{uid}/rankHistory/{id}`.
- **Badges** are not stored as documents — the 50+ `BadgeDefinition`s live in code (`lib/models/badge.dart`); the DB stores only a denormalized `badges: List<String>` of unlocked IDs.
- **`*_gotten_incorrectly`** collections are keyed by `questionId` (global counters, not per-user).
- **Non-DB data**: `LevelSystem` (derived from `score`), `ShopItem` (static store items), `AvatarOptions` (DiceBear traits), and `GuestUser`/`GuestProgress` (persisted locally via `SharedPreferences`).
