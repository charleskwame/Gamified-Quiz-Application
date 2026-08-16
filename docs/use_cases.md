# Gamified Quiz App — Use Case Diagrams

> Generated from `lib/screens/`, `lib/widgets/`, and `lib/services/`.
> Sources: `docs/use_case_*.mmd` (renderable via the Mermaid extension / `mermaid-cli`).

## Actors

| Actor                           | Description                                                                                                                         |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Guest User**                  | Plays quizzes without an account. Progress (score, streaks, badges-free stats) is stored **locally** on the device.                 |
| **Registered User**             | Signed in with email/password and verified email. Can sync guest progress, earn/persist badges & coins, access shop, rankings, etc. |
| **Firebase Authentication**     | External identity system (sign-up, sign-in, email verification, session restore).                                                   |
| **Cloud Firestore**             | External data store for user profiles, stats, rankings, quiz questions, and power-up inventory.                                     |
| **DeepSeek AI Study Assistant** | External AI service providing real-time study tips and chat during/after quizzes.                                                   |
| **Bug Report Service**          | Google Apps Script web app that appends bug reports to a Google Sheet.                                                              |
| **GitHub Releases**             | External update server hosting signed APK/AAB releases.                                                                             |

> **Generalization:** _Registered User_ —|> _Guest User_ (a registered user can do everything a guest can, plus account-based features).

---

## 1. Overall System Context

```mermaid
flowchart LR
    classDef actor fill:#003F91,stroke:#111C4A,color:#ffffff,font-weight:700;
    classDef system fill:#ECF8F8,stroke:#003F91,color:#111C4A,font-weight:600;
    classDef uc fill:#ffffff,stroke:#003F91,color:#111C4A;

    GU["👤 Guest User"]:::actor
    RU["👤 Registered User"]:::actor
    RU --|> GU

    subgraph APP[Gamified Quiz Application]
        direction LR
        UC_AUTH(("Auth &<br/>Account"))
        UC_QUIZ(("Quiz<br/>Gameplay"))
        UC_GAM(("Gamification<br/>& Social"))
        UC_SUP(("System &<br/>Support"))
    end

    GU --> UC_QUIZ
    GU --> UC_GAM
    GU --> UC_SUP
    RU --> UC_AUTH
    RU --> UC_QUIZ
    RU --> UC_GAM
    RU --> UC_SUP

    FA["Firebase Authentication"]:::system
    FS["Cloud Firestore"]:::system
    AI["DeepSeek AI<br/>Study Assistant"]:::system
    BR["Bug Report Service<br/>(Google Sheets)"]:::system
    GH["GitHub Releases<br/>(Update Server)"]:::system

    FA -.-> UC_AUTH
    FS -.-> UC_AUTH
    FS -.-> UC_QUIZ
    AI -.-> UC_QUIZ
    FS -.-> UC_GAM
    BR -.-> UC_SUP
    GH -.-> UC_SUP
```

Source: `docs/use_case_overall.mmd`

---

## 2. Authentication & Account Management

```mermaid
flowchart TB
    classDef actor fill:#003F91,stroke:#111C4A,color:#ffffff,font-weight:700;
    classDef system fill:#ECF8F8,stroke:#003F91,color:#111C4A,font-weight:600;
    classDef uc fill:#ffffff,stroke:#003F91,color:#111C4A;
    classDef inc fill:#fff7e6,stroke:#F59E0B,color:#111C4A;

    GU["👤 Guest User"]:::actor
    RU["👤 Registered User"]:::actor
    FA["Firebase Authentication"]:::system
    FS["Cloud Firestore"]:::system

    subgraph System[Account Management]
        GUNAME(("Enter Guest Name"))
        TOUR(("View Onboarding Tour"))
        SIGNUP(("Sign Up"))
        LOGIN(("Log In"))
        LOGOUT(("Log Out"))
        VERIFY(("Verify Email"))
        RESEND(("Resend Verification"))
        SYNC(("Sync Guest Progress<br/>to Account"))
        PROFILE(("Update Account Info"))
        AVATAR(("Customize Avatar"))
        DELETE(("Delete Account"))
        REAUTH(("Reauthenticate<br/>with Password"))
        RESTORE(("Restore Session"))
    end

    GU --> GUNAME
    GU --> TOUR
    RU --> TOUR
    RU --> SIGNUP
    RU --> LOGIN
    RU --> LOGOUT
    RU --> VERIFY
    RU --> PROFILE
    RU --> AVATAR
    RU --> DELETE

    LOGIN -- includes --> VERIFY
    SIGNUP -- includes --> VERIFY
    SIGNUP -- includes --> SYNC
    VERIFY -- includes --> RESEND
    DELETE -- includes --> REAUTH
    RESTORE -. silent restore .-> LOGIN

    FA -.-> SIGNUP
    FA -.-> LOGIN
    FA -.-> VERIFY
    FA -.-> PROFILE
    FA -.-> DELETE
    FS -.-> SYNC
    FS -.-> PROFILE
```

