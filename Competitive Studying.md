# Study Forces
An app that gamifies studying by letting you set a rating system for each subject and track your progress.

---
## Core Idea
- Each subject has a **rating**: from a base (minimum) to a max (goal).
- Max rating represents “ideal performance” (e.g., solving problems at ~2 minutes/problem with 98% accuracy).
- To progress, you log study sessions or problem-solving sessions.  
- If you don’t log within the required frequency, your rating decreases.  
- Ranks (colorful, customizable roles) are unlocked at rating thresholds.  

---

## How it works
1. Add a subject with its configuration (base rating, max rating, goals).
2. Choose whether the subject has:
   - **Study sessions** (measured in user-chosen **units**, e.g. “pages” or “minutes”).
   - **Problem-solving sessions** (measured by number of problems solved, time taken, and accuracy).  
   At least one must be enabled.
3. Log sessions:
   - **Study** → enter how many units you studied.  
   - **Problems** → enter number solved, time taken, correctness.  
4. At the end of each **frequency window** (e.g., every 3 days), the app evaluates your performance and updates your rating.  
---

## Scoring system
### Study sessions
- User defines a **unit** (pages, chapters, minutes, etc.).  
- Performance for one frequency window:  

$$
\text{Performance} = \frac{\text{units logged}}{\text{units goal}} \times R_\text{max}
$$

---

### Problem-solving sessions
Factors:
- Amount of problems solved  
- Average time per problem  
- Accuracy  

Performance:  

$$
\text{Performance} = 
\frac{P_t}{P_g} \times \frac{t_{avg}}{t_\text{g}} \times \frac{P_c}{P_t} \times R_\text{max}
$$

Where:
- $P_t$ = problems attempted  
- $P_g$ = goal problems (for the frequency)  
- $t_g$ = expected time per problem (goal)  
- $t_\text{avg}$ = actual average time per problem  
- $P_c$ = problems correct  

---

## Rating change
At the end of each **frequency window**:
$$
\Delta R = \frac{R_\text{performance} - R_\text{current}}{C_f}
$$

- $C_f$ = constant for the frequency (scales how fast rating changes).  
- Positive if performance > current rating, negative if performance < current rating.  

---

## Final Rating Change formulas
### Rating changes with an ongoing streak
**Positive change:**
$$
\text{Rating Change}=\triangle R \times S_{m+}
$$
**Negative change**:

$$
\text{Rating Change}=\frac{\triangle R}{S_{m+}}
$$

### No-streak rate-loss
**First hit:**
$$
\triangle R = \frac{S_{m+} \times R_\text{current}}{125}
$$
After the first hit, $S_{m+}$ will be reset and no longer will be used to infect rating losses, however, a new variable, $S_{m-}$ will take control, which is defined by the formula:
$$
S_{m-}=\frac{\log_{10}\left(1+\text{days without streak}\right)}{3}
$$
It grows daily, regardless of what the frequency of the goal is, that is because every day without a streak is a chance you've missed to revive your streak.
Change for next hits will be calculated using this formula:
$$
\triangle R = R_\text{current}\times(100-S_{m-})
$$
So everyday, you'd lose \%$S_{m-}$ of your rating, until you revive your streak.

---
# DS Planning

## Rank()
### Properties
- Id: (`int`)
- RequiredRating: (`int`) rating required to gain that rank
- Name: (`string`) name of the rank
- Description: (`string`) description of the rank
- Color: (`string`) a hex color for the rank's color
- Glow: (`boolean`) whether the rank glows or not

### Methods
- None

---

## ProblemSession()
### Properties
- Id: (`int`)
- when: (`DateTime`) when the session took place
- ProblemsAttempted: (`int`) total number of problems attempted
- ProblemsCorrect: (`int`) number of problems correctly solved
- DurationSeconds: (`int`) total duration of the session, the UI would allow for you to easily write it out, then it'll get converted to seconds.
- Applied: (`boolean`) whether this session has already been applied in rating calculations

