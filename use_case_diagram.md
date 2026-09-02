Here is a simplified list of all actions (use cases) that **Guest Users** and **Registered Users** can perform in the application, which you can use to design your diagram:

---

### 1. Shared Core Actions (Both Guest and Registered Users)
*   **Onboarding**: Run the initial onboarding app tour.
*   **Set Profile Name**: Choose/edit a display name.
*   **Configure Application Settings**: Toggle audio (background music, sound effects) and app themes.
*   **Check for App Updates**: Check the current app version against GitHub to trigger downloads.
*   **Select Quiz Subject**: Choose between Computer Architecture, Computer Networking, or Software Engineering.
*   **Choose Challenge Mode**: Toggle between timed and untimed quiz formats.
*   **Play Quiz Session**: Answer multiple-choice questions sequentially.

---

### 2. Actions Exclusive to Guest Users
*   **Create Local Profile**: Set up local-only guest progress saved to device storage.
*   **Migrate Account**: Register or log in to a cloud account to transfer local guest progress, stats, and coins to Firestore.

---

### 3. Actions Exclusive to Registered Users (Cloud-Synced Features)
*   **Customize Avatar Details**: Choose visual attributes (hair, eyes, clothing, skin color) for their user avatar.
*   **Earn & Track Progression**: Accumulate experience points, level up, and maintain daily play streaks.
*   **Earn QuizCoins**: Receive in-game currency by correctly answering questions and completing streaks.
*   **Browse & Purchase Items**: Spend QuizCoins in the shop to purchase power-ups (Shields, Skips, Pause Timers, No Deductions).
*   **Activate Power-up**: Apply purchased items during a quiz session to skip questions or prevent point deductions.
*   **Consult AI Assistant**: Stream real-time natural language explanations for quiz questions using the DeepSeek-powered chat interface.
*   **Unlock & Equip Badges**: Earn achievements based on milestone targets and select which badges to display on their public profile.
*   **View Personal Analytics**: Review historical performance charts, correct/incorrect ratios, and detailed category points.
*   **View Leaderboards**: Browse the global user rankings sorted by total score or specific categories.
*   **Submit Bug Reports**: Submit issues and logs directly to the Firestore backend.
*   **Complete Evaluation Survey**: Answer the 20 quality assessment questions to review the app's performance.