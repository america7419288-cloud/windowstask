# Taski 🎨

**The most aesthetic, sticker-driven task manager for Windows & Web.**

Taski isn't just a to-do list; it's a visual sanctuary for your productivity. Built with the "Sticker-Hero" philosophy, Taski turns your mundane tasks into a vibrant, animated workspace.

---

## 🚀 Key Features

### 1. Sticker-Hero Task Cards 🃏
We've redesigned the core task experience. Pick from **4 unique layouts** to suit your style:
- **Grid View**: A beautiful, cover-based grid with priority-tinted overlays.
- **Kanban Board**: Drag-and-drop columns with status-tinted borders and real-time count badges.
- **Compact List**: Perfect for high-density lists with intuitive sticker-to-checkbox toggles.
- **Magazine View**: A luxurious, spacious view for your most important projects, featuring high-res hero stickers and 2-column subtask grids.

### 2. Smart Natural Language Quick Add 🪄
Stop filling out forms. Just type:
> "Grocery shopping every Monday at 6pm !high"

Taski's **NlpParser** automatically extracts the due date, recurrence, and priority in real-time.

### 3. Deep Focus Mode 🧘‍♂️
Level up your concentration:
- **Session Goals**: Pick tasks to tackle before you start the clock.
- **Break Mode**: Rewarding break screens with lottie animations and motivational quotes.
- **Weekly Insights**: Track your focus patterns with premium charts.

### 4. Daily Planning Mode ☀️
Start every day with intention. The **Daily Planning Wizard** helps you pick yesterday's leftovers and set your **MITs (Most Important Tasks)** for today.

### 5. Bulk Actions & Multi-selection ⚡
Manage your clutter instantly. Hold `Shift` or `Ctrl` to select multiple tasks and perform bulk deletes, rescheduling, or priority changes.

### 6. Recurring Tasks & Smart Reminders 🔔
Set complex recurrence rules (Daily, Weekly, Monthly) and receive native Windows Toast notifications so you never miss a beat.

---

## ✨ Design Philosophy & UI

- **Stickers as Identity**: Every task can be assigned a sticker that serves as its visual anchor across the app.
- **Fluid Motion**: Powered by `flutter_animate` and Lottie, the UI feels alive with subtle micro-animations and smooth state transitions.
- **Premium Aesthetics**: Features a signature Dark Mode (`0xFF111827`), glassmorphism effects, and custom gradient priority badges.
- **Typography**: Optimized for clarity using the **Plus Jakarta Sans** font.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Current Platform: Windows)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database**: [Hive](https://pub.dev/packages/hive) (Local persistent storage)
- **Icons**: [Phosphor Flutter](https://pub.dev/packages/phosphor_flutter)
- **Animations**: [Lottie](https://pub.dev/packages/lottie), [Flutter Animate](https://pub.dev/packages/flutter_animate)
- **Notifications**: `win_toast` integration for native Windows support.

## 📦 Getting Started

1. Clone this repository.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run -d windows` to launch the app.

---

> *"Plan your day, stick to it."*
