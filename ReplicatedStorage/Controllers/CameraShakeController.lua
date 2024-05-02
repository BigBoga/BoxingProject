local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Blur = game:GetService("Lighting").Blur

local player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CameraShakeController = Knit.CreateController{
	Name = "CameraShakeController"
}

function CameraShakeController:Shake(TimeShake, Stregth)
	if not player.Character then return end
	
	local Humanoid = player.Character:WaitForChild("Humanoid")
	
	local TimeStarted = tick()
	
	repeat	
		local Val = tick() * 25 * Stregth -- getting val using tick for smooth
		
		Humanoid.CameraOffset = Vector3.new( 
			math.sin(Val) * 0.1,
			math.sin(Val) * 0.1,
			math.cos(Val) * 0.1
		)
		
		Blur.Size = math.random(5,20) * 0.5 * Stregth 
		
		task.wait()
	until tick() - TimeStarted > TimeShake

    -- Reset
	Humanoid.CameraOffset = Vector3.new(0,0,0)
	Blur.Size = 1
end

return CameraShakeController
