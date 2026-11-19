# Personal Life OS — Redesign Brief v3
## Final design decisions
- **PC:** Balanced density — comfortable spacing and enough information per screen, without feeling empty or crowded.
- **HP:** Keep the previous mobile layout/concept, including the familiar stacked cards and bottom navigation.
- **Charts:** Optional. Users can show or hide charts; summary figures and transaction/activity history remain accessible either way.
- **Color:** White background and white cards; pink buttons, active states, highlights, and interaction accents.
- **Navigation:** Sidebar on PC; bottom navigation on mobile.
- **Dashboard:** Fully customizable from the dashboard itself. Users can reorder, show/hide, resize, and add dashboard widgets without visiting Settings.
- **Quick add:** Floating + action may remain as a shortcut, but it must not be the only way to create or edit records.

## Core interaction principle
Each category is a complete workspace. Opening a category should show its primary input/edit controls, current data, history, and its own report in one coherent page. Users should not have to use Quick Add or Settings for routine data entry.

## Page-by-page scope
### 1. Home / Dashboard
- PC: left sidebar, compact header, customizable widget grid with balanced spacing.
- HP: preserve previous mobile concept; vertically stacked modules and bottom navigation.
- Widgets: category shortcuts, today's tasks, calendar/agenda, finance snapshot, mood check-in, recent activity, progress.
- Edit dashboard directly: reorder, resize, add, hide, and restore widgets inline.

### 2. Productivity
- Task list with checkboxes, priority, due date, and inline editing.
- Calendar views; daily routines grouped by morning/afternoon/evening.
- Project tracker, backlog/someday list, Pomodoro.
- Reward/achievement progress.
- Report area: completion summary, routine consistency, project progress, weekly/monthly review.
- Charts are optional and can be hidden independently from the underlying data.

### 3. Finance
- Envelope budgeting with editable allocations.
- Inline income/expense entry and editing.
- Transaction history with search/filter and edit/delete.
- Savings goals, recurring bills, debts/installments.
- Monthly report: income, expenses, budget remaining, category breakdown, savings progress.
- Keep the form and history on the Finance page; Quick Add is only a shortcut.

### 4. Health
- Weight and target-weight tracker.
- Food diary and calorie estimates.
- Water intake tracker.
- Workout log and activity history.
- Body measurements.
- Progress summary; charts optional.

### 5. Wellness
- Mood, energy, stress, and sleep check-ins.
- Daily journal, gratitude journal, emotional trigger notes.
- Weekly mental-health reflection.
- Gentle summaries; no automated diagnosis or judgment.

### 6. Menstrual
- Calendar for period start/end and cycle history.
- Symptoms and mood notes by date.
- Estimated next period and cycle-length history.
- Reminders are configurable; predictions clearly labeled as estimates, not medical certainty.

### 7. Notes & Journal
- Quick notes, daily journal, brain dump, gratitude journal.
- Tags, categories, search, pinned notes.
- PC: list/editor split view.
- HP: notes list and editor as simple mobile screens.

### 8. Rewards
- Points balance, reward catalog, redemption progress.
- Achievements and redemption history.
- Missed days do not subtract points.

### 9. Settings
- App-level preferences, theme/accent, sync, backup, export, privacy.
- Do not place everyday category editing here.

## Visual system
- Background: `#FFFFFF`
- Card: `#FFFFFF`
- Primary pink: `#ED9FBD`
- Pink highlight: `#FFF0F5`
- Text: `#493640`
- Muted text: `#A18C96`
- Border: `#F2E5EB`
- Use subtle borders and minimal shadows. Avoid decorative clutter and oversized charts.

## Responsive behavior
- Desktop: sidebar + main content; balanced 3-column category shortcuts and flexible content grids.
- Mobile: preserve previous mobile layout, stacked content, readable touch targets, fixed bottom navigation with safe-area padding.
- Tablet: collapse grids progressively; do not force desktop's dense layout onto narrow screens.

## Data and synchronization requirements
- Audit existing V0.2.0 code and schema before implementation.
- Back up current data before migrations.
- Cloud database should be the shared source of truth for PC and mobile.
- Two-way sync, offline entry with later sync, sync status, conflict handling, automatic backup, restore, authentication, and access rules.
- Do not rely on LAN discovery or same-network connectivity for cross-device sync.
- Preserve existing DailyChecklist tasks, reward points, history, and settings during migration.

## Implementation notes
- This HTML is a visual/navigation prototype, not production software.
- Demo form actions are not connected to a persistent database.
- Developer should inspect the existing stack and choose the least disruptive implementation path.
- Build in phases, but keep the full module scope in the product plan.
