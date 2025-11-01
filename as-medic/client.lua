local ESX = exports[Config.ESXExport]:getSharedObject()

local npcPed, npcBlip = nil, nil
local npcEnabled = false -- wird vom Server gesetzt

-- ========= NPC / Blip Erzeugen & Entfernen =========
local function SpawnNPC()
    if npcPed and DoesEntityExist(npcPed) then return end

    local model = GetHashKey(Config.NPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    npcPed = CreatePed(4, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.heading, false, true)
    SetEntityAsMissionEntity(npcPed, true, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    SetPedCanRagdoll(npcPed, false)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)

    if Config.NPC.scenario and Config.NPC.scenario ~= '' then
        TaskStartScenarioInPlace(npcPed, Config.NPC.scenario, 0, true)
    end

    if Config.Blip.enabled and not npcBlip then
        npcBlip = AddBlipForCoord(Config.NPC.coords)
        SetBlipSprite(npcBlip, Config.Blip.sprite)
        SetBlipDisplay(npcBlip, 4)
        SetBlipScale(npcBlip, Config.Blip.scale)
        SetBlipColour(npcBlip, Config.Blip.color)
        SetBlipAsShortRange(npcBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.name)
        EndTextCommandSetBlipName(npcBlip)
    end
end

local function DespawnNPC()
    if npcPed and DoesEntityExist(npcPed) then
        DeletePed(npcPed)
    end
    npcPed = nil

    if npcBlip and DoesBlipExist(npcBlip) then
        RemoveBlip(npcBlip)
    end
    npcBlip = nil
end

-- ========= Server steuert Schalter =========
RegisterNetEvent('npc_medical:setNpcEnabled', function(enabled)
    npcEnabled = enabled and true or false
    if npcEnabled then
        SpawnNPC()
    else
        DespawnNPC()
    end
end)

-- Beim Client-Start Initialzustand anfragen
CreateThread(function()
    TriggerServerEvent('npc_medical:requestNpcState')
end)

-- ========= Hilfsfunktionen =========
local function DrawText3D(x,y,z, text)
    local onScreen,_x,_y = World3dToScreen2d(x,y,z)
    local px,py,pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px,py,pz) - vector3(x,y,z))
    local scale = (1.0 / math.max(dist, 0.1)) * 2.0
    local fov = (1.0 / GetGameplayCamFov()) * 100.0
    scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.45 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(1)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentString(text)
        EndTextCommandDisplayText(_x,_y)
    end
end

local function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local me = PlayerId()
    local plyCoords = GetEntityCoords(PlayerPedId())
    local closestDist = radius + 0.001
    local closestPlayer = -1

    for _,pid in ipairs(players) do
        if pid ~= me then
            local ped = GetPlayerPed(pid)
            local dist = #(GetEntityCoords(ped) - plyCoords)
            if dist < closestDist then
                closestDist = dist
                closestPlayer = pid
            end
        end
    end
    return closestPlayer
end

local function IsTargetDead(clientPlayerId)
    local targetPed = GetPlayerPed(clientPlayerId)
    if not targetPed or targetPed == 0 then return false end
    if IsEntityDead(targetPed) then return true end
    return GetEntityHealth(targetPed) <= 0
end

-- ========= Aktionen (Client) =========
local function TryHealSelf()
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)

    if health >= maxHealth then
        ESX.ShowNotification('~y~Du hast bereits volle Gesundheit.')
        return
    end
    TriggerServerEvent('npc_medical:payAndHeal')
end

local function TryReviveOther()
    local target = GetClosestPlayer(Config.ReviveDistance)
    if target == -1 then
        ESX.ShowNotification('~r~Kein Spieler in der Nähe zum Wiederbeleben.')
        return
    end
    if not IsTargetDead(target) then
        ESX.ShowNotification('~y~Dieser Spieler lebt bereits und kann nicht wiederbelebt werden.')
        return
    end
    TriggerServerEvent('npc_medical:payAndRevive', GetPlayerServerId(target))
end

-- ========= Menülogik je nach Config =========
local function OpenMedicalMenu()
    local elements = {
        {label = ('🩹 Selbst heilen ($%d)'):format(Config.PriceHealSelf), value = 'heal_self'},
        {label = ('💉 Anderen wiederbeleben (nahe) ($%d)'):format(Config.PriceReviveOther), value = 'revive_other'}
    }

    if Config.MenuType == "as" then
        -- as-menu
        if not exports['as-menu'] then
            ESX.ShowNotification('~r~as-menu nicht gefunden.')
            return
        end
        exports['as-menu']:openMenu({
            { header = 'Sanitäter (NPC)', isMenuHeader = true },
            {
                header = '🩹 Selbst heilen',
                txt = ('$%d'):format(Config.PriceHealSelf),
                params = { event = 'npc_medical:heal_self' }
            },
            {
                header = '💉 Anderen wiederbeleben',
                txt = ('$%d'):format(Config.PriceReviveOther),
                params = { event = 'npc_medical:revive_other' }
            }
        })
        return
    end

    if Config.MenuType == "esx" and ESX.UI and ESX.UI.Menu then
        -- ESX Menu
        ESX.UI.Menu.CloseAll()
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'npc_medical_menu', {
            title = 'Sanitäter (NPC)',
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            if data.current.value == 'heal_self' then
                TryHealSelf()
            elseif data.current.value == 'revive_other' then
                TryReviveOther()
            end
        end, function(_, menu)
            menu.close()
        end)
        return
    end

    -- Fallback (keine Menüs)
    ESX.ShowNotification('~b~[E] Heilen  |  [G] Revive naher Spieler')
    local t0 = GetGameTimer()
    while GetGameTimer() - t0 < 7000 do
        if IsControlJustReleased(0, 38) then -- E
            TryHealSelf()
            break
        elseif IsControlJustReleased(0, 47) then -- G
            TryReviveOther()
            break
        end
        Wait(0)
    end
end

-- Events für as-menu Buttons
RegisterNetEvent('npc_medical:heal_self', TryHealSelf)
RegisterNetEvent('npc_medical:revive_other', TryReviveOther)

-- ========= Interaktionsloop (nur wenn NPC aktiv) =========
CreateThread(function()
    while true do
        local sleep = 1000
        if npcEnabled and npcPed and DoesEntityExist(npcPed) then
            local pcoords = GetEntityCoords(PlayerPedId())
            local ncoords = GetEntityCoords(npcPed)
            local dist = #(pcoords - ncoords)
            if dist < 3.0 then
                sleep = 0
                DrawText3D(ncoords.x, ncoords.y, ncoords.z + 1.0, "~g~[E]~s~ Sanitäter sprechen")
                if IsControlJustReleased(0, Config.Key) then
                    OpenMedicalMenu()
                end
            end
        end
        Wait(sleep)
    end
end)

-- ========= Client-seitige Effekte =========
RegisterNetEvent('npc_medical:clientHeal', function()
    local ped = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(ped)
    SetEntityHealth(ped, maxHealth)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ESX.ShowNotification('~g~Du wurdest vollständig geheilt.')
end)

RegisterNetEvent('npc_medical:clientRevive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    ClearPedBloodDamage(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    SetEntityHealth(ped, maxHealth)
    ESX.ShowNotification('~g~Du wurdest wiederbelebt!')
end)
