local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local MainGUI = player.PlayerGui:WaitForChild("ScreenGui")
local Vignette = MainGUI:WaitForChild("Vignette")

local Mouse = player:GetMouse()
local InputService = game:GetService("UserInputService")

local FistsController = Knit.CreateController{
	Name = "FistsController"
}

local FistsService, CameraShakeController


function FistsController:ConnectInput()
	local Started,Render

    -- Punch INput

	Mouse.Button1Down:Connect(function()
		if player.Character.InBlock.Value == true then return end
		
		Started = tick()
		
		Render = RunService.RenderStepped:Connect(function()
			Vignette.ImageTransparency = math.clamp(1 - (tick() - Started),0,1 )
		end)
	end)
	
	Mouse.Button1Up:Connect(function()
		Render:Disconnect()
		if player.Character.InBlock.Value == true then return end
		Vignette.ImageTransparency = 1
		
		local AttackType = "Base"
		
		if  tick() - Started > 1 then AttackType = "Strong" end
		FistsService:Attack(AttackType)
		CameraShakeController:Shake(0.2, AttackType == "Strong" and 2 or 1)
	end)
	
	-- Block Input
	
	InputService.InputBegan:Connect(function(Input)
		if Input.KeyCode == Enum.KeyCode.X then
			FistsService:Block()
		end
	end)
end

function FistsController:KnitInit()
	FistsService = Knit.GetService("FistsService") -- Getting Service
	CameraShakeController = Knit.GetController("CameraShakeController")
	self:ConnectInput()
end

return FistsController
