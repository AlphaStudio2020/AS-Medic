Config = {}

-- 🧭 Menütyp wählen: "as" (as-menu) | "esx" (ESX.UI.Menu) | "none" (Tastatur)
Config.MenuType = "esx"

-- ESX Export-Name
Config.ESXExport = 'es_extended'  -- i.d.R. 'es_extended'

-- Prices 
Config.PriceHealSelf = 250      -- Price for self-healing 
Config.PriceReviveOther = 1500  -- Price for reviving another 
-- Distance in which another player may be found for the Revive 
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
    name = 'Paramedics (NPC)'
}


Config.Key = 38 


-- === Deactivate dynamics at Medics  ===
Config.MedicJobName = 'ambulance'  -- Job-Name der Medics   
Config.MedicMinOnline = 2          -- From this number of media: NPC + Blip disappear 
Config.MedicCheckIntervalMs = 15000 -- Fallback interval for regular check-ups  (ms)
