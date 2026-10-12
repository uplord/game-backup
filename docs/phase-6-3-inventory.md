# Phase 6.3 — Inventory & Equipment (local prototype)

- Press **I** to open inventory. Click an equippable item to equip it; click an occupied equipment slot to unequip.
- Copper Ore and other known items gathered from resources now enter the shared `Inventory` autoload.
- Slots: helm, armour, cape, main_hand, off_hand, pickaxe, axe, fishing_rod.
- An item needs `equipment_slot` (or `equipmentSlot` / `slot`) matching the slot name to equip.
- Inventory uses the active published `items` definitions. Missing item IDs are rejected with a warning.
- Items are kept across map changes **in the current game session**, not saved across restarts. Server persistence, item use, stats and durability remain future work.
- Combat respawn also restores the enemy's runtime enabled flag and HP.
