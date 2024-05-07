local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local AttackList = require(script.AttackList) -- Getting AttackList
local Settings = require(ServerStorage.Main.Settings) -- Getting Settings

local ParticlesFolder = ServerStorage.Particles
local Fireball = ServerStorage.Main.Fireball

local PlayersState = {}

local Cooldown = require(script.Parent.CooldownService)
local Cooldowns = {
	Base = Cooldown.NewCooldown(0.1), 
	Strong = Cooldown.NewCooldown(0.9)
} 

local blockCooldown = Cooldown.NewCooldown(1)
local fireBallCooldown = Cooldown.NewCooldown(1)

local FistsService = Knit.CreateService{ -- Creating Service
	Name = "FistsService",
	Client = {
		Attack = Knit.CreateSignal(),
		Block = Knit.CreateSignal(),
		Hitted = Knit.CreateSignal(),
		FireBall = Knit.CreateSignal(),
		Shake = Knit.CreateSignal()
	}
}

function FistsService:PlaySound(Character, Id)
	--We create a sound within the character so that the sound doesn't play throughout the entire map
	local Sound = Instance.new("Sound", Character.HumanoidRootPart)
	Sound.SoundId = `rbxassetid://{Id}`
	Sound.Volume = 0.3 -- changing volume
	Sound.RollOffMaxDistance = 100 -- changing max distance sound
	Sound:Play() -- playing sound
	
	Debris:AddItem(Sound, Sound.TimeLength + 1) -- adding sound to debris and set time to delete, sound length and plus 1
	
	return Sound
end

function FistsService:PlayAnim(Player, id)
	local NewAnim = Instance.new("Animation")
	NewAnim.AnimationId = `rbxassetid://{id}`

	local anim = Player.Character.Humanoid.Animator:LoadAnimation(NewAnim)
	anim:Play()
	
	return anim
end

-- When Player Triger remote attack

