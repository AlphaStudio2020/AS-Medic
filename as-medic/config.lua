Config = {}

-- 🧭 Menütyp wählen: "as" (as-menu) | "esx" (ESX.UI.Menu) | "none" (Tastatur)
Config.MenuType = "esx"

-- ESX Export-Name
Config.ESXExport = 'es_extended'  -- i.d.R. 'es_extended'

-- Preise
Config.PriceHealSelf = 250      -- Preis fürs Selbst-Heilen
Config.PriceReviveOther = 1500  -- Preis fürs Wiederbeleben eines anderen

-- Distanz, in der ein "anderer" Spieler fürs Revive gefunden werden darf
Config.ReviveDistance = 3.0

-- NPC-Settings
Config.NPC = {
    model = 's_m_m_doctor_01',
    coords = vector3(1139.2552, -1546.6598, 35.3805),
    heading = 230.0,
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

-- Blip
Config.Blip = {
    enabled = true,
    sprite = 61, 
    color = 2,
    scale = 0.8,
    name = 'Sanitäter (NPC)'
}


Config.Key = 38 


-- === Dynamisches Deaktivieren bei Medics ===
Config.MedicJobName = 'ambulance'  -- Job-Name der Medics
Config.MedicMinOnline = 2          -- Ab dieser Anzahl Medics: NPC + Blip verschwinden
Config.MedicCheckIntervalMs = 15000 -- Fallback-Intervall für regelmäßigen Check (ms)