Source: `docs/use_case_auth.mmd`

---

## 3. Quiz Gameplay

```mermaid
flowchart TB
    classDef actor fill:#003F91,stroke:#111C4A,color:#ffffff,font-weight:700;
    classDef system fill:#ECF8F8,stroke:#003F91,color:#111C4A,font-weight:600;
    classDef uc fill:#ffffff,stroke:#003F91,color:#111C4A;
    classDef inc fill:#fff7e6,stroke:#F59E0B,color:#111C4A;

    GU["👤 Guest User"]:::actor
    RU["👤 Registered User"]:::actor
    AI["DeepSeek AI<br/>Study Assistant"]:::system
    FS["Cloud Firestore"]:::system

    subgraph Quiz[Quiz Gameplay]
        SELECT(("Select Quest<br/>Category"))
        MODE(("Choose Mode<br/>Normal / Timed / Offline"))
        PLAY(("Play Quiz"))
        ANSWER(("Answer Question"))
        POWER(("Use Power-Up"))
        SHIELD(("Shield"))
        SKIP(("Skip Question"))
        NODED(("No Deductions"))
        PAUSE(("Pause Timer"))
        AICHAT(("AI Study Assistant"))
        DOWNLOAD(("Download Questions<br/>for Offline"))
        RESULTS(("View Results &<br/>Review Incorrect"))
        REWARDS(("Earn Coins, XP<br/>& Streaks"))
        LEVELUP(("Level Up"))
        BADGE(("Unlock Badge"))
    end

    GU --> SELECT
    RU --> SELECT
    GU --> DOWNLOAD
    RU --> DOWNLOAD
    GU --> RESULTS
    RU --> RESULTS
    GU --> AICHAT
    RU --> AICHAT

    SELECT -- includes --> MODE
    MODE -- extends --> PLAY
    PLAY -- includes --> ANSWER
    PLAY -- includes --> POWER
    PLAY -- includes --> AICHAT
    POWER -- includes --> SHIELD
    POWER -- includes --> SKIP
    POWER -- includes --> NODED
    POWER -- includes --> PAUSE
    DOWNLOAD -- extends --> MODE
    PLAY -- includes --> RESULTS
    RESULTS -- includes --> REWARDS
    REWARDS -- includes --> LEVELUP
    REWARDS -- includes --> BADGE

    AI -.-> AICHAT
    FS -.-> SELECT
    FS -.-> PLAY
    FS -.-> DOWNLOAD
```

Source: `docs/use_case_quiz.mmd`

---

## 4. Gamification & Social

```mermaid
flowchart TB
    classDef actor fill:#003F91,stroke:#111C4A,color:#ffffff,font-weight:700;
    classDef system fill:#ECF8F8,stroke:#003F91,color:#111C4A,font-weight:600;
    classDef uc fill:#ffffff,stroke:#003F91,color:#111C4A;
    classDef inc fill:#fff7e6,stroke:#F59E0B,color:#111C4A;

    GU["👤 Guest User"]:::actor
    RU["👤 Registered User"]:::actor
    FS["Cloud Firestore"]:::system

    subgraph Gamification[Gamification & Social]
        PROFILE(("View Profile"))
        BADGES(("View Badges<br/>Earned / All"))
        SELECTB(("Select Badges<br/>to Display"))
        ANALYTICS(("View Analytics"))
        RANKS(("View Leaderboard<br/>Rankings"))
        FILTER(("Filter by Category<br/>& Sort"))
        LEVELS(("View Levels /<br/>XP Vault"))
        STREAK(("View Streak Card"))
        SHOP(("Visit Shop"))
        PURCHASE(("Purchase Power-Up<br/>with Coins"))
    end

    GU --> PROFILE
    RU --> PROFILE
    RU --> BADGES
    RU --> SELECTB
    GU --> ANALYTICS
    RU --> ANALYTICS
    GU --> RANKS
    RU --> RANKS
    GU --> LEVELS
    RU --> LEVELS
    GU --> STREAK
    RU --> STREAK
    RU --> SHOP

    PROFILE -- includes --> BADGES
    PROFILE -- includes --> SELECTB
    RANKS -- includes --> FILTER
    SHOP -- includes --> PURCHASE

    FS -.-> PROFILE
    FS -.-> RANKS
    FS -.-> SHOP
```

Source: `docs/use_case_gamification.mmd`

