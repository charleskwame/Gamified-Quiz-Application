# Application Process Flowchart

This document details the user journeys and internal decision logic for the **Gamified Quiz Application**. It maps out application startup updates, authentication decisions, guest gameplay, and the full interactive online/offline quiz loop.

---

## Process Flowchart

```mermaid
%%{init: {'flowchart': {'curve': 'linear'}}}%%
flowchart TD
    %% Styling
    classDef startEnd fill:#ffebe6,stroke:#ff5630,stroke-width:2px,rx:8,ry:8;
    classDef process fill:#deebff,stroke:#0747a6,stroke-width:1.5px,rx:4,ry:4;
    classDef decision fill:#fffae6,stroke:#ff8f00,stroke-width:1.5px;
    classDef database fill:#eae6ff,stroke:#403294,stroke-width:1.5px,rx:4,ry:4;

    subgraph Startup ["1. Startup & Verification"]
        Start([Start App]):::startEnd
        CheckUpdate{Check GitHub Updates}:::decision
        DownloadUpdate[Download & Install Update APK]:::process
        Terminate([Restart App]):::startEnd
        CheckOnboarding{Onboarding Tour Done?}:::decision
        PlayTour[Play Onboarding Tour]:::process
        SaveOnboardingFlag[Save Onboarding Flag]:::process
        
        Start --> CheckUpdate
        CheckUpdate -- Update Found --> DownloadUpdate --> Terminate
        CheckUpdate -- Up to Date --> CheckOnboarding
        CheckOnboarding -- No --> PlayTour --> SaveOnboardingFlag
    end

    subgraph AccessControl ["2. Authentication & Profile Selection"]
        AuthSelection{Login Status}:::decision
        RunAuth[Auth Screen: Register or Login]:::process
        SyncProgress[Sync Guest Progress to Firestore]:::process
        AuthenticatedHome[Home Screen: Authenticated User]:::database
        GuestHome[Home Screen: Guest User]:::process
        
        CheckOnboarding -- Yes --> AuthSelection
        SaveOnboardingFlag --> AuthSelection
        
        AuthSelection -- Logged In --> AuthenticatedHome
        AuthSelection -- Guest Mode --> GuestHome
        AuthSelection -- Register/Login --> RunAuth --> SyncProgress --> AuthenticatedHome
    end

    subgraph OfflinePlay ["3. Guest Offline Gameplay"]
        SelectLocalQuiz[Select Subject Category]:::process
        PlayLocalQuiz[Play Offline Quiz: Local Questions]:::process
        TallyLocal[Tally Score & Update Local Cache]:::process
        UpgradeAccount{Upgrade Account?}:::decision
        
        GuestHome --> SelectLocalQuiz --> PlayLocalQuiz --> TallyLocal --> GuestHome
        GuestHome --> UpgradeAccount
        UpgradeAccount -- Yes --> RunAuth
        UpgradeAccount -- No --> GuestHome
    end

    subgraph OnlinePlay ["4. Authenticated Gameplay & AI Summary"]
        SelectSubject[Select Subject Category]:::process
        SelectMode{Select Quiz Mode}:::decision
        PlayTimed[Play Quiz with Timer Countdown]:::process
        PlayUntimed[Play Quiz: No Timer Constraints]:::process
        GameplayLoop[Question Displayed]:::process
        
        UsePowerup{Activate Power-up?}:::decision
        ApplyPowerup[Apply Shield/Skip/Pause/No Deductions]:::process
        SubmitAnswer[Submit Answer]:::process
        NextQuestion{More Questions?}:::decision
        
        SaveResults[Save RankHistory & Update Profiles]:::process
        EarnCoins[Award QuizCoins & Exp]:::process
        CheckBadges{Unlock New Badges?}:::decision
        AwardBadge[Award Achievement Badge]:::process
        UpdateFirestore[Sync to Cloud Database]:::database
        
        ShowSummary[Show Summary Screen & Results]:::process
        ClickAIIcon{Click AI Feedback Icon?}:::decision
        CallAI[Stream Session Feedback via DeepSeek]:::process
        ReturnHome[Return to Home Screen]:::process

        AuthenticatedHome --> SelectSubject --> SelectMode
        SelectMode -- Timed --> PlayTimed --> GameplayLoop
        SelectMode -- Untimed --> PlayUntimed --> GameplayLoop
        
        GameplayLoop --> UsePowerup
        UsePowerup -- Yes --> ApplyPowerup --> SubmitAnswer
        UsePowerup -- No --> SubmitAnswer
        
        SubmitAnswer --> NextQuestion
        NextQuestion -- Yes --> GameplayLoop
        
        NextQuestion -- No --> SaveResults --> EarnCoins --> CheckBadges
        CheckBadges -- Yes --> AwardBadge --> UpdateFirestore
        CheckBadges -- No --> UpdateFirestore
        
        UpdateFirestore --> ShowSummary --> ClickAIIcon
        ClickAIIcon -- Yes --> CallAI --> ReturnHome
        ClickAIIcon -- No --> ReturnHome --> AuthenticatedHome
    end

    subgraph UserConfig ["5. Profile & Inventory Operations"]
        BrowseShop[Browse Shop Inventory]:::process
        BuyItem{Afford Price?}:::decision
        DeductCoins[Deduct QuizCoins & Add to Inventory]:::process
        
        CustomizeAvatar[Customize Visual Avatar Features]:::process
        UpdateProfile[Save Avatar Config to Firestore]:::database
        
        ViewRankings[View Leaderboard Rankings]:::process

        AuthenticatedHome --> BrowseShop --> BuyItem
        BuyItem -- Yes --> DeductCoins --> AuthenticatedHome
        BuyItem -- No --> AuthenticatedHome
        
        AuthenticatedHome --> CustomizeAvatar --> UpdateProfile --> AuthenticatedHome
        AuthenticatedHome --> ViewRankings --> AuthenticatedHome
    end
```
