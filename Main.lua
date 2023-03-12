local REvent = game:GetService("ReplicatedStorage").RemoteEvent
local RFunction = game:GetService("ReplicatedStorage").RemoteFunction

local System = {}
local PlaceId = game.PlaceId

getgenv().InLobby = (PlaceId == 3260590327)

if getgenv().InLobby then
    System.SearchFor = function(Table, Key)
        for CKey, _ in pairs(Table) do
            if CKey == Key then
                return true
            end
        end

        return false
    end

    System.GetLoadout = function(TTEquip, GTroops)
        local ActionsPerfomed = {}
        local Troops = {}

        for Troop, Data in pairs(RFunction:InvokeServer("Session", "Search", "Inventory.Troops")) do
            if Data.Equipped and not table.find(TTEquip, Troop) then
                Troops[Troop] = {["Goal"] = "Unequip"}
            elseif not Data.Equipped and table.find(TTEquip, Troop) then
                Troops[Troop] = {["Goal"] = "Equip"}
            elseif Data.Equipped and table.find(TTEquip, Troop) and System.SearchFor(Data, "GoldenPerks") then
                Troops[Troop] = {["Goal"] = "GoldenIdle"}
            end
        end

        for Troop, Data in pairs(Troops) do
            table.insert(ActionsPerfomed, {Data["Goal"], function()
                if Data["Goal"] ~= "GoldenIdle" then
                    RFunction:InvokeServer("Inventory", Data["Goal"], "Tower", Troop)
                end

                task.spawn(function()
                    if table.find(GTroops, Troop) then
                        RFunction:InvokeServer("Inventory", "Equip", "Golden", Troop)
                    else
                        RFunction:InvokeServer("Inventory", "Unequip", "Golden", Troop)
                    end
                end)
            end})
        end

        table.sort(ActionsPerfomed, function(Element1, Element2)
            if Element1[1] == "Unequip" and Element2[1] ~= "Unequip" then
                return true
            elseif Element1[1] ~= "Unequip" and Element2[1] == "Unequip" then
                return false
            else
                return false
            end
        end)

        for _, Data in ipairs(ActionsPerfomed) do
            task.spawn(Data[2])

            task.wait(1 / 15)
        end
    end

    System.JoinGame = function(Game, Type)
        local Elevators = workspace.Elevators:GetChildren()

        while true do
            for _, Elevator in pairs(Elevators) do
                if Elevator.State.Map.Title.Value == Game and Elevator.State.Players.Value == 0 and require(Elevator.Settings).Type == Type then
                    REvent:FireServer("Elevators", "Enter", Elevator)

                    repeat
                        task.wait()
                    until Elevator.State.Players.Value > 1 or Elevator.State.Map.Title.Value ~= Game

                    REvent:FireServer("Elevators", "Leave")
                elseif Elevator.State.Map.Title.Value ~= Game and Elevator.State.Players.Value == 0 and require(Elevator.Settings).Type == Type then
                    REvent:FireServer("Elevators", "Enter", Elevator)

                    task.wait(.5)

                    REvent:FireServer("Elevators", "Leave")
                end
            end

            task.wait()
        end
    end
else
    local State = game:GetService("ReplicatedStorage").State
    local Towers = workspace.Towers

    local StateReplicator;

    for _, Replicator in pairs(game:GetService("ReplicatedStorage").StateReplicators:GetChildren()) do
        if Replicator:GetAttribute("TimeScale") then
            StateReplicator = Replicator;
        end
    end

    local TCount = 0

    Towers.ChildAdded:Connect(function(Tower)
        TCount = TCount + 1

        Tower.Name = TCount
    end)

    System.Vote = function(Mode)
        --[[
            Easy: Normal
            Normal: Fallen
            Insane: Fallen
        ]]

        RFunction:InvokeServer("Difficulty", "Vote", Mode)
    end

    System.PlaceTroop = function(Troop, Wave, Timestamp, PositionX, PositionY, PositionZ, RotationX, RotationY, RotationZ)
        repeat
            task.wait()
        until StateReplicator:GetAttribute("Wave") == Wave and State.Timer.Time.Value <= Timestamp

        RFunction:InvokeServer("Troops", "Place", Troop, {
            ["Rotation"] = CFrame.new(RotationX, RotationY, RotationZ),
            ["Position"] = Vector3.new(PositionX, PositionY, PositionZ)
        })
    end

    System.SkipWave = function(Wave, Timestamp)
        repeat
            task.wait()
        until StateReplicator:GetAttribute("Wave") == Wave and State.Timer.Time.Value <= Timestamp

        RFunction:InvokeServer("Waves", "Skip")
    end

    System.UpgradeTroop = function(TowerIndex, Wave, Timestamp)
        repeat
            task.wait()
        until StateReplicator:GetAttribute("Wave") == Wave and State.Timer.Time.Value <= Timestamp

        RFunction:InvokeServer("Troops", "Upgrade", "Set", {
            ["Troop"] = Towers:FindFirstChild(tostring(TowerIndex))
        })
    end

    System.UseAbility = function(TowerIndex, Ability, Wave, Timestamp)
        repeat
            task.wait()
        until StateReplicator:GetAttribute("Wave") == Wave and State.Timer.Time.Value <= Timestamp

        RFunction:InvokeServer("Troops", "Abilities", "Activate", {
            ["Troop"] = Towers:FindFirstChild(tostring(TowerIndex)),
            ["Name"] = Ability
        })
    end

    System.SetTarget = function(TowerIndex, Wave, Timestamp)
        repeat
            task.wait()
        until StateReplicator:GetAttribute("Wave") == Wave and State.Timer.Time.Value <= Timestamp

        RFunction:InvokeServer("Troops", "Target", "Set", {
            ["Troop"] = Towers:FindFirstChild(tostring(TowerIndex))
        })
    end

    System.SellTroop = function(TowerIndex, Wave, Timestamp)
        repeat
            task.wait()
        until StateReplicator:GetAttribute("Wave") == Wave and State.Timer.Time.Value <= Timestamp

        RFunction:InvokeServer("Troops", "Sell", {
            ["Troop"] = Towers:FindFirstChild(tostring(TowerIndex))
        })
    end
end

return System
