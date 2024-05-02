local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local AttackList = require(script.Parent.AttackList) -- Getting AttackList
local Settings = require(ServerStorage.Main.Settings) -- Getting Settings

local ParticlesFolder = ServerStorage.Particles

local PlayersState = {}

local Cooldown = require(script.Parent.CooldownService)
local Cooldowns = {
	Base = Cooldown.NewCooldown(0.1), 
	Strong = Cooldown.NewCooldown(0.9)
} 

local blockCooldown = Cooldown.NewCooldown(1)

local FistsService = Knit.CreateService{ -- Creating Service
	Name = "FistsService",
	Client = {
		Attack = Knit.CreateSignal(),
		Block = Knit.CreateSignal(),
		Hitted = Knit.CreateSignal()
	}
}

function FistsService:PlaySound(Character, Id)
	local Sound = Instance.new("Sound", Character.HumanoidRootPart)
	Sound.SoundId = `rbxassetid://{Id}`
	Sound.Volume = 0.3 -- changing volume
	Sound.RollOffMaxDistance = 100 -- changing max distance sound
	Sound:Play() -- playing sound
	
	Debris:AddItem(Sound, Sound.TimeLength + 1) -- adding sound to debris and set time to delete, sound length and plus 1
	
	return Sound
end

function FistsService:PlayAnim(Player, id, repeating)
	local NewAnim = Instance.new("Animation")
	NewAnim.AnimationId = `rbxassetid://{id}`

	local anim = Player.Character.Humanoid.Animator:LoadAnimation(NewAnim)
	anim:Play()
	
	return anim
end

-- When Player Triger remote attack

