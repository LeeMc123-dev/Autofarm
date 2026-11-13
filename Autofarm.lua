-- ID del juego "Escaleras Obby Difícil"
local TARGET_PLACE_ID = 12101921792

if game.PlaceId ~= TARGET_PLACE_ID then
    warn("Este script solo funciona en Escaleras Obby Difícil.")
    return
end

-- Cargar WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Crear ventana principal
local Window = WindUI:CreateWindow({
    Title = "Auto-Farm Coins",
    Icon = "coins",
    Author = "??",
    Folder = "EduardAutoFarm",
    Size = UDim2.fromOffset(480, 340),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 150,
})

-- Crear pestaña
local MainTab = Window:Tab({
    Title = "Principal",
    Icon = "play",
})

-- Variables de control
local autoFarmActive = false
local farmSpeed = 0.1
local searchFilter = "" -- Si está vacío, buscará partes físicas o modelos de monedas

-- Función mejorada para encontrar monedas de forma más flexible
local function getOrderedCoins(rootPart)
    local coins = {}
    local filterLower = searchFilter:lower()

    -- Revisamos todos los descendientes en el Workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Verificamos si es una Parte o un Modelo que parezca una moneda
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local primaryPart = obj:IsA("Model") and obj.PrimaryPart or obj
            
            if primaryPart then
                local nameLower = obj.Name:lower()
                local parentName = obj.Parent and obj.Parent.Name:lower() or ""

                -- Condición de coincidencia: si coincide con el filtro o nombres típicos de monedas/recompensas
                local matchesFilter = (filterLower == "") or nameLower:find(filterLower) or parentName:find(filterLower) or nameLower:find("coin") or nameLower:find("gold") or nameLower:find("cash") or nameLower:find("money")

                if matchesFilter then
                    local distance = (rootPart.Position - primaryPart.Position).Magnitude
                    -- Límite ampliado a 2000 studs para cubrir la altura de las escaleras
                    if distance < 2000 then
                        table.insert(coins, {part = primaryPart, dist = distance})
                    end
                end
            end
        end
    end

    -- Ordenar de más cercana a más lejana
    table.sort(coins, function(a, b)
        return a.dist < b.dist
    end)

    return coins
end

-- Bucle principal del Auto-Farm
task.spawn(function()
    while true do
        if autoFarmActive then
            pcall(function()
                local player = game.Players.LocalPlayer
                local character = player.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                if rootPart then
                    local orderedCoins = getOrderedCoins(rootPart)

                    for _, coinData in ipairs(orderedCoins) do
                        if not autoFarmActive then break end
                        local coinPart = coinData.part

                        if coinPart and coinPart.Parent then
                            -- Teletransporte directo a la moneda
                            rootPart.CFrame = coinPart.CFrame + Vector3.new(0, 2, 0)
                            
                            -- Intentar forzar el toque si existe TouchTransmitter
                            if firetouchinterest then
                                firetouchinterest(rootPart, coinPart, 0)
                                firetouchinterest(rootPart, coinPart, 1)
                            end
                            
                            task.wait(farmSpeed)
                        end
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- Elementos de la interfaz (Controles en WindUI)
MainTab:Toggle({
    Title = "Activar Auto-Farm",
    Desc = "Teletransporta al personaje hacia las monedas",
    Value = false,
    Callback = function(state)
        autoFarmActive = state
    end
})

MainTab:Slider({
    Title = "Velocidad de Recolección",
    Desc = "Tiempo de espera entre cada teletransporte",
    Step = 0.02,
    Value = {
        Min = 0.05,
        Max = 1.0,
        Default = 0.1,
    },
    Callback = function(value)
        farmSpeed = value
    end
})

MainTab:Input({
    Title = "Filtro de Nombre (Opcional)",
    Desc = "Déjalo vacío o escribe parte del nombre de la moneda",
    Value = "",
    Placeholder = "Ej: coin, gold...",
    Callback = function(text)
        searchFilter = text or ""
    end
})

-- NUEVO BOTÓN: Teletransporte rápido hacia arriba / Fogata o checkpoints más altos
MainTab:Button({
    Title = "Subir al Checkpoint / Fogata más alta",
    Desc = "Te teletransporta al objeto más alto del mapa (faro o fogata)",
    Callback = function()
        pcall(function()
            local player = game.Players.LocalPlayer
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")

            if rootPart then
                local highestPart = nil
                local maxHeight = -math.huge

                -- Buscamos la parte más alta en el mapa (como el faro o checkpoints superiores)
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        if obj.Position.Y > maxHeight then
                            maxHeight = obj.Position.Y
                            highestPart = obj
                        end
                    end
                end

                if highestPart then
                    rootPart.CFrame = highestPart.CFrame + Vector3.new(0, 5, 0)
                    WindUI:Notify({
                        Title = "Teletransporte",
                        Content = "¡Movido a la zona más alta!",
                        Duration = 3
                    })
                end
            end
        end)
    end
})
