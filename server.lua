local playersInTrunk = {} -- Tabela para manter os jogadores trancados no porta-malas
local lastCommandTime = {}
local commandCooldown = 2000 -- Tempo de recarga em milissegundos

-- Função para enviar mensagens personalizadas
local function outputMessage(elem, mess, tipo)
    return exports["[HS]Infobox"]:notify(elem, mess, tipo)
end

function enterTrunk(player, vehicle)
    if isElement(vehicle) and getElementType(vehicle) == "vehicle" and hasTrunk(vehicle) then
        -- Verifica se já há alguém no porta-malas ou capô
        for p in pairs(playersInTrunk) do
            if playersInTrunk[p] == vehicle then
                outputMessage(player, "Esse porta-malas já está ocupado!", "error")
                return
            end
        end
        
        local trunkPosX, trunkPosY, trunkPosZ = getPositionFromElementOffset(vehicle, 0, 1, 0)
        local vehicleID = getElementModel(vehicle)

        -- Abre o capô ou porta-malas
        if vehicleID == 545 or vehicleID == 429 then
            setVehicleDoorOpenRatio(vehicle, 0, 1, 1000) -- Abre o capô
            setTimer(function()
                setElementPosition(player, trunkPosX, trunkPosY, trunkPosZ)
                attachElements(player, vehicle, 0, 0.5, 0.5)
                playersInTrunk[player] = vehicle
                setElementAlpha(player, 0)
                outputMessage(player, "Você entrou no porta-malas!", "success")

                -- Fecha o capô após um breve atraso
                setTimer(function()
                    setVehicleDoorOpenRatio(vehicle, 0, 0, 1000) -- Fecha o capô
                end, 500, 1)

                -- Ajusta a visão do jogador para a frente
                local _, _, vehicleYaw = getElementRotation(vehicle)
                setElementRotation(player, 0, 0, vehicleYaw + 180)
            end, 1000, 1) -- Espera 1000 ms para garantir que o capô esteja totalmente aberto
        else
            setVehicleDoorOpenRatio(vehicle, 1, 1, 1000) -- Abre o porta-malas
            setTimer(function()
                setElementPosition(player, trunkPosX, trunkPosY, trunkPosZ)
                attachElements(player, vehicle, 0, -2, 0.5)
                playersInTrunk[player] = vehicle
                setElementAlpha(player, 0)
                outputMessage(player, "Você entrou no porta-malas!", "success")

                -- Fecha o porta-malas após um breve atraso
                setTimer(function()
                    setVehicleDoorOpenRatio(vehicle, 1, 0, 1000) -- Fecha o porta-malas
                end, 500, 1)
            end, 1000, 1) -- Espera 1000 ms para garantir que o porta-malas esteja totalmente aberto
        end
    else
        outputMessage(player, "Esse veículo não tem porta-malas!", "error")
    end
end