---

## 5. System & Support

```mermaid
flowchart TB
    classDef actor fill:#003F91,stroke:#111C4A,color:#ffffff,font-weight:700;
    classDef system fill:#ECF8F8,stroke:#003F91,color:#111C4A,font-weight:600;
    classDef uc fill:#ffffff,stroke:#003F91,color:#111C4A;

    GU["👤 Guest User"]:::actor
    RU["👤 Registered User"]:::actor
    GH["GitHub Releases<br/>(Update Server)"]:::system
    BR["Bug Report Service<br/>(Google Apps Script → Sheet)"]:::system

    subgraph Support[System & Support]
        CHECK(("Check for<br/>App Update"))
        UPDATE_DL(("Download &<br/>Install Update"))
        BUG(("Submit<br/>Bug Report"))
    end

    GU --> CHECK
    RU --> CHECK
    GU --> BUG
    RU --> BUG

    CHECK -- includes --> UPDATE_DL

    GH -.-> CHECK
    GH -.-> UPDATE_DL
    BR -.-> BUG
```

Source: `docs/use_case_support.mmd`

---

## Use Case Catalog

| #   | Use Case                                                   | Primary Actor    | System Support             | Includes / Extends                                          |
| --- | ---------------------------------------------------------- | ---------------- | -------------------------- | ----------------------------------------------------------- |
| 1   | Enter Guest Name                                           | Guest User       | Local storage              | —                                                           |
| 2   | View Onboarding Tour                                       | Guest/Registered | Local storage              | —                                                           |
| 3   | Sign Up                                                    | Registered User  | Firebase Auth, Firestore   | includes: Verify Email, Sync Guest Progress                 |
| 4   | Log In                                                     | Registered User  | Firebase Auth              | includes: Verify Email                                      |
| 5   | Log Out                                                    | Registered User  | Firebase Auth              | —                                                           |
| 6   | Verify Email                                               | Registered User  | Firebase Auth              | includes: Resend Verification                               |
| 7   | Restore Session                                            | Registered User  | Firebase Auth              | silent restore of previous login                            |
| 8   | Update Account Info                                        | Registered User  | Firebase Auth, Firestore   | —                                                           |
| 9   | Customize Avatar                                           | Registered User  | Firestore                  | —                                                           |
| 10  | Delete Account                                             | Registered User  | Firebase Auth, Firestore   | includes: Reauthenticate with Password                      |
| 11  | Select Quest Category                                      | Guest/Registered | Firestore                  | —                                                           |
| 12  | Choose Quiz Mode                                           | Guest/Registered | —                          | extends: Play Quiz                                          |
| 13  | Play Quiz                                                  | Guest/Registered | Firestore                  | includes: Answer Question, Use Power-Up, AI Study Assistant |
| 14  | Use Power-Up (Shield / Skip / No Deductions / Pause Timer) | Registered User  | Firestore                  | included in Play Quiz                                       |
| 15  | AI Study Assistant                                         | Guest/Registered | DeepSeek AI                | included in Play Quiz                                       |
| 16  | Download Questions for Offline                             | Guest/Registered | Firestore → local          | extends: Play Offline                                       |
| 17  | View Results & Review Incorrect                            | Guest/Registered | Firestore / local          | included in Play Quiz                                       |
| 18  | Earn Coins, XP & Streaks                                   | Guest/Registered | Firestore / local          | included in Results                                         |
| 19  | Level Up                                                   | Guest/Registered | —                          | included in Rewards                                         |
| 20  | Unlock Badge                                               | Guest/Registered | Firestore / local          | included in Rewards                                         |
| 21  | View Profile                                               | Guest/Registered | Firestore / local          | —                                                           |
| 22  | View Badges (Earned / All)                                 | Registered User  | Firestore                  | included in Profile                                         |
| 23  | Select Badges to Display                                   | Registered User  | Firestore                  | included in Profile                                         |
| 24  | View Analytics                                             | Guest/Registered | Firestore / local          | —                                                           |
| 25  | View Leaderboard / Rankings                                | Guest/Registered | Firestore                  | includes: Filter by Category & Sort                         |
| 26  | View Levels / XP Vault                                     | Guest/Registered | Firestore / local          | —                                                           |
| 27  | View Streak Card                                           | Guest/Registered | Firestore / local          | —                                                           |
| 28  | Visit Shop & Purchase Power-Up                             | Registered User  | Firestore                  | includes: Purchase with Coins                               |
| 29  | Check for App Update                                       | Guest/Registered | GitHub Releases            | includes: Download & Install                                |
| 30  | Submit Bug Report                                          | Guest/Registered | Google Apps Script → Sheet | —                                                           |