function FistsService.Client:Attack(Player, AttackType)
	if not Cooldowns[AttackType]:CheckPlayer(Player.UserId) then return end
	if not PlayersState[Player] then return end  -- We check if the player is in the state table.
	if not Player.Character then return end -- We check if the character is absent from our player
	if Player.Character.Humanoid.Health <= 0 then return end --We check if the character is alive
	if not AttackList[AttackType] then return end -- We check if such a attack is in the list
	if PlayersState[Player].InBlock == true then return end -- We check if the character is in a blocked state
	if PlayersState[Player].CanDamage == false then return end -- We check if it's possible to damage our player. If not, we return
	if PlayersState[Player].InState == true then return end
	
	--We create a variable for the player's selected attack.
	local AttackType = AttackList[AttackType]
	
	-- Anim Playing // We search for a random animation in the selected type of attack
	local RandomAnim = AttackType.Anims[math.random(1,#AttackType.Anims)]
	FistsService:PlayAnim(Player, RandomAnim)
	
	-- Sound Playing // We vary the playback speed to make it seem like different sounds
	local Sound = FistsService:PlaySound(Player.Character, 5835032207) -- playing sound id
	Sound.PlaybackSpeed = 1 + math.random(1, 10) * 0.1 -- changing sound speed
	
	-- Let's use our function and find some player
	local HitPlayer = FistsService:MakeColliderAndFind(Player.Character)
	if not HitPlayer then return end
	

	-- Playing Hit Sound // We search for a random hit sound in the selected type of attack
	FistsService:PlaySound(HitPlayer, AttackType.HitSound[math.random(#AttackType.HitSound)])

	-- If the player we are hitting is in a blocking state, we reduce the damage power. If the player delivers a strong strike, we decrease the damage slightly less
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

	--We create a function in the task spawn so that the script immediately reaches the function with the kill check
	task.spawn(function()
		HitPlayer.Humanoid:TakeDamage(math.random(AttackType.Damage.Min, AttackType.Damage.Max) * Multiple)
		HitPlayer.HumanoidRootPart:ApplyImpulse(Player.Character.HumanoidRootPart.CFrame.LookVector * (150 * AttackType.Impulse * Multiple))
		FistsService:CreateBlood(HitPlayer, Player.Character.HumanoidRootPart.CFrame.LookVector)
	end)
	
	-- Checking player killed another player 
	FistsService:CheckKill(Player, HitPlayer)
end

function FistsService.Client:FireBall(Player)
	if not fireBallCooldown:CheckPlayer(Player.UserId) then return end
	if not PlayersState[Player] then return end  -- We check if the player is in the state table.
	if not Player.Character then return end -- We check if the character is absent from our player
	if Player.Character.Humanoid.Health <= 0 then return end --We check if the character is alive
	if PlayersState[Player].InState == true then return end
	if PlayersState[Player].InBlock == true then return end
	
	PlayersState[Player].InState = true
	
	local dir = Player.Character.HumanoidRootPart.CFrame.LookVector * 300
	
	--We set up parameters for our raycast, switch to exception mode, and add our player to the list. To prevent the raycast from interacting with our player.
	local RayParam = RaycastParams.new()
	RayParam.FilterType = Enum.RaycastFilterType.Exclude
	RayParam.FilterDescendantsInstances = {Player.Character}
	
	local RayInfo = workspace:Raycast(Player.Character.HumanoidRootPart.Position, dir, RayParam)

	--If the raycast finds any object, and if there is a humanoid in the parent of this object, then we proceed with the function
	if not RayInfo then PlayersState[Player].InState = false return end
	--We have two possible scenarios: if the raycast collides with an accessory, then its parent will be the accessory. Therefore, we need to search in the parent parent
	local hum = RayInfo.Instance.Parent:FindFirstChild("Humanoid") or RayInfo.Instance.Parent.Parent:FindFirstChild("Humanoid")
	if not hum then return end
	
	--We trigger an event to initiate camera shake.
	FistsService.Client.Shake:Fire(Player)

	--We clone our fireball. Then, we create the first attachment and set its parent to our fireball. Subsequently, we create the second attachment, and its parent will be the object hit by the raycast.
	local Fireball_Clone = Fireball:Clone()
	Fireball_Clone.Parent = workspace
	Fireball_Clone.Sphereyellow.CFrame = Player.Character.HumanoidRootPart.CFrame * CFrame.new(Vector3.new(0,0,-2))

	local Attachment1 = Instance.new("Attachment", Fireball_Clone.Sphereyellow)
	local Attachemnt2 = Instance.new("Attachment", RayInfo.Instance)

	--We create an align position so that our object smoothly flies towards the target. This is why we created attachments, because align position only accepts attachments.
	local AlignPos = Instance.new("AlignPosition", Fireball_Clone.Sphereyellow)
	AlignPos.Attachment0 = Attachment1
	AlignPos.Attachment1 = Attachemnt2
	
	--We use the functions we created earlier to play a sound and trigger an animation.
	FistsService:PlayAnim(Player, 17415784526)
	FistsService:PlaySound(Player.Character, 1544022435)
	
	--
	-- every heartbeat, we check the position of our ball relative to the target. As soon as the ball reaches its destination,
	-- we disconnect an event, remove our ball, and deal damage to our enemy.
	--
	
	local hearbeat
	hearbeat = RunService.Heartbeat:Connect(function()
		if (Fireball_Clone.Sphereyellow.Position - RayInfo.Instance.Position).Magnitude < 5 then
			hearbeat:Disconnect()
			Fireball_Clone:Destroy()	
			Attachemnt2:Destroy()
			hum:TakeDamage(math.random(10,25))
		end
	end)
	
	PlayersState[Player].InState = false
end

function FistsService.Client:Block(Player)
    --
    -- We check our player for cooldown and whether they are in the table of player states. 
    -- If yes, we set the value in this table indicating that the player is in a blocked state, or vice versa.
    --
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
	
	--
	--We create a coroutine so that we can later suspend the function to avoid a bug where the block
	--is removed and placed again, preventing it from being removed again
	--
	
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

-- We create variables to simplify the work. These variables store the position slightly offset from the player, as well as the collider size, which is defined in the settings.
function FistsService:MakeColliderAndFind(Character)
	local ColliderCFrame = Character.HumanoidRootPart.CFrame * CFrame.new(Vector3.new(0,0,-2))
	local ColliderSize = Settings.ColliderSize
	
	--
	--We create parameters for our collider and set an option to make our player not visible to the collider. 
	--If the collider detects any player, we stop the loop and return the character of that player.
	--Also, if debug mode is enabled, we create a debug object with parameters from our variables.
	--
	
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


-- If the person we hit runs out of health, we increment the kill count in the statistics by one
function FistsService:CheckKill(Player, Hited)
	if Hited.Humanoid.Health > 0 then return end -- if out player killed him then
	
	Player.leaderstats.Kills.Value += 1
	
	FistsService:CreateBloodPart(Hited, Vector3.new(8,0.05,8))
	
	-- If we find a player from the character, we increment their death count by one.
	local KilledPlayer = Players:GetPlayerFromCharacter(Hited)
	if not KilledPlayer then return end
	
	KilledPlayer.leaderstats.Deaths.Value += 1
end

-- Create blood effect on baseplate

function FistsService:CreateBloodPart(Character, Size_Set)
	-- Here we set up parameters for the raycast and configure it so that the raycast doesn't detect our player.
	local Params = RaycastParams.new() -- Creating Params
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Character}

	-- We launch a raycast. If the raycast detects any object, and that object fits our parameters, we create blood at the position of the raycast hit.
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
	--
	--We clone the blood particle and attach it to the character we are hitting. 
	--Then we add a weld and the particle to the debris to be removed after the specified time.
	--
	local Blood = ParticlesFolder.Blood:Clone()
	Blood.Parent = workspace
	Blood.Position = Character.HumanoidRootPart.Position - LookVector*1 -- we set the position so that it is closer to the side of the player who hit
	--We create a weld to attach our character to the particle
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
		CanDamage = true,
		InState = false
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
