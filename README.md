# aux – Enhanced Auction House AddOn

[![ClassicAPI](https://img.shields.io/badge/ClassicAPI-Required-800080?labelColor=555555&style=flat-square)](https://github.com/brues-code/ClassicAPI)
[![HearthDB](https://img.shields.io/badge/HearthDB-Required-800080?labelColor=555555&style=flat-squar)](https://github.com/copypasteonly/HearthDB)
[![Join our Discord](https://img.shields.io/badge/Discord-Join%20our%20server-5865F2?logo=discord&logoColor=white)](https://discord.gg/XDMJVczNcY)

A performance-focused fork of **aux**, the advanced Auction House addon for World of Warcraft 1.12.1, featuring additional optimizations, improved compatibility, and HearthDB integration.

Designed primarily for **Turtle WoW and Vanilla WoW 1.12.1**, this fork aims to provide a smoother and more responsive Auction House experience while preserving the familiar aux interface, pricing system, and workflow.

## ✨ Features

### 🚀 Performance Improvements

- Optimized event listener management and background task scheduling.
- Reduced unnecessary frame updates and repeated calculations.
- Improved item cache scanning and historical price calculations.
- Optimized Auction House listing rendering and selection handling.
- Reduced temporary memory allocations and redundant UI operations.
- Improved responsiveness when handling large auction listings.

### 💾 HearthDB Integration

- SQLite-based auction history storage using HearthDB.
- Stores historical data in `CustomData/aux-history.db`.
- Cached database reads and batched background writes.
- Automatic migration from existing SavedVariables history.
- Fallback to SavedVariables if database operations fail.

### 🎨 Themes

| Theme | Description |
|-------|-------------|
| Blizzard | Classic Blizzard interface styling |
| Modern | Modernized aux appearance |
| pfUI | Native pfUI styling when pfUI is installed |

**Switch themes using:**

```text
/aux theme
/aux theme pfui
```

### 📊 Auction History & Pricing

- Daily minimum unit buyout tracking.
- Long-term historical pricing calculated using an age-weighted median.
- Automatic price history collection during Auction House scans.
- Optional price sharing through the LFT channel.
- Improved caching for historical values and pricing calculations.

### 🛒 Auction House

- Search, Auctions, Bids, and Post functionality.
- Automatic auction scanning and listing management.
- Auction posting with pricing and undercutting rules.
- Improved handling of large auction lists.
- More reliable loading and refreshing of Auctions and Bids tabs.

### 🔧 Compatibility

- World of Warcraft 1.12.1.
- Turtle WoW support.
- ClassicAPI compatibility.
- HearthDB database integration.
- Optional pfUI theme integration.

---

## 📦 Installation

1. Download or clone this repository.
2. Extract the addon into your WoW `Interface/AddOns/` directory.
3. Make sure the addon folder is named exactly `aux-addon`.
4. Install ClassicAPI and HearthDB dependencies.
5. Launch the game and open the Auction House.

---

## ⌨️ Slash Commands

| Command | Description |
|---------|-------------|
| `/aux` | Display available settings |
| `/aux theme` | Cycle through available themes |
| `/aux theme pfui` | Enable the pfUI theme |
| `/aux hdb` | Display HearthDB integration status |
| `/aux hdb clean` | Remove old SavedVariables history after migration |

---

## 🗄️ Database

HearthDB is used to store auction history in an SQLite database.

**Database location:**

```text
CustomData/aux-history.db
```

The database keeps historical auction data separate from the standard WoW SavedVariables system, helping reduce SavedVariables overhead.

---

## 🤝 Credits

This project is based on the original **aux Auction House addon** and builds upon the work of its original developers and contributors.

- **Original addon:** [shirsig/aux-addon-vanilla](https://github.com/shirsig/aux-addon-vanilla)
- **HearthDB:** SQLite database integration.
- **pfUI:** Optional interface styling integration.
- **ClassicAPI:** Classic WoW API compatibility.

Additional optimizations, compatibility improvements, and integrations are maintained in this fork.

---

## 📄 License

See [LICENSE](LICENSE) for license information.