### Methods
- None (session data is stored and later processed by Subject)

---

## StudySession()
### Properties
- Id: (`int`)
- when: (`DateTime`) when the session took place
- Units: (`double`) number of units studied (unit meaning is defined in Subject)
- Applied: (`boolean`) whether this session has already been applied in rating calculations

### Methods
- None (session data is stored and later processed by Subject)

---
## RatingLog()
### Properties 
- when: (`DateTime`) the day when the rating reaches Rating
- Rating: (`int`) the rating at that time 
### Methods
None

---
## Subject()
### Properties
- Id: (`int`)
- Name: (`string`) name of the subject
- Description: (`string`) description of the subject
- BaseRating: (`int`) starting rating
- MaxRating: (`int`) max/goal rating
- StudyEnabled: (`boolean`) whether study sessions are enabled
- ProblemEnabled: (`boolean`) whether problem-solving sessions are enabled
#### Study specific properties
- UnitName: (`string`) name of the unit used for study sessions (e.g. “pages” or “minutes”)
- StudyFrequency: (`int`) how often do you have to reach your minimum goal to keep a streak, also how often rating changes will apply, this is in days.
- StudyGoalMin: (`int`) minimum study units required per frequency
- StudyGoalMax: (`int`) maximum study units per frequency, if you achieve it, you're performing at max rating.
- StudyStreak: (`int`) positive if the streak is positive, and negative otherwise.
- StudyRating: (`int`) current rating for studying
- LastProcessedStudy: (`DateTime`) last time rating changes for study sessions were processed.
- StudyRatingConstant: (double) an integer >= 1, that is used in rating formulas.
#### Problem solving specific properties
- ProblemGoalMin: (`int`) minimum amount of problems required to maintain a streak.
- ProblemGoalMax: (`int`) the amount of problems that if reached, you'd be performing at max rating
- ProblemFrequency: (`int`) how often do you have to reach your minimum goal to keep a streak, also how often rating changes will apply, this is in days.
- ProblemStreak: similar to study one.
- ProblemTimeGoal: (`int`) time in seconds required for each problem as a goal.
- ProblemRating: (`int`) rating for solving problems
- LastProcessedProblems: (`DateTime`) last time problem sessions were processed.
- ProblemRatingConstant: (double) an integer >= 1, that is used in rating formulas.

- Ranks: (`list<Rank>`) list of ranks available for this subject

- StudySessions: (`list<StudySession>`) all study sessions for this subject
- ProblemSessions: (`list<ProblemSession>`) all problem-solving sessions for this subject
- StudyRatingHistory (``list<RatingLog>``)
- ProblemRatingHistory (`list<RatingLog>`) 
All of these lists have to be sorted all the time.

### Methods
- `addStudySession(StudySession session)`: adds a study session
- `addProblemSession(ProblemSession session)`: adds a problem-solving session
- `deleteStudySession(int id)`: deletes the study session with the given Id, and reprocesses ratings after it.
- `deleteProblemSession(int id)`: deletes the problem session with the given Id, and reprocesses ratings after it.
- `GetStudyPerformance, GetProblemPerformance`: Calculates performance since last rating update until now
- `GetStreakMultiplier(int streak)`: calculates positive or negative streak multiplier.
Rating calculation functions:
- `applyStudyRateChanges(DateTime asOf)`: recalculates unprocessed study rating changes.
- `applyProblemRateChanges(DateTime asOf)`: recalculates unprocessed problem-solving rating changes
- `resetAndRecalculateProblem()`, `resetAndRecalculateStudy()`: Recalculates ratings from the beginning, resets history and sets it back, resets streaks and sets it back.
All of these functions do something if there's a new frequency-sized chunk to be processed, except for the `resetAndRecalculate`- pair.
They all add rating changes to RatingHistory. 
They all calculate negative streaks and streaks multipliers.