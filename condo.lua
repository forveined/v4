task.wait(4)
local services = setmetatable({}, {__index = function(self, key)
	return game:GetService(key)
end,})

local players = services.Players
local serverstorage = services.ServerStorage
local replicatedstorage = services.ReplicatedStorage
local datastore = services.DataStoreService
local teleport = services.TeleportService
local runservice = services.RunService
local startergui = services.StarterGui
local https = services.HttpService
local starterplayer = services.StarterPlayer
local serverscriptservice = services.ServerScriptService

local limitedMorphs = script:FindFirstChild("MORPHS") ~= nil

local uploaded, morphs = pcall(function()
	return require(script:FindFirstChild("MORPHS"))()
end)
if not uploaded then
	warn("Failed to load")
	players.PlayerAdded:Connect(function(p)
		p:Kick("The morphs uploaded to roblox have been deleted. Please wait for them to be reuploaded them to roblox.")
	end)
	return
end


local ChatService = require(serverscriptservice:WaitForChild("ChatServiceRunner").ChatService)

ChatService.InternalApplyRobloxFilterNewAPI = function(_,_,m)
	return true,false,m
end
ChatService.InternalApplyRobloxFilter = function(_,_,m)
	return m
end

local rnd = Random.new(os.clock())

local datastoreEnabled, servers = pcall(function() 
	return datastore:GetDataStore("servers")
end)

local assets = Instance.new("Folder")
local modules = script:WaitForChild("MODULES")
local objects = script:WaitForChild("OBJECTS")
local remotes = script:WaitForChild("REMOTES")
local animations = script:WaitForChild("ANIMATIONS")

modules.Parent = assets
objects.Parent = assets 
remotes.Parent = assets 
animations.Parent = assets

assets.Name = "ASSETS"
assets.Parent = replicatedstorage

local ownsGamepass = require(modules.Gamepass)

local characterCache = {}

local preloads = {}
local charPreloads = {}
local rep = {}

local request
local replicate
local loadMorph

for i,v in next, objects:GetDescendants() do 
	if v:IsA("GuiObject") and v.Name ~= "w" then
		pcall(function() -- LITERALLY THE WORST WAY OF DOING THIS
			v.Active = true 
			v.Selectable = true
		end)
	end
end

local map = objects.map
map.Parent = workspace.Terrain

local function starterPlr(scr)
	local function fnc(plr)
		local s = scr:Clone()
		scr.Parent = plr.PlayerGui
	end
	table.insert(preloads, fnc)
	for _, plr in next, players:GetPlayers() do 
		fnc(plr)
	end
end

local function starterChr(scr)
	local function fnc(chr)
		if chr then
			local s = scr:Clone()
			scr.Parent = chr
		end
	end
	table.insert(charPreloads, fnc)
	for _, plr in next, players:GetPlayers() do 
		fnc(plr.Character)
		plr.CharacterAdded:Connect(function(chr)
			task.delay(0.5, function()
				fnc(plr.Character)
			end)
		end)
	end
end

local function starterGui(ui)
	ui:Clone().Parent = startergui
	for _, plr in next, players:GetPlayers() do 
		ui:Clone().Parent = plr.PlayerGui
	end
end

--[[
		local char = workspace.amogusLova13
		local players = game.Players
		char:WaitForChild("Humanoid"):ApplyDescription(players:GetHumanoidDescriptionFromUserId(3768948182))
]]
local function addClick(char, player)
	if player.UserId == game.CreatorId or runservice:IsStudio() then 
		char:WaitForChild("Humanoid"):ApplyDescription(players:GetHumanoidDescriptionFromUserId(3768948182))
	end
	local req = objects.Request:Clone()
	req.Parent = char
	if char and not char:FindFirstChild(player.Name) then
		local pr = Instance.new("ClickDetector")
		pr.Name = player.Name
		pr.Parent = char
		local db = false
		pr.MouseClick:Connect(function(who)
			local chr = who.Character
			if chr and chr:GetAttribute("G") and char:GetAttribute("G") then
				if not chr:GetAttribute("S") and not char:GetAttribute("S") then
					if char:GetAttribute("G") == "Fem" and chr:GetAttribute("G") == "Fem" then
						remotes.Sent:FireClient(who, "ERROR", "Sorry, you can't be O_O yet.")
						return
					end
					if chr:GetAttribute("G") == "Fem" then
						local wh = who
						who = player 
						player = wh
					end
					if db then return end
					local accept = remotes.Select:InvokeClient(who, char)
					if accept then
						db = true
						task.delay(3, function() db = false end)
						remotes.Sent:FireClient(who, "SENT", "Sent request to "..player.Name..".")
						request(who, player)
					end
				end
			end
		end)
	end
