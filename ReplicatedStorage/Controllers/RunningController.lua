local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local InputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer

local RunningController = Knit.CreateController{
	Name = "RunningController"
}

local function SetSpeed(input, gameprocssed, speed)
	if gameprocssed then return end
	if not player.Character then return end -- if player doesnt have player return
	if input.KeyCode ~= Enum.KeyCode.LeftShift then return end -- if not left shift input return
	
	player.Character.Humanoid.WalkSpeed = speed -- changing walk speed
end

function RunningController:KnitInit()
	InputService.InputBegan:Connect(function(input, gameprocssed)
		SetSpeed(input, gameprocssed, 22)
	end)
	
	InputService.InputEnded:Connect(function(input, gameprocssed)
		SetSpeed(input, gameprocssed, 16)
	end)
end

return RunningController