function FistsService.Client:Attack(Player, AttackType)
	if not PlayersState[Player] then return end
	if not Player.Character then return end
	if Player.Character.Humanoid.Health <= 0 then return end
	if not AttackList[AttackType] then return end
	if not Cooldowns[AttackType]:CheckPlayer(Player.UserId) then return end
	if PlayersState[Player].InBlock == true then return end
	if PlayersState[Player].CanDamage == false then return end
	
	local AttackType = AttackList[AttackType]
	
	-- Anim Playing
	local RandomAnim = AttackType.Anims[math.random(1,#AttackType.Anims)]
	FistsService:PlayAnim(Player, RandomAnim)
	
	-- Sound Playing
	local Sound = FistsService:PlaySound(Player.Character, 5835032207) -- playing sound id
	Sound.PlaybackSpeed = 1 + math.random(1, 10) * 0.1 -- changing sound speed
	
	-- Finding player to hit
	local HitPlayer = FistsService:MakeColliderAndFind(Player.Character)
	if not HitPlayer then return end
	

	-- Playing Hit Sound
	FistsService:PlaySound(HitPlayer, AttackType.HitSound[math.random(#AttackType.HitSound)])

	-- Main Function
	local Multiple = 1
	if PlayersState[Players:GetPlayerFromCharacter(HitPlayer)] then
		if PlayersState[Players:GetPlayerFromCharacter(HitPlayer)].InBlock == true then
			Multiple = 0.1
			if AttackType == "Strong" then Multiple = 0.25 end
		end
		if PlayersState[HitPlayer].CanDamage == false then
			return
		end
	end

	task.spawn(function()
		HitPlayer.Humanoid:TakeDamage(math.random(AttackType.Damage.Min, AttackType.Damage.Max) * Multiple)
		HitPlayer.HumanoidRootPart:ApplyImpulse(Player.Character.HumanoidRootPart.CFrame.LookVector * (150 * AttackType.Impulse * Multiple))
		FistsService:CreateBlood(HitPlayer, Player.Character.HumanoidRootPart.CFrame.LookVector)
	end)
	
	-- Checking player killed another player
	FistsService:CheckKill(Player, HitPlayer)
end

function FistsService.Client:Block(Player)
	if not blockCooldown:CheckPlayer(Player.UserId) then return end -- checking ready player or not
	
	local PlayerInTable = PlayersState[Player] -- finding player into the table with state
	if not PlayerInTable  then return end
	
	PlayerInTable.InBlock = not PlayerInTable.InBlock -- set the value to the opposite of the one given
	Player.Character.InBlock.Value = PlayerInTable.InBlock -- Set visual bool
	
	local function TurnOff()
		PlayerInTable.BlockAnim:Stop()
		PlayerInTable.Coroutine = nil -- clearing
		Player.Character.InBlock.Value = false
		PlayerInTable.InBlock = false
	end
	
	if PlayerInTable.InBlock then
		PlayerInTable.BlockAnim = FistsService:PlayAnim(Player,Settings.BlockAnim)
		PlayerInTable.Coroutine = coroutine.create(function()-- creatin coroutine
			task.wait(5)
			TurnOff()
		end)	
		coroutine.resume(PlayerInTable.Coroutine) -- starting coroutine
	elseif not PlayerInTable.InBlock and PlayerInTable.BlockAnim ~= nil then
		coroutine.close(PlayerInTable.Coroutine) -- stopping coroutine
		TurnOff()
	end
end

-- Creating collider to find player to hit

function FistsService:MakeColliderAndFind(Character)
	local ColliderCFrame = Character.HumanoidRootPart.CFrame * CFrame.new(Vector3.new(0,0,-2))
	local ColliderSize = Settings.ColliderSize
	
	local Overlap = OverlapParams.new() -- Creating Overlap
	Overlap.FilterType = Enum.RaycastFilterType.Exclude -- Settings type on exclude
	Overlap.FilterDescendantsInstances = {Character} -- set exluding our player
	
	local Bounds = workspace:GetPartBoundsInBox(ColliderCFrame, ColliderSize, Overlap)
	
	if Settings.Debug then
		local DebugPart = Instance.new("Part", workspace) -- Creating part for debug
		DebugPart.CanCollide = false
		DebugPart.Anchored = true
		DebugPart.CFrame = ColliderCFrame
		DebugPart.Size = ColliderSize
		Debris:AddItem(DebugPart, 0.06) -- Adding part to debris for destroy it through 0.06 s
	end
	
	for _, inctance in Bounds do
		if inctance.Parent:FindFirstChild("Humanoid") and inctance.Parent.Humanoid.Health > 0 then -- if hitted player died skip
			return inctance.Parent
		end
	end
end


function FistsService:CheckKill(Player, Hited)
	if Hited.Humanoid.Health > 0 then return end -- if out player killed him then
	
	Player.leaderstats.Kills.Value += 1
	
	FistsService:CreateBloodPart(Hited, Vector3.new(8,0.05,8))
	
	local KilledPlayer = Players:GetPlayerFromCharacter(Hited)
	if not KilledPlayer then return end
	
	KilledPlayer.leaderstats.Deaths.Value += 1
end

-- Create blood effect on baseplate

function FistsService:CreateBloodPart(Character, Size_Set)
	local Params = RaycastParams.new() -- Creating Params
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Character}

	local rayInfo = workspace:Raycast(Character.HumanoidRootPart.Position, Vector3.new(0,-5,0),Params) -- Making raycast with out params
	if rayInfo then -- if raycast finding anything then creating blood part
		if rayInfo.Instance then
			local BloodPart =  ParticlesFolder.BloodPart:Clone()
			BloodPart.Parent = workspace
			BloodPart.Position = rayInfo.Position

			TweenService:Create(BloodPart, TweenInfo.new(2.5, Enum.EasingStyle.Exponential), {Size = Size_Set or Vector3.new(math.random(4,6),0.05,math.random(4,6))}):Play()

			Debris:AddItem(BloodPart, 9) 
			
			task.wait(7)
			TweenService:Create(BloodPart, TweenInfo.new(2.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Vector3.new(0,0,0)}):Play()
		end
	end
end

-- Create blood particles on hit player

function FistsService:CreateBlood(Character, LookVector)
	if Character.Humanoid.Health <= 0 then return end
	
	local Blood = ParticlesFolder.Blood:Clone()
	Blood.Parent = workspace
	Blood.Position = Character.HumanoidRootPart.Position - LookVector*1 -- we set the position so that it is closer to the side of the player who hit
	
	local Weld = Instance.new("WeldConstraint", workspace) -- Creating weld for weld particle to character
	Weld.Part0 = Character.HumanoidRootPart
	Weld.Part1 = Blood
	
	Debris:AddItem(Blood, 1) -- add blood to debris
	Debris:AddItem(Weld, 1) -- Add weld to debris
	
	if Character.Humanoid.Health <=10  then -- If character health <= 10 calling creating blood part
		task.spawn(function()
			FistsService:CreateBloodPart(Character) 
		end)
	end	
	
	task.wait(0.25)
	Blood.Attachment.Blood.Enabled = false
end

-- Player interaction

function FistsService.PlayerLeaved(Player)
	if not PlayersState[Player] then return end
	PlayersState[Player] = nil
end

function FistsService.PlayerJoin(Player : Player)
	PlayersState[Player] = { -- add player in table
		InBlock = false,
		CanDamage = true
	}	
	
	Player.CharacterAdded:Connect(function(Character)
		-- Creating inblock visual
		local InBlockVisual = Instance.new("BoolValue", Character)
		InBlockVisual.Name = "InBlock"
		InBlockVisual.Value = false
		--Spawn Shield
		local shield_effect = ParticlesFolder["effect shiled"].Ground2:Clone()
		shield_effect.Parent = Character.HumanoidRootPart
		Debris:AddItem(shield_effect, 6)
		
		PlayersState[Player].CanDamage = false
		task.wait(5)
		PlayersState[Player].CanDamage = true
		
		shield_effect.Swirl.Enabled = false
	end)
	
	-- Creating leaderstats
	local leaderstats = Instance.new("Folder", Player)
	leaderstats.Name = "leaderstats"
	local Kills = Instance.new("NumberValue", leaderstats)
	Kills.Name = "Kills"
	local Deaths = Instance.new("NumberValue", leaderstats)
	Deaths.Name = "Deaths"
end

function FistsService:KnitInit()
	for _, plr in Players:GetPlayers() do FistsService.PlayerJoin(plr) end
	Players.PlayerAdded:Connect(FistsService.PlayerJoin)
	Players.PlayerRemoving:Connect(FistsService.PlayerLeaved)
end

return FistsService
