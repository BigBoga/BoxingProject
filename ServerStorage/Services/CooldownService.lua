local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Players = game:GetService("Players")

local CooldownService = {}
CooldownService.__index = CooldownService

function CooldownService:CheckPlayer(UserId)
	local player = self.Players[UserId]
	if not player then return end
	
	if tick() - player >= self.Time  then -- If last trig tick - current tick more than cooldown then return true
		self.Players[UserId] = tick() -- set last trig tick
		return true
	else
		return false
	end
end

function CooldownService:PlayerJoin(plr)
	self.Players[plr.UserId] = tick() -- Set Tick
end

function CooldownService.NewCooldown(Time)
	local self = setmetatable({}, CooldownService) -- Creating metatable
	
	self.Players = {} -- Creating table with players
	self.Time = Time -- creating variable with cooldown time
	
	for _, plr in Players:GetPlayers() do self:PlayerJoin(plr) end -- getting all players
	
	Players.PlayerAdded:Connect(function(plr) -- Connecting added event
		self:PlayerJoin(plr)
	end)
	
	return self
end



return CooldownService
