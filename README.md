# Item Spammer

**Version:** 1.0  
**Status:** Public

## Overview

Item Spammer is a Guild Wars bot that helps you advance character titles by automatically consuming items from your inventory. It intelligently uses consumables to progress **Drunkard**, **Party Animal**, and **Sweet Tooth** titles with real-time tracking and smart item prioritization.

## Features

### 🎯 Core
- **Automatic Item Consumption:** Continuously uses items from your inventory with randomized delays (100-200ms) to appear natural
- **Real-time Title Tracking:** Directly reads title points from game memory via GwAu3 API
- **Three Title Categories:**
  - 🍺 **Drunkard** - Alcohol items
  - 🎉 **Party Animal** - Party items (fireworks, tonics, etc.)
  - 🍰 **Sweet Tooth** - Sweet items (candy, cakes, etc.)

### 💡 Features
- **Point Threshold Management:** Automatically stops at 10,000 points (max title level)
- **Value-Based Prioritization:** Uses less valuable items first (1pt → 2pt → 3pt → 5pt → 7pt → 25pt → 50pt)
- **Title Level Display:** Shows current accomplishment level (0-2) for each title
- **Session Statistics:** Current points per title | Session gains | Items used counter | Runtime tracking

## Requirements

- **Guild Wars** (Game must be running)
- **[GwAu3](https://github.com/JAG-GW/GwAu3)** - Guild Wars AutoIt library
- **AutoIt3** - To run `.au3` scripts

## Installation

1. Clone or download the GwAu3 repository, inside Scripts folder
2. Navigate to `Scripts/Item-spammer/`
3. Run `Item-spammer.au3` with AutoIt3

## How It Works
1. **Initialization:** Connects to Guild Wars client and reads current title points from memory
2. **Item Scanning:** Scans all inventory bags for consumable items matching the selected category
3. **Smart Sorting:** Prioritizes items by point value (lowest first) to maximize efficiency
4. **Consumption Loop:**
   - Uses the lowest-value item available
   - Waits for item cooldown (e.g. tonics, instant for most items)
   - Applies random delay (100-200ms) between uses
5. **Auto-Stop:** Stops when reaching 10,000 points or running out of items

## Title Levels
| Level | Points Required | Display |
|-------|----------------|---------|
| **0** | 0 - 999        | Title (0) - No title |
| **1** | 1,000 - 9,999  | Title (1) - First level |
| **2** | 10,000+        | Title (2) - Max level ⭐ |

## Item Point Values

### Alcohol (Drunkard)
- 1 point: Hunter's Ale, Eggnog, etc. (11 items)
- 3 points: Aged variants (7 items)
- 50 points: Keg of Aged Hunter's Ale

**Reference:** [Guild Wars Wiki - Alcohol](https://wiki.guildwars.com/wiki/Alcohol)

### Party (Party Animal)
- 1 point: Fireworks, sparklers (6 items)
- 2 points: Most tonics (19 items)
- 3 points: Crate of Fireworks, special tonics
- 5 points: Mysterious Tonic
- 7 points: Disco Ball
- 25 points: Spooky Tonic
- 50 points: Party Beacon

**Reference:** [Guild Wars Wiki - Festive Items](https://wiki.guildwars.com/wiki/Festive_item)

### Sweet (Sweet Tooth)
- 1 point: Candy Corn, Candy Apple, etc. (13 items)
- 2 points: Cupcake, Chocolate Bunny, etc. (5 items)
- 3 points: Crème Brûlée, Green Rock Candy (4 items)
- 5 points: Blue Rock Candy
- 7 points: Red Rock Candy
- 50 points: Delicious Cake

**Reference:** [Guild Wars Wiki - Sweet](https://wiki.guildwars.com/wiki/Sweet)

## Tips

- Stock your inventory with items **before** starting the bot
- Use cheaper items to save expensive ones (automation will prioritize automatically)
- The bot displays progress for **all three titles**, even when working on just one category
- Final statistics are shown in the log when stopped

## Planned Features

- 🏰 **Travel to Guild Hall:** Automatically travel to the Guild Hall to use tonics or fireworks and bypass usage restrictions
- 📦 **Storage Integration:** Pick up items directly from storage to avoid manually moving them to the character's inventory
- ⚙️ **Configurable Priority:** Option to change the priority order of item usage (from most valuable to least valuable, or custom order)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author
Made by Arca, also known as jbi3

---

**⚠️ Disclaimer:** Use of automation tools may violate Guild Wars Terms of Service. Use at your own risk.
