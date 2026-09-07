# Entity Relationship Diagram

The diagram below reflects the persisted schema currently used by the application. Firestore subcollections are shown as entities with an explicit `userId` parent key for readability; in Firestore, that key is represented by the document path (`users/{uid}/...`).

```mermaid
erDiagram
    USER {
        string uid PK "Firebase Auth UID / document ID"
        string displayName
        string email
        boolean emailVerified
        int score
        int quizCoins
        int shieldCount
        int skipCount
        int pauseTimerCount
        int noDeductionsCount
        int computerArchitecturePoints
        int computerNetworkingPoints
        int softwareEngineeringPoints
        int caAnswered
        int caCorrect
        int cnAnswered
        int cnCorrect
        int seAnswered
        int seCorrect
        int questionsCorrect
        int questionsAnswered
        int streakNumber
        string[] badges "Badge IDs"
        string[] selectedBadges "Badge IDs, max 3"
        string avatarUrl
        map avatarDetails
        timestamp createdAt
    }

    PUBLIC_PROFILE {
        string uid PK "Same document ID as USER"
        string displayName
        int score
        int computerArchitecturePoints
        int computerNetworkingPoints
        int softwareEngineeringPoints
        int streakNumber
        string[] badges "Badge IDs"
        string[] selectedBadges "Badge IDs"
        string avatarUrl
        timestamp updatedAt
    }

    RANK_HISTORY_ENTRY {
        string entryId PK "Auto ID or guest_{sessionId}"
        string userId FK "Parent USER uid"
        string guestSessionId "Nullable; only migrated guest sessions"
        string rank
        string category
        float percentage
        timestamp timestamp
    }

    MIGRATION_EVENT {
        string eventId PK "purchase_{eventId}"
        string userId FK "Parent USER uid"
        string itemId
        int price
        timestamp timestamp
    }

    QUESTION {
        string questionId PK "Firestore document ID"
        string category PK "Collection/category namespace"
        string questionText
        string[] options
        string correctAnswer
        string explanation
    }

    INCORRECT_QUESTION_STATS {
        string questionId PK "Same ID as QUESTION"
        string category PK "Collection/category namespace"
        int number_of_wrong
    }

    GUEST_ACCOUNT {
        string id PK "Local UUID; not the Firebase uid"
        string username
        string displayName
        timestamp createdAt
        timestamp updatedAt
        string avatarUrl
        map avatarDetails
        int quizCoins
        int shieldCount
        int skipCount
        int pauseTimerCount
        int noDeductionsCount
        string[] badges "Badge IDs"
        string[] selectedBadges "Badge IDs"
        int schemaVersion
        string linkedUid "Nullable Firebase uid"
        boolean migrationCompleted
    }

    GUEST_SESSION {
        string sessionId PK
        string guestAccountId FK
        string challengeId
        string category
        int score
        int correctAnswers
        int totalQuestions
        timestamp playedAt
        boolean isTimed
        int coinsEarned
        int shieldChange
        int skipChange
        int pauseTimerChange
        int noDeductionsChange
        string rank
        float percentage
    }

    GUEST_PURCHASE {
        string eventId PK
        string guestAccountId FK
        string itemId
        int price
        timestamp timestamp
    }

    USER ||--|| PUBLIC_PROFILE : "projects to"
    USER ||--o{ RANK_HISTORY_ENTRY : "contains"
    USER ||--o{ MIGRATION_EVENT : "contains"
    QUESTION ||--o| INCORRECT_QUESTION_STATS : "has global stats"

    GUEST_ACCOUNT ||--o{ GUEST_SESSION : "embeds"
    GUEST_ACCOUNT ||--o{ GUEST_PURCHASE : "embeds"
    GUEST_ACCOUNT ||..o| USER : "links to Firebase uid"
    GUEST_SESSION ||..o| RANK_HISTORY_ENTRY : "migrates to"
    GUEST_PURCHASE ||..o| MIGRATION_EVENT : "migrates to"
```

## Storage Notes

- `USER`, `RANK_HISTORY_ENTRY`, and `MIGRATION_EVENT` are stored in Firestore under `users/{uid}` and its subcollections.
- `PUBLIC_PROFILE` is a denormalized, publicly readable projection of `USER`, not a second account.
- There are three separate `QUESTION` collections and three matching incorrect-question-stat collections, one pair per category. The `category` attribute above represents that collection namespace.
- `GUEST_ACCOUNT`, `GUEST_SESSION`, and `GUEST_PURCHASE` are local SharedPreferences JSON data. They are cleared after a successful merge into Firebase.
- Badge definitions, shop-item definitions, avatar options, levels, and offline question caches are static or derived data, so they are intentionally not modeled as persisted entities.