# Item Spammer

**Version:** 1.1.0

## Overview

Item Spammer is a Guild Wars bot that helps you advance character titles by automatically consuming items from your inventory. It intelligently uses consumables to progress **Drunkard**, **Party Animal**, and **Sweet Tooth** titles with real-time tracking and smart item prioritization.

## ✨ Features

- **Automatic Item Consumption:** Continuously uses items from your inventory
- **Multi-Category Support:** Select and spam 1, 2, or all 3 categories in a single session
- **Real-time Title Tracking:** Directly reads title points from game memory via GwAu3 API
- **Three Title Categories:**
  - 🍺 **Drunkard** - Alcohol items
  - 🎉 **Party Animal** - Party items (fireworks, tonics, etc.)
  - 🍰 **Sweet Tooth** - Sweet items (candy, cakes, etc.)
- **Point Threshold Management:** Automatically stops at 10,000 points (max title level)
- **Value-Based Prioritization:** Uses less valuable items first (1pt → 2pt → 3pt → 5pt → 7pt → 25pt → 50pt)
- **Title Level Display:** Shows current accomplishment level (0-2) for each title
- **Session Statistics:** Current points per title | Session gains | Items used counter | Runtime tracking

## Requirements

- **Guild Wars** (Game must be running)
- **[GwAu3](https://github.com/JAG-GW/GwAu3)** - Guild Wars AutoIt library
- **AutoIt3** - To run `.au3` scripts

## Installation

1. Clone or download the GwAu3 repository
2. Extract to `GwAu3/Scripts`
3. Run `Item-spammer.au3`

## How It Works
1. **Category Selection:** Choose one or multiple categories to spam using checkboxes
2. **Initialization:** Connects to Guild Wars client and reads current title points from memory
3. **Item Scanning:** Scans all inventory bags for consumable items matching the selected categories
4. **Smart Sorting:** Prioritizes items by point value (lowest first) to maximize efficiency
5. **Sequential Processing:** Processes each selected category one after another:
   - Completes first category (max points or out of items)
   - Automatically moves to next selected category
   - Continues until all selected categories are complete
6. **Consumption Loop:**
   - Uses the lowest-value item available
   - Waits for item cooldown (e.g. tonics, instant for most items)
7. **Auto-Stop:** Stops when reaching 10,000 points or running out of items for all selected categories

### Important Notes

- ⚠️ **Must be in an Outpost or Guild Hall**
- ⚠️ **Character must be logged in** and in-game
- ⚠️ **Do not interfere** with the game while spamming is in progress

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
- 1 point: Fruitcake, Mandragor Root Cake, Sugary Blue Drink (3 items)
- 2 points: Chocolate Bunny, Red Bean Cake, Jar of Honey (3 items)
- 3 points: Crème Brûlée, Krytan Lokum, Mini Treats of Purity (3 items)
- 50 points: Delicious Cake

**Reference:** [Guild Wars Wiki - Sweet](https://wiki.guildwars.com/wiki/Sweet)

**Note:** Explorable-area-only items are excluded (Candy Apple, Candy Corn, Golden Egg, Honeycomb, Pumpkin Cookie, Refined Jelly, Slice of Pumpkin Pie, War Supplies, Wintergreen/Rainbow/Peppermint Candy Canes, Birthday Cupcake, Rock Candies). These items cannot be used in outposts/guild halls where the bot operates.

## Tips

- Stock your inventory with items **before** starting the bot
- Use cheaper items to save expensive ones (automation will prioritize automatically)
- Select multiple categories to spam them all in one session - statistics are preserved throughout
- The bot displays progress for **all three titles**, tracking gains across the entire session
- Final statistics are shown in the log when stopped

## Planned Features

- 🏰 **Travel to Guild Hall:** Automatically travel to the Guild Hall to use tonics or fireworks and bypass usage restrictions
- 📦 **Storage Integration:** Pick up items directly from storage to avoid manually moving them to the character's inventory
- ⚙️ **Configurable Priority:** Option to change the priority order of item usage (from most valuable to least valuable, or custom order)

## 💡 Feature Ideas

Ideas under consideration for future development:

- 🎁 **Extended Item Support:** Add functionality to automatically open Strongboxes, Wintersday Gifts, Zaishen Chests, and other stackable containers (ideas from Title Helper)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author
Made by Arca, also known as jbi3

---

**⚠️ Disclaimer:** Use of automation tools may violate Guild Wars Terms of Service. Use at your own risk.