-- Função para tirar o jogador do porta-malas ou capô
function exitTrunk(player)
    local vehicle = playersInTrunk[player]
    if vehicle and isElement(vehicle) and getElementType(vehicle) == "vehicle" then
        local vehicleID = getElementModel(vehicle)

        if vehicleID == 545 or vehicleID == 429 then
            -- Animação de abertura do capô
            setVehicleDoorOpenRatio(vehicle, 0, 1, 1000) -- Abre o capô
            setTimer(function()
                detachElements(player, vehicle)
                -- Teleporta o jogador para a frente do veículo, mais próximo
                local x, y, z = getPositionFromElementOffset(vehicle, 0, 3, 0) -- Ajustado para 3 para ficar mais à frente
                setElementPosition(player, x, y, z + 1) -- Eleva um pouco para evitar colisão
                
                -- Fecha o capô após um breve atraso
                setTimer(function()
                    setVehicleDoorOpenRatio(vehicle, 0, 0, 1000) -- Fecha o capô
                end, 500, 1) -- Espera 500 ms antes de fechar
                
                playersInTrunk[player] = nil -- Remove o jogador da lista
                setElementAlpha(player, 255) -- Torna o jogador visível novamente
                outputMessage(player, "Você saiu do porta-malas!", "success")
            end, 1000, 1) -- Aguarda 1000 ms para garantir que o capô esteja totalmente aberto
        else
            -- Animação de abertura do porta-malas
            setVehicleDoorOpenRatio(vehicle, 1, 1, 1000) -- Abre o porta-malas
            setTimer(function()
                detachElements(player, vehicle)
                local x, y, z = getPositionFromElementOffset(vehicle, 0, -4, 0) -- Teleporta o jogador para trás do veículo
                setElementPosition(player, x, y, z + 1) -- Eleva um pouco para evitar colisão
                
                -- Fecha o porta-malas após um breve atraso
                setTimer(function()
                    setVehicleDoorOpenRatio(vehicle, 1, 0, 1000) -- Fecha o porta-malas
                end, 500, 1) -- Espera 500 ms antes de fechar
                
                playersInTrunk[player] = nil -- Remove o jogador da lista
                setElementAlpha(player, 255) -- Torna o jogador visível novamente
                outputMessage(player, "Você saiu do porta-malas!", "success")
            end, 1000, 1) -- Aguarda 1000 ms para garantir que o porta-malas esteja totalmente aberto
        end
    else
        outputMessage(player, "Você não está no porta-malas!", "error")
    end
end

-- Comando para entrar/sair do porta-malas
addCommandHandler("trunk", 
    function(player)
        local currentTime = getTickCount()

        -- Checa se o jogador está dentro do tempo de recarga
        if lastCommandTime[player] and currentTime - lastCommandTime[player] < commandCooldown then
            outputMessage(player, "Aguarde um pouco antes de usar este comando novamente.", "error") -- Mensagem de erro
            return
        end

        local vehicle = getPedOccupiedVehicle(player)
        if playersInTrunk[player] then
            exitTrunk(player) -- Se já estiver no porta-malas, tenta sair
        else
            if not vehicle then
                local x, y, z = getElementPosition(player)
                local nearbyVehicle = getClosestVehicle(player, x, y, z)
                if nearbyVehicle then
                    enterTrunk(player, nearbyVehicle)
                else
                    outputMessage(player, "Não há veículo próximo!", "error")
                end
            else
                outputMessage(player, "Você já está em um veículo!", "error")
            end
        end

        -- Atualiza o tempo do último comando
        lastCommandTime[player] = currentTime
    end
)

-- Função para obter o veículo mais próximo
function getClosestVehicle(player, x, y, z)
    local minDist = 5 -- Distância máxima para detectar o veículo mais próximo
    local closestVehicle = nil

    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        local vx, vy, vz = getElementPosition(vehicle)
        local dist = getDistanceBetweenPoints3D(x, y, z, vx, vy, vz)
        if dist < minDist then
            minDist = dist
            closestVehicle = vehicle
        end
    end

    return closestVehicle
end

-- Função para verificar se o veículo tem porta-malas
function hasTrunk(vehicle)
    local model = getElementModel(vehicle)
    local vehiclesWithoutTrunk = { 448, 462, 581, 521 } -- IDs de motos que não têm porta-malas
    for _, v in ipairs(vehiclesWithoutTrunk) do
        if model == v then
            return false
        end
    end
    return true
end

-- Função auxiliar para obter a posição do elemento com um deslocamento
function getPositionFromElementOffset(element, x, y, z)
    local matrix = getElementMatrix(element)
    local offX = x * matrix[1][1] + y * matrix[2][1] + z * matrix[3][1] + matrix[4][1]
    local offY = x * matrix[1][2] + y * matrix[2][2] + z * matrix[3][2] + matrix[4][2]
    local offZ = x * matrix[1][3] + y * matrix[2][3] + z * matrix[3][3] + matrix[4][3]
    return offX, offY, offZ
end
