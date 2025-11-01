# 🏥 AS-Medical | NPC Medic System for ESX

A simple and optimized **ESX NPC Medic** script that lets players heal or revive themselves (or others) via an NPC — only when not enough real medics are online.

---

## ✨ Features
- 🧍 Dynamic NPC that appears only if few medics are online  
- 💰 Configurable prices for healing and reviving  
- ⚙️ Compatible with **ESX Legacy** and older versions  
- 📋 Supports **as-menu**, **ESX.UI.Menu**, or simple key interactions  
- 💡 Automatic detection and deactivation when medics log in/out  
- 📍 Optional blip on the map  
- 🔧 Fully configurable via `config.lua`

---

## 🧩 Requirements
- [ESX Framework](https://github.com/esx-framework/esx_core)  
- (Optional) [as-menu]()  SOON
- MySQL-Async (already referenced)

---

## ⚙️ Installation
1. Download or clone this repository:
   ```bash
   git clone https://github.com/AlphaStudio2020/as-medical.git
   ```
2. Place the folder into your `resources` directory:
   ```
   resources/[esx]/as-medical
   ```
3. Add the resource to your `server.cfg`:
   ```bash
   ensure as-medical
   ```
4. Adjust your configuration in `config.lua`:
   ```lua
   Config.PriceHealSelf = 250
   Config.PriceReviveOther = 1500
   Config.MedicMinOnline = 2
   ```

---

## 🧠 How It Works
- When fewer than `Config.MedicMinOnline` medics are online,  
  an **NPC doctor** spawns at the defined coordinates.
- Players can interact with the NPC (`E` key by default).
- Menu opens to:
  - Heal themselves
  - Revive nearby dead players
- Payment is handled server-side with anti-exploit checks.

---

## 📁 File Structure
```
as-medical/
│
├── fxmanifest.lua
├── config.lua
├── client.lua
└── server.lua
```



## 🧑‍💻 Author
**AS.DEV**  
Discord: *yourname#0000*  
GitHub: [github.com/yourname](https://github.com/AlphaStudio2020)

---

## 📜 License
This project is open source for personal use.  
Please credit the author when redistributing or modifying.
