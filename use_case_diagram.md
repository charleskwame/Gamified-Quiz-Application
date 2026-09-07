# Gamified Quiz Application Use Case Flow

This flow reflects the implemented Flutter app. The app auto-detects sign-in,
creates a local guest profile when needed, shows onboarding on first launch,
then opens the dashboard. Guests and registered users share the same features;
progress goes to local storage for guests and Firestore for registered users.

## Use Case Flow

```mermaid
flowchart TD
    %% Styling
    classDef startEnd fill:#f96,stroke:#333,stroke-width:2px,rx:15,ry:15;
    classDef process fill:#9cf,stroke:#333,stroke-width:1.5px;
    classDef decision fill:#ff9,stroke:#333,stroke-width:1.5px;
    classDef cloud fill:#fdf,stroke:#333,stroke-width:1.5px;
    classDef storage fill:#dfd,stroke:#333,stroke-width:1.5px;

    Start([Open App]):::startEnd

    Start --> AuthCheck{Signed in?}:::decision
    AuthCheck -- No --> GuestExists{Local guest profile?}:::decision
    GuestExists -- No --> CreateGuest[Create local guest profile]:::process
    CreateGuest --> Local[(Local storage)]:::storage
    GuestExists -- Yes --> OnboardingCheck
    CreateGuest --> OnboardingCheck
    AuthCheck -- Yes --> OnboardingCheck{First launch?}:::decision

    OnboardingCheck -- Yes --> PlayTour[Play onboarding tour]:::process
    PlayTour --> MarkOnboarding[Mark tour completed]:::process
    MarkOnboarding --> Dashboard
    OnboardingCheck -- No --> Dashboard[Open dashboard]:::cloud

    Dashboard -. once on open .-> CheckUpdate{Update available?}:::decision
    CheckUpdate -- Yes --> DownloadUpdate[Download and install update]:::process
    DownloadUpdate --> Restart([Restart app]):::startEnd
    CheckUpdate -- No --> Dashboard

    %% Quiz flow
    Dashboard --> SelectSubject[Select subject]:::process
    SelectSubject --> SelectMode{Choose mode}:::decision
    SelectMode -- Normal --> PlayQuiz[Answer questions]:::process
    SelectMode -- Timed --> PlayQuiz
    SelectMode -- Offline --> PlayQuiz
    PlayQuiz --> UsePowerup{Use power-up?}:::decision
    UsePowerup -- Yes --> ApplyPowerup[Apply shield, skip, pause, or no-deductions]:::process
    ApplyPowerup --> PlayQuiz
    UsePowerup -- No --> NextQuestion{More questions?}:::decision
    NextQuestion -- Yes --> PlayQuiz
    NextQuestion -- No --> SaveResults{Registered user?}:::decision

    SaveResults -- Guest --> SaveLocal[Update local progress, coins, badges]:::process
    SaveLocal --> Local
    SaveResults -- Registered --> SaveCloud[Update Firestore: score, coins, badges, rank history]:::process
    SaveCloud --> Cloud[(Firestore)]:::storage
    SaveLocal --> ShowSummary
    SaveCloud --> ShowSummary[Show results summary]:::process

    ShowSummary --> LevelUp{Leveled up?}:::decision
    LevelUp -- Yes --> Celebrate[Show level-up celebration]:::process
    LevelUp -- No --> AICheck
    Celebrate --> AICheck{Open AI review?}:::decision
    AICheck -- Yes --> AIReview[Stream AI session review via DeepSeek]:::process
    AICheck -- No --> Dashboard
    AIReview --> Dashboard

    %% Shop
    Dashboard --> Shop[Browse shop power-ups]:::process
    Shop --> BuyItem{Afford item?}:::decision
    BuyItem -- Yes --> AddItem[Spend coins and add to inventory]:::process
    AddItem -- Guest --> Local
    AddItem -- Registered --> Cloud
    AddItem --> Shop
    BuyItem -- No --> Shop

    %% Profile
    Dashboard --> ProfileHub[Open profile]:::process
    ProfileHub --> CustomizeAvatar[Customize avatar]:::process
    ProfileHub --> ViewBadges[View and equip badges]:::process
    ProfileHub --> ViewAnalytics[View analytics and rank history]:::process
    CustomizeAvatar -- Guest --> Local
    CustomizeAvatar -- Registered --> Cloud

    %% Rankings
    Dashboard --> Rankings[View leaderboard rankings]:::process
    Rankings -. reads .-> Cloud

    %% Settings
    Dashboard --> Settings[Configure settings]:::process

    %% Account actions
    Dashboard -. guest .-> SignIn[Sign in with Google]:::process
    SignIn --> Migrate[Merge guest progress into account]:::process
    Migrate -. writes .-> Cloud
    Migrate -. clears .-> Local
    Migrate --> Dashboard

    Dashboard -. registered .-> BugReport[Submit bug report]:::process
    Dashboard -. registered .-> Evaluation[Complete evaluation survey]:::process
    BugReport -. writes .-> Cloud
    Evaluation -. writes .-> Cloud

    Dashboard -. registered .-> LogOut[Log out]:::process
    LogOut --> Start
```

## Relationship Notes

- Update checking runs once when the dashboard opens; onboarding plays only on
    the first launch, for both guests and registered users.
- Quiz: select a subject, choose normal, timed, or offline mode, answer
    questions with optional power-ups, then finish. Offline mode always saves
    progress locally.
- Results branch by user: guests update local storage; registered users update
    Firestore (score, coins, badges, and rank history), with an optional
    level-up celebration and AI session review.
- Shop, avatar, badges, analytics, and rankings are shared features. Purchases
    and avatar edits persist locally for guests and in Firestore for registered
    users; rankings read public Firestore data.
- Signing in with Google merges local guest progress into Firestore and clears
    the local copy. Bug reports and evaluation surveys are registered-only, and
    logging out returns to the sign-in check.