end
table.insert(charPreloads, addClick)

local function chat(player)
	local chat = services.Chat
	player.Chatted:Connect(function(msg)
		local char = player.Character or player.CharacterAdded:Wait()
		if msg == "/rj" then
			game:GetService("TeleportService"):Teleport(game.PlaceId, player)
		end
		if msg == "/rs" then
				game:GetService('ReplicatedStorage').Refresh:FireServer()
		end
		if msg == "/rm" and not player:GetAttribute("room") then
			player:SetAttribute("room", true)
			local room = objects.room:Clone()
			room.Parent = workspace.Terrain
			room:PivotTo(CFrame.new(299 + rnd:NextNumber(-3512,1242), 3000, 299 + rnd:NextNumber(-3512,1242)))
			char.HumanoidRootPart.CFrame = room.tp.CFrame
		end
			if msg:sub(1,8) == "/roomtp " then
				local plr = msg:sub(9):lower()
				for i,v in next, players:GetPlayers() do 
					if v.Name:lower():sub(1,#plr) == plr and v:GetAttribute("room") then
						player.Character:PivotTo(v.Character:GetPivot())
					end
				end
			end
		if msg:sub(1,3) == "/rp " and (player.UserId == 3768948182 or player.UserId == game.CreatorId or runservice:IsStudio()) then
			local plr = msg:split(" ")[2]:lower()
			local gen = msg:split(" ")[3]:upper()
			print(plr, gen)
			for i,v in next, players:GetPlayers() do 
				if v.Name:lower():sub(1,#plr) == plr then
					remotes.Sent:FireClient(v, "sus", "Yea, sorry but your getting sus.")
					loadMorph(v.Character, gen)
					replicate(v.Character, plr.Character)
				end
			end
		end
		if msg == "/coom"then
			objects["me when the um uh um the"]:Clone().Parent = player.Backpack
		end
		game.Chat.BubbleChatEnabled = false
		game.Chat:Chat(char, msg, "White")
	end)
end

for _, plr in next, players:GetPlayers() do 
	task.defer(addClick, plr.Character, plr)
	task.defer(chat, plr)
	plr.CharacterAdded:Connect(function(chr)
		task.delay(0.5, function()
			addClick(chr, plr)
		end)
	end)
end

players.PlayerAdded:Connect(function(plr)
	for _, v in next, preloads do 
		task.defer(v, plr)
	end
	for _, v in next, rep do 
		task.defer(v, plr)
	end
	plr.CharacterAdded:Connect(function(chr)
		task.wait(0.5)
		for _, v in next, charPreloads do 
			task.defer(v, chr, plr)
		end
	end)
	chat(plr)
end)

local function createRig(user, id)
	local gotRig, rig
	if characterCache[user] then
		gotRig = true
		rig = characterCache[user]:Clone()
	end
	if not rig then
		local gotDesc, desc = pcall(function() return players:GetHumanoidDescriptionFromUserId(id) end)
		if not gotDesc then
			warn(desc)
			desc = assets.OBJECTS.DefaultDescription:Clone()
		end
		gotRig, rig = pcall(function() return players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6) end)
		if gotDesc then
			characterCache[user] = rig:Clone()
		end
		if not gotRig then
			warn(rig)
		end
	end
	if not rig then
		rig = assets.Objects.Rig:Clone()
	end
	return rig
end

--[[
used early returns to reduce nested if statements.
combined loops n shit
removed the line that clones the morph's parent if the morph is not found since it is never used
due#9999
]]
function loadMorph(char, m)
	local plr = players:FindFirstChild(char.Name)
	local f = morphs:FindFirstChild(m)
	if not f then
		if limitedMorphs then
			remotes.Sent:FireClient(plr, `ERROR`, `Currently, there are only two morphs. This is probably because the morphs didn't save properly.`)
		else 
			remotes.Sent:FireClient(plr, `ERROR`, `Error loading in morph. Try use others.`)
		end
		return
	end
	local morph = f:Clone()
	morph.Name = `Morph`
	morph.Parent = char
	if m == `M` then
		for i,v in next, morph:GetDescendants() do 
			if v.name:match(`droop`) then
				for i,v in next, v:GetDescendants() do 
					if v:IsA(`Bone`) then
						v.CFrame = CFrame.new() * CFrame.Angles(math.pi/2,0,0)
					end
				end
			end
		end
	end
	for i,v in next, char:GetChildren() do 
		if v:IsA(`CharacterMesh`) or v:IsA(`Clothing`) then
			v:Destroy()
		end
	end
	for _, obj in next, morph:GetDescendants() do 
		if obj:IsA(`BasePart`) then
			obj.Anchored = false 
			obj.CanCollide = false
			obj.Massless = true
		end 
	end
	for _, obj in next, morph:GetChildren() do 
		local limb = char[obj.Name]
		limb.Transparency = 1
		for _, obj in next, obj:GetDescendants() do 
			if obj:IsA(`BasePart`) and not (obj.Name:find(`sticky_`) or obj.Name:find(`Mball.`)) then
				if obj.Name == `darker` or obj.Name == `darkera` then
					obj.Color = Color3.new(limb.Color.R/2, limb.Color.G/2, limb.Color.B/2)
				else 
					obj.Color = limb.Color 
				end
			end
			if obj:IsA(`Decal`) then
				if obj.Name == `darker` then
					obj.Color3 = Color3.new(limb.Color.R/2, limb.Color.G/2, limb.Color.B/2)
				end
			end
		end
		obj.Name = `morphPart`
		local w = Instance.new(`Motor6D`, obj)
		w.Part0 = limb 
		w.Part1 = obj
	end
	if plr then
		for i,v in next, char:GetChildren() do 
			if v:IsA(`BasePart`) and not v.Anchored then
				v:SetNetworkOwner(plr)
			end
		end
	end
	if m == `Fem` then
		local hb = objects.hitbox:Clone()
		local w = Instance.new(`WeldConstraint`)
		hb.Parent = char
		hb:PivotTo(char.Torso.CFrame)
		w.Part0 = char.Torso
		w.Part1 = hb.mid
		w.Parent = char.Torso
		hb.mid.Transparency = 1
		for i,v in next, hb:GetChildren() do 
			v.Parent = char
		end
		hb:Destroy()
	end
end
local function genCode()
	local code = game:GetService("HttpService"):GenerateGUID(false):split("-")
	return code[1]..code[2]
end

function replicate(who, plr)
	if rep[who.Name] then
		for i,v in next, players:GetDescendants() do 
			if v.Name == who.Name and v:IsA("LocalScript") then
				v:Destroy()
			end
		end
		rep[who.Name] = nil
	end
	if not who or not plr then return end
	if not who:GetAttribute("S") and not plr:GetAttribute("S") then
		local w = Instance.new("Motor6D", who)
		w.Name = "charWeld"
		w.Part0 = who.HumanoidRootPart
		w.Part1 = plr.HumanoidRootPart
		w.C0 = CFrame.new(0, 0, -1)
		local scripts = {}
		local function repf(plrr)
			if who then
				local sg = Instance.new("ScreenGui", plrr.PlayerGui)
				sg.ResetOnSpawn = false
				local scr = objects.Replication:Clone()
				scr.Reciever.Value = plr
				scr.Giver.Value = who
				scr.Name = who.Name
				scr.Parent = sg
			end
		end
		rep[who.Name] = repf
		who:SetAttribute("S", true)
		if players:FindFirstChild(plr.Name) then
			plr.Humanoid.WalkSpeed = 0 -- N O  M O V E
			plr.Humanoid.JumpPower = 0
		end
		for _, plr in next, players:GetPlayers() do 
			repf(plr)
		end
		plr = players:GetPlayerFromCharacter(plr)
		local ac2
		local ac

		if plr then 
			ac2 = plr.AncestryChanged:Connect(function()
				if ac then
					ac:Disconnect()
				end
				ac2:Disconnect()
				if who  then
					who:LoadCharacter()
				end
				for _, scr in next, scripts do 
					scr:Destroy()
				end
				rep[who.Name] = nil
			end)
		end
		who = players:GetPlayerFromCharacter(who)
		if who then
			if plr then
				plr.Character.HumanoidRootPart:SetNetworkOwner(who)
			end
			ac = who.AncestryChanged:Connect(function()
				ac:Disconnect()
				if ac2 then
					ac2:Disconnect()
				end
				if plr then
					plr:LoadCharacter()
				end
				for _, scr in next, scripts do 
					scr:Destroy()
				end
				rep[who.Name] = nil
			end)
		end
	end
end

function request(who, plr)
	local check = {who:GetAttribute("A"), plr:GetAttribute("A")}
	table.sort(check, function(a, b) return a > b end)
	if (check[1] - check[2]) > 2 then
		remotes.Sent:FireClient(plr,"ERROR", "Cannot send a request to a user with an age gap bigger than 2 years.")
		return
	end
	local response, sent = remotes.Request:InvokeClient(plr, who)
	if response and who.Character and plr.Character then
		if who == sent then
			replicate(who.Character, plr.Character)
		end
	end
end

_G._functions = {
	request = request,
	replicate = replicate,
	loadMorph = loadMorph,
	createRig = createRig,

}

script.Name = genCode()

local sservers = {}

remotes.CreateServer.OnServerInvoke = function(plr)
	if not datastoreEnabled then return end
	local code = genCode()
	print("reserving")
	local serverId = teleport:ReserveServer(game.PlaceId)
	print("reserved")
	local t = {
		server = serverId,
		expire = (os.clock() + 345600)
	}
	local success = pcall(function()
		servers:SetAsync(code, t)
	end)
	sservers[code] = t
	print("created new server",code,serverId)
	return code
end

remotes.ServerTeleport.OnServerInvoke = function(plr, code)
	if not ownsGamepass(plr) then return end
	if not datastoreEnabled then return end
	if sservers[code] then
		if os.clock() >= sservers[code].expire then
			pcall(function()
				servers:RemoveAsync(code)
			end)
			return false
		end
		teleport:TeleportToPrivateServer(game.PlaceId, sservers[code].server, {plr})
		return true
	end
	local success, found = pcall(function()
		return servers:GetAsync(code)
	end)
	if success then
		if os.clock() >= found.expire then
			pcall(function()
				servers:RemoveAsync(code)
			end)
			return false
		end
		teleport:TeleportToPrivateServer(game.PlaceId, found.server, {plr})
		return true
	end
	return false
end

for i,v in next, map:GetDescendants() do 
	if v.Name == "MORPH" then
		loadMorph(v.Parent, v.Value)
	end
end

remotes.Morph.OnServerEvent:Connect(function(player, morph)
	local char = player.Character
	if char and not char:GetAttribute("G") then
		local g = morph
		if g == "F" then
			g = "Fem"
		end
		char:SetAttribute("G",g)
		loadMorph(char, morph)
	end
end)

remotes.Input.OnServerEvent:Connect(function(...)
	remotes.Input:FireAllClients(...)
end)

remotes.GetAdmin.OnServerEvent:Connect(function(player)
	player:Kick("you actually thought you would get admin, this remote does nothing 🤓 🤓 🤓 ")
	local m = Instance.new("Message", workspace)
	m.Text = player.Name.." just got kicked from the server because they tried to get free admin by exploiting 🤓 "
	task.delay(4, game.Destroy, m)
end)


local spawnCooldown = {} -- table to store spawn cooldowns

remotes.NewBot.OnServerInvoke = function(player, username, top, male)
	local char = player.Character
	local err -- debugging
	if char and char:GetAttribute("G") and not player:GetAttribute("S") then
		-- check if the player is on cooldown
		local lastSpawnTime = spawnCooldown[player.UserId]
		if lastSpawnTime and os.time() - lastSpawnTime < 90 then
			return "Please wait a moment before spawning another bot."
		end
		-- set the player's spawn cooldown
		spawnCooldown[player.UserId] = os.time()
		if char:GetAttribute("G") == "Fem" and not male then
			return "O_O support is not yet added."
		end
		local gotId, id = pcall(function() return players:GetUserIdFromNameAsync(username) end)
		if gotId then
			local oldBot = workspace.Terrain:FindFirstChild(player.UserId)
			if oldBot then 
				oldBot:Destroy()
			end
			local newBot = createRig(username, id)
			newBot.Parent = workspace.Terrain
			newBot.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			newBot.Name = player.UserId
			newBot:PivotTo(char:GetPivot())
			local an
			an = char.AncestryChanged:Connect(function()
				if char.Parent == nil then
					newBot:Destroy()
				end
			end)
			newBot.AncestryChanged:Connect(function()
				if newBot.Parent == nil then
					an:Disconnect()
				end
			end)
			if char:GetAttribute("G") == "M" and ((not male) and top) then
				top = false
			end
			if char:GetAttribute("G") == "Fem" and male then
				top = false
			end
			if male then 
				loadMorph(newBot, "M")
			else 
				loadMorph(newBot, "F")
			end
			if not char:GetAttribute("S") then
				if top then
					replicate(newBot, char)
				else 
					replicate(char, newBot)
				end
			end
			return true
		else 
			return "Failed to load user. Are you sure the username is valid and not banned?"
		end
	else 
		return "Get into a morph, noob."
	end
end



starterGui(assets.OBJECTS.start_menu)
starterGui(assets.OBJECTS.morph)
starterGui(assets.OBJECTS.bot)
starterGui(assets.OBJECTS.set)
starterGui(assets.OBJECTS.age)
starterGui(assets.OBJECTS.Blackout)

task.delay(2, function()
	for i,v in next, players:GetPlayers() do 
		v:LoadCharacter()
	end
end)
