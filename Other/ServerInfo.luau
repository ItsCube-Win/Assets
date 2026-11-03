-- Not mine by Malware.gg

repeat task.wait() until game:IsLoaded()

local cloneref = cloneref or function(x) return x end

local Players = cloneref(game:GetService("Players"))
local lp = Players.LocalPlayer

local CoreGui = cloneref(game:GetService("CoreGui"))
local MPS = cloneref(game:GetService("MarketplaceService"))
local TPS = cloneref(game:GetService("TeleportService"))
local HTTP = cloneref(game:GetService("HttpService"))

local gethui = get_hidden_ui or gethui or function() return CoreGui end
local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or function() end

local randomString = function()
	local length = math.random(10,20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local copyText = (setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)) or function(text) warn("Failed to copy text:\n" .. text) end

local getGameIcon = function(id)
    local Details = MPS:GetProductInfo(id)
    local Icon = Details.IconImageAssetId

    return "rbxthumb://type=Asset&id=" .. Icon .. "&w=420&h=420"
end

local getGameName = function(id)
    return MPS:GetProductInfo(id).Name
end

if not isfile("Server Viewer.rbxm") then writefile("Server Viewer.rbxm", game:HttpGet("https://github.com/ATrainz/Addons/raw/refs/heads/main/Server%20Viewer.rbxm")) end

local GUI = game:GetObjects(getcustomasset("Server Viewer.rbxm"))[1]
GUI.Name = randomString()
GUI.Parent = gethui()

local Library = loadstring(GUI.ModuleScript.Source)()
Library:Initialize(GUI.Main)

local Pages = Library.Pages
local Icon = getGameIcon(game.PlaceId)

-- Old Servers

if isfolder("Old Servers") then
    for _,v in pairs(listfiles("Old Servers")) do
        local source = readfile(v)
        local tbl = HTTP:JSONDecode(source)
        
        local Server = Pages.OldServers:AddServer({
            Name = getGameName(tbl.PlaceId),
            Icon = getGameIcon(tbl.PlaceId),
            Time = tbl.JoinTime,
            Labels = {
                {Text = "Place ID: " .. tbl.PlaceId},
                {Text = "Job ID: " .. tbl.JobId},
                {Text = "Players: " .. table.concat(tbl.Players, ", ")}
            }
        })
        
        Server:AddButton({
            Text = "Join",
            Callback = function()
                TPS:Teleport(tbl.PlaceId, lp)
            end
        })
        
        Server:AddButton({
            Text = "Copy Join Link",
            Callback = function()
				copyText("roblox://experiences/start?placeId=" .. tbl.PlaceId .. "&gameInstanceId=" .. tbl.JobId)
            end
        })
        
        Server:AddButton({
            Text = "Copy Place ID",
            Callback = function()
                copyText(tbl.PlaceId)
            end
        })

        Server:AddButton({
            Text = "Remove",
            Callback = function()
                Server:Remove()
                delfile(v)
            end
        })
    end
end

-- Universe Viewer

local Interlude = request({
	Url = "https://develop.roblox.com/v1/universes/" .. game.GameId .. "/places?isUniverseCreation=false&limit=100&sortOrder=Asc",
	Method = "GET"
})

if Interlude then
	local data = HTTP:JSONDecode(Interlude.Body).data
	for _,v in pairs(data) do
		local id = v.id
		local name = v.name

		if id ~= game.PlaceId then
			local Server = Pages.UniverseViewer:AddServer({
				Name = name,
				Icon = Icon,
				Time = os.date("%I:%M:%S %p"),
				Labels = {
					{Text = "Place ID: " .. id},
                    {Text = "Players: Unable to fetch players"},
				}
			})
			
			Server:AddButton({
				Text = "Join",
				Callback = function()
					TPS:Teleport(id, lp)
				end
			})
			
			Server:AddButton({
				Text = "Copy Join Link",
				Callback = function()
					copyText("roblox://experiences/start?placeId=" .. id)
				end
			})
			
			Server:AddButton({
				Text = "Copy Place ID",
				Callback = function()
					copyText(id)
				end
			})
		end
	end
end

-- Friends

--[[
	Joins Off: DisplayName IsOnline LastLocation LastOnline LocationType UserName VisitorId
	Joins On: DisplayName GameId IsOnline LastLocation LastOnline LocationType PlaceId UserName VisitorId
]]

Pages.Friends.TabButton:FindFirstChildWhichIsA("TextButton").MouseButton1Click:Connect(function()	
	for _,v in pairs(Pages.Friends.Servers) do
		v:Remove()
	end
	
	for _,v in pairs(lp:GetFriendsOnline()) do
		local Display, User, PlaceID, JobID, VisitorID, LocationType = v.DisplayName, v.UserName, v.PlaceId, v.GameId, v.VisitorId, v.LocationType
		
		if Display and User and PlaceID and JobID and VisitorID and LocationType then
			local Server = Pages.Friends:AddServer({
				Name = Display .. " (@" .. User .. ")",
				Icon = "rbxthumb://type=AvatarHeadShot&id=" .. VisitorID .. "&w=420&h=420",
				Time = os.date("%I:%M:%S %p"),
				Labels = {
					{Text = "Place ID: " .. PlaceID, TextSize = 12},
					{Text = "Job ID: " .. JobID, TextSize = 12},
					{Text = "Location Type: " .. LocationType, TextSize = 12}
				}
			})

			Server:AddButton({
				Text = "Join",
				Callback = function()
					TPS:TeleportToPlaceInstance(PlaceID, JobID, lp)
				end
			})

			Server:AddButton({
				Text = "Copy Join Link",
				Callback = function()
					copyText("roblox://experiences/start?placeId=" .. PlaceID .. "&gameInstanceId=" .. JobID)
				end
			})

			Server:AddButton({
				Text = "Copy Place ID",
				Callback = function()
					copyText(PlaceID)
				end
			})
			
			Server:AddButton({
				Text = "Copy Job ID",
				Callback = function()
					copyText(JobID)
				end
			})
		end
	end
end)
