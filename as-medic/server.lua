local ESX = exports[Config.ESXExport]:getSharedObject()

-- Interner Schalter
local npcEnabled = true

-- ========= Medics zählen =========
local function CountMedicsOnline()
    local count = 0

    if ESX.GetExtendedPlayers then
        -- ESX Legacy
        local players = ESX.GetExtendedPlayers()
        for _, xP in pairs(players) do
            local job = xP.getJob and xP.getJob() or xP.job
            local jname = job and (job.name or job) or nil
            if jname == Config.MedicJobName then
                count = count + 1
            end
        end
        return count
    end

    -- Ältere ESX
    if ESX.GetPlayers then
        for _, id in ipairs(ESX.GetPlayers()) do
            local xP = ESX.GetPlayerFromId(id)
            if xP then
                local job = xP.getJob and xP.getJob() or xP.job
                local jname = job and (job.name or job) or nil
                if jname == Config.MedicJobName then
                    count = count + 1
                end
            end
        end
    end

    return count
end

local function BroadcastNpcState(enabled)
    npcEnabled = enabled and true or false
    TriggerClientEvent('npc_medical:setNpcEnabled', -1, npcEnabled)
end

local function ReevaluateNpc()
    local medics = CountMedicsOnline()
    local shouldEnable = (medics < Config.MedicMinOnline)
    if shouldEnable ~= npcEnabled then
        BroadcastNpcState(shouldEnable)
        print(('[npc_medical] NPC %s (Medics online: %d | Schwelle: %d)'):format(
            shouldEnable and 'aktiviert' or 'deaktiviert', medics, Config.MedicMinOnline
        ))
    end
end

-- ========= Initialisierung & Intervall =========
CreateThread(function()
    Wait(3000)      -- auf ESX/Spieler warten
    ReevaluateNpc()
    while true do
        Wait(Config.MedicCheckIntervalMs)
        ReevaluateNpc()
    end
end)

-- ========= Events, die Neu-Bewertung triggern =========
RegisterNetEvent('npc_medical:requestNpcState', function()
    local src = source
    TriggerClientEvent('npc_medical:setNpcEnabled', src, npcEnabled)
end)

-- Jobwechsel / Spieler laden / disconnect
AddEventHandler('esx:setJob', function(playerId, job, lastJob)
    SetTimeout(500, ReevaluateNpc)
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    SetTimeout(500, ReevaluateNpc)
end)

AddEventHandler('playerDropped', function()
    SetTimeout(500, ReevaluateNpc)
end)

-- ========= Bezahlte Aktionen =========
-- Heilen: nur wenn nicht volle HP, NPC aktiv
RegisterNetEvent('npc_medical:payAndHeal', function()
    local src = source
    if not npcEnabled then
        TriggerClientEvent('esx:showNotification', src, '~y~Medics sind verfügbar. Der NPC arbeitet derzeit nicht.')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local health = GetEntityHealth(ped)
        local maxHealth = GetEntityMaxHealth(ped)
        if health >= maxHealth then
            TriggerClientEvent('esx:showNotification', src, '~y~Du hast bereits volle Gesundheit.')
            return
        end
    end

    local price = Config.PriceHealSelf
    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        TriggerClientEvent('npc_medical:clientHeal', src)
        TriggerClientEvent('esx:showNotification', src, ('~g~Behandlung abgeschlossen. -$%d'):format(price))
    else
        TriggerClientEvent('esx:showNotification', src, '~r~Du hast nicht genug Geld.')
    end
end)

-- Revive: nur wenn Ziel tot, Distanz ok, NPC aktiv
RegisterNetEvent('npc_medical:payAndRevive', function(targetServerId)
    local src = source
    if not npcEnabled then
        TriggerClientEvent('esx:showNotification', src, '~y~Medics sind verfügbar. Der NPC arbeitet derzeit nicht.')
        return
    end

    local xPayer = ESX.GetPlayerFromId(src)
    if not xPayer then return end

    local tId = tonumber(targetServerId)
    if not tId or tId == src then
        TriggerClientEvent('esx:showNotification', src, '~r~Ungültiges Ziel.')
        return
    end

    local xTarget = ESX.GetPlayerFromId(tId)
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, '~r~Zielspieler nicht gefunden.')
        return
    end

    local targetPed = GetPlayerPed(tId)
    if not targetPed or targetPed == 0 then
        TriggerClientEvent('esx:showNotification', src, '~r~Zielped nicht verfügbar.')
        return
    end

    local targetHealth = GetEntityHealth(targetPed)
    if targetHealth > 0 then
        TriggerClientEvent('esx:showNotification', src, '~y~Dieser Spieler lebt bereits und kann nicht wiederbelebt werden.')
        return
    end

    -- Distanz-Check (Anti-Exploit)
    local payerPed = GetPlayerPed(src)
    if payerPed ~= 0 then
        local pc = GetEntityCoords(payerPed)
        local tc = GetEntityCoords(targetPed)
        if #(pc - tc) > (Config.ReviveDistance + 1.0) then
            TriggerClientEvent('esx:showNotification', src, '~r~Du bist zu weit weg, um den Spieler wiederzubeleben.')
            return
        end
    end

    local price = Config.PriceReviveOther
    if xPayer.getMoney() >= price then
        xPayer.removeMoney(price)
        TriggerClientEvent('npc_medical:clientRevive', tId)
        TriggerClientEvent('esx:showNotification', src, ('~g~Du hast einen Spieler wiederbelebt. -$%d'):format(price))
        TriggerClientEvent('esx:showNotification', tId, '~g~Ein Sanitäter hat dich wiederbelebt.')
    else
        TriggerClientEvent('esx:showNotification', src, '~r~Du hast nicht genug Geld.')
    end
end)
