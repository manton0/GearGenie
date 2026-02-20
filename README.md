# GearGenie

A gear comparison addon for the **Ascension** private server (WoW 3.3.5). GearGenie evaluates item stats using per-class/per-spec stat weights and tells you at a glance whether an item is an upgrade or downgrade.

## Features

- **Automatic Tooltip Comparison** — Hover any weapon or armor piece to see a score comparison vs your equipped item, with green/red coloring and percentage change
- **Comparison Window** — Drag two items side-by-side to see a full stat-by-stat breakdown with color-coded differences and total scores
- **Per-Class Stat Weights** — 13 classes with all specs, sourced from AutoGear (Warrior Fury, Mage Fire, Priest Holy, etc.)
- **Auto-Detection** — Automatically detects your class and applies the right weight profile
- **Classless Realm Support** — On Ascension's classless realm (Hero class), falls back to primary stat detection (Strength, Agility, Intellect, Spirit)
- **Config UI** — Select your class and spec from dropdowns, changes apply immediately
- **Scaled Item Support** — Correctly reads Ascension's level-scaled item stats (not just base template values)
- **Persistent Settings** — Your class/spec selection is saved between sessions

## Installation

1. Download the latest release from the [Releases page](https://github.com/manton0/GearGenie/releases/latest)
2. Extract the ZIP into your `Interface/AddOns` folder
3. Make sure the folder is called `GearGenie`
4. Start your client and enjoy

## Usage

- `/gg` — Open the config window to select your class and spec
- `/gg compare` — Open the comparison window directly
- `/gg help` — Show all available commands
- **Hover items** in your bags or character panel to see automatic upgrade/downgrade scoring
- **Drag items** into the comparison window slots to compare any two items side-by-side
- **Right-click** a comparison slot to clear it

## Author

**mazer** (Discord: the_mazer)
