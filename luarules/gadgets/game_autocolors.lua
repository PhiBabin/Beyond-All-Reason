local gadget = gadget ---@type Gadget

function gadget:GetInfo()
	return {
		name = "AutoColorPicker",
		desc = "Automatically assigns colors to teams",
		author = "Damgam, Born2Crawl (color palette)",
		date = "2021",
		license = "GNU GPL, v2 or later",
		layer = -100,
		enabled = true,
	}
end

local anonymousMode = Spring.GetModOptions().teamcolors_anonymous_mode
local gaiaTeamID = Spring.GetGaiaTeamID()
local teamList = Spring.GetTeamList()
local allyTeamList = Spring.GetAllyTeamList()
local allyTeamCount = #allyTeamList - 1
local isSurvival = Spring.Utilities.Gametype.IsPvE()

local survivalColorNum = 1 -- Starting from color #1
local survivalColorVariation = 0 -- Current color variation
local allyTeamNum = 0
local teamSizes = {}

local myAllyTeamID, myTeamID
if not gadgetHandler:IsSyncedCode() then
	myAllyTeamID = Spring.GetMyAllyTeamID()
	myTeamID = Spring.GetMyTeamID()
end

-- Special colors
local armBlueColor = "#004DFF" -- Armada Blue
local corRedColor = "#FF1005" -- Cortex Red
local scavPurpColor = "#6809A1" -- Scav Purple
local raptorOrangeColor = "#CC8914" -- Raptor Orange
local gaiaGrayColor = "#7F7F7F" -- Gaia Grey
local legGreenColor = "#0CE818" -- Legion Green

-- NEW IceXuick Colors V6
local ffaColors = {
	"#004DFF", -- 1
	"#FF1005", -- 2
	"#0CE908", -- 3
	"#FFD200", -- 4
	"#F80889", -- 5
	"#09F5F5", -- 6
	"#FF6107", -- 7
	"#F190B3", -- 8
	"#097E1C", -- 9
	"#C88B2F", -- 10
	"#7CA1FF", -- 11
	"#9F0D05", -- 12
	"#3EFFA2", -- 13
	"#F5A200", -- 14
	"#C4A9FF", -- 15
	"#0B849B", -- 16
	"#B4FF39", -- 17
	"#FF68EA", -- 18
	"#D8EEFF", -- 19
	"#689E3D", -- 20
	"#B04523", -- 21
	"#FFBB7C", -- 22
	"#3475FF", -- 23
	"#DD783F", -- 24
	"#FFAAF3", -- 25
	"#4A4376", -- 26
	"#773A01", -- 27
	"#B7EA63", -- 28
	"#764A4A", -- 29
	"#7EB900", -- 30
}
-- delete excess so a table shuffe wont use the colors added on the bottom
if #ffaColors > #teamList-1 then
	for i = #teamList, #ffaColors do
		ffaColors[i] = nil
	end
end

-- Tailwind v4 color palette (Mostly brightness 200 to 800)
-- Note: the official color palette used P3 colors (which are meant for HDR displays), this is the fallback RGB colors.
-- RGB value are listed as integer values to skip the call to hex2RGB()
local gradients = {
	blue = {{190, 219, 255}, {142, 197, 255}, {81, 162, 255}, {43, 127, 255}, {21, 93, 252}, {20, 71, 230}, {25, 60, 184}},
	cyan = {{162, 244, 253}, {83, 234, 253}, {0, 211, 242}, {0, 184, 219}, {0, 146, 184}, {0, 117, 149}, {0, 95, 120}},
	violet = {{221, 214, 255}, {196, 180, 255}, {166, 132, 255}, {142, 81, 255}, {127, 34, 254}, {112, 8, 231}, {93, 14, 192}, {77, 23, 154}},
	fusia = {{246, 207, 255}, {244, 168, 255}, {237, 106, 255}, {225, 42, 251}, {200, 0, 222}, {168, 0, 183}, {138, 1, 148}},
	pink = {{253, 165, 213}, {251, 100, 182}, {246, 51, 154}, {230, 0, 118}, {198, 0, 92}, {163, 0, 76}, {134, 16, 67}},
	red = {{255, 201, 201}, {255, 162, 162}, {255, 100, 103}, {251, 44, 54}, {231, 0, 11}, {193, 0, 7}, {159, 7, 18}},
	orange = {{255, 214, 167}, {255, 184, 106}, {255, 137, 4}, {255, 105, 0}, {245, 73, 0}, {202, 53, 0}},
	yellow = {{255, 240, 133}, {255, 223, 32}, {253, 199, 0}, {240, 177, 0}, {208, 135, 0}, {166, 95, 0}, {137, 75, 0}},
	green = {{185, 248, 207}, {123, 241, 168}, {5, 223, 114}, {0, 201, 80}, {0, 166, 62}, {0, 130, 54}, {1, 102, 48}},
	lime = {{236, 252, 202}, {216, 249, 153}, {187, 244, 81}, {154, 230, 0}, {124, 207, 0}, {94, 165, 0}, {73, 125, 0}, {60, 99, 0}, {53, 83, 14}},
	teal = {{150, 247, 228}, {70, 236, 213}, {0, 213, 190}, {0, 187, 167}, {0, 150, 137}, {0, 120, 111}, {0, 95, 90}},
	sky = {{184, 230, 254}, {116, 212, 255}, {0, 188, 255}, {0, 166, 244}, {0, 132, 209}, {0, 105, 168}, {0, 89, 138}},
}

local allGrandientNames = {"blue", "red", "green", "yellow", "fusia", "teal", "orange", "pink", "lime", "violet", "cyan", "sky"}

local gradientGroupPerNumTeams = {
	-- One team
	{
		{"blue", "sky", "violet", "green", "lime"}, -- cold
	},
	-- 2 teams
	{
		{"blue", "sky", "violet", "green", "lime"}, -- cold
		{"red", "pink", "fusia", "orange", "yellow"}, -- warm
	},
	-- 3 teams
	{
		{"blue", "sky", "violet"}, -- blue
		{"red", "orange", "yellow"}, -- red
		{"green", "lime", "teal"}, -- green
	},
	-- 4 teams
	{
		{"blue", "sky", "violet"}, -- blue
		{"red", "pink", "fusia"}, -- red pink
		{"green", "lime", "teal"}, -- green
		{"orange", "yellow"},
	},
	-- 5 teams
	{
		{"blue", "sky"}, -- blue
		{"red", "pink"}, -- red pink
		{"green", "lime"}, -- green
		{"orange", "yellow"},
		{"violet", "fusia"},
	},
	-- 6 teams
	{
		{"blue", "sky"}, -- blue
		{"red", "pink"}, -- red pink
		{"green", "lime"}, -- green
		{"orange", "yellow"},
		{"violet", "fusia"},
		{"teal", "cyan"},
	},
}


local survivalColors = {
	"#0B3EF3", -- 1
	"#FF1005", -- 2
	"#0CE908", -- 3
	"#ffab8c", -- 4
	"#09F5F5", -- 5
	"#FCEEA4", -- 6
	"#097E1C", -- 7
	"#F190B3", -- 8
	"#F80889", -- 9
	"#3EFFA2", -- 10
	"#911806", -- 11
	"#7CA1FF", -- 12
	"#3c7a74", -- 13
	"#B04523", -- 14
	"#B4FF39", -- 15
	"#773A01", -- 16
	"#D8EEFF", -- 17
	"#689E3D", -- 18
	"#0B849B", -- 19
	"#FFD200", -- 20
	"#971C48", -- 21
	"#4A4376", -- 22
	"#764A4A", -- 23
	"#4F2684", -- 24
}

local teamColors = {
	{ -- One Team (not possible)
		{ -- First Team
			"#004DFF", -- Armada Blue
		},
	},

	{ -- Two Teams (40 colors)
		{ -- First Team (Cool)
			"#0B3EF3", --1
			"#0CE908", --2
			"#00f5e5", --3
			"#6941f2", --4
			"#8fff94", --5
			"#1b702f", --6
			"#7cc2ff", --7
			"#a294ff", --8
			"#0B849B", --9
			"#689E3D", --10
			"#4F2684", --11
			"#2C32AC", --12
			"#6968A0", --13
			"#D8EEFF", --14
			"#3475FF", --15
			"#7EB900", --16
			"#4A4376", --17
			"#B7EA63", --18
			"#C4A9FF", --19
			"#37713A", --20
		},
		{ -- Second Team (Warm)
			"#FF1005", --1
			"#FFD200", --2
			"#FF6107", --3
			"#F80889", --4
			"#FCEEA4", --5
			"#8a2828", --6
			"#F190B3", --7
			"#C88B2F", --8
			"#B04523", --9
			"#FFBB7C", --10
			"#A35274", --11
			"#773A01", --12
			"#F5A200", --13
			"#BBA28B", --14
			"#971C48", --15
			"#FF68EA", --16
			"#DD783F", --17
			"#FFAAF3", --18
			"#764A4A", --19
			"#9F0D05", --20
		},
	},

	{ -- Three Teams (24 colors)
		{ -- First Team (Blue)
			"#004DFF", -- 1
			"#09F5F5", -- 2
			"#7CA1FF", -- 3
			"#2C32AC", -- 4
			"#D8EEFF", -- 5
			"#0B849B", -- 6
			"#3C7AFF", -- 7
			"#5F6492", -- 8
		},
		{ -- Second Team (Red)
			"#FF1005", -- 1
			"#FF6107", -- 2
			"#FFD200", -- 3
			"#FF6058", -- 4
			"#FFBB7C", -- 5
			"#C88B2F", -- 6
			"#F5A200", -- 7
			"#9F0D05", -- 8
		},
		{ -- Third Team (Green)
			"#0CE818", -- 1
			"#B4FF39", -- 2
			"#097E1C", -- 3
			"#3EFFA2", -- 4
			"#689E3D", -- 5
			"#7EB900", -- 6
			"#B7EA63", -- 7
			"#37713A", -- 8
		},
	},

	{ -- Four Teams (24 colors)
		{ -- First Team (Blue)
			"#004DFF", -- 1
			"#7CA1FF", -- 2
			"#D8EEFF", -- 3
			"#09F5F5", -- 4
			"#3475FF", -- 5
			"#0B849B", -- 6
		},
		{ -- Second Team (Red)
			"#FF1005", -- 1
			"#FF6107", -- 2
			"#FF6058", -- 3
			"#B04523", -- 4
			"#F80889", -- 5
			"#971C48", -- 6
		},
		{ -- Third Team (Green)
			"#0CE818", -- 1
			"#B4FF39", -- 2
			"#097E1C", -- 3
			"#3EFFA2", -- 4
			"#689E3D", -- 5
			"#7EB900", -- 6
		},
		{ -- Fourth Team (Yellow)
			"#FFD200", -- 1
			"#F5A200", -- 2
			"#FCEEA4", -- 3
			"#FFBB7C", -- 4
			"#BBA28B", -- 5
			"#C88B2F", -- 6
		},
	},

	{ -- Five Teams  (25 colors)
		{ -- First Team (Blue)
			"#004DFF", -- 1
			"#7CA1FF", -- 2
			"#D8EEFF", -- 3
			"#09F5F5", -- 4
			"#3475FF", -- 5
		},
		{ -- Second Team (Red)
			"#FF1005", -- 1
			"#FF6107", -- 2
			"#FF6058", -- 3
			"#B04523", -- 4
			"#9F0D05", -- 5
		},
		{ -- Third Team (Green)
			"#0CE818", -- 1
			"#B4FF39", -- 2
			"#097E1C", -- 3
			"#3EFFA2", -- 4
			"#689E3D", -- 5
		},
		{ -- Fourth Team (Yellow)
			"#FFD200", -- 1
			"#F5A200", -- 2
			"#FCEEA4", -- 3
			"#FFBB7C", -- 4
			"#C88B2F", -- 5
		},
		{ -- Fifth Team (Fuchsia)
			"#F80889", -- 1
			"#FF68EA", -- 2
			"#FFAAF3", -- 3
			"#AA0092", -- 4
			"#701162", -- 5
		},
	},

	{ -- Six Teams (24 colors)
		{ -- First Team (Blue)
			"#004DFF", -- 1
			"#7CA1FF", -- 2
			"#D8EEFF", -- 3
			"#2C32AC", -- 4
		},
		{ -- Second Team (Red)
			"#FF1005", -- 1
			"#FF6058", -- 2
			"#B04523", -- 3
			"#9F0D05", -- 4
		},
		{ -- Third Team (Green)
			"#0CE818", -- 1
			"#B4FF39", -- 2
			"#097E1C", -- 3
			"#3EFFA2", -- 4
		},
		{ -- Fourth Team (Yellow)
			"#FFD200", -- 1
			"#F5A200", -- 2
			"#FCEEA4", -- 3
			"#9B6408", -- 4
		},
		{ -- Fifth Team (Fuchsia)
			"#F80889", -- 1
			"#FF68EA", -- 2
			"#FFAAF3", -- 3
			"#971C48", -- 4
		},
		{ -- Sixth Team (Orange)
			"#FF6107", -- 1
			"#FFBB7C", -- 2
			"#DD783F", -- 3
			"#773A01", -- 4
		},
	},

	{ -- Seven Teams (21 colors)
		{ -- First Team (Blue)
			"#004DFF", -- 1
			"#7CA1FF", -- 2
			"#2C32AC", -- 3
		},
		{ -- Second Team (Red)
			"#FF1005", -- 1
			"#FF6058", -- 2
			"#9F0D05", -- 3
		},
		{ -- Third Team (Green)
			"#0CE818", -- 1
			"#B4FF39", -- 2
			"#097E1C", -- 3
		},
		{ -- Fourth Team (Yellow)
			"#FFD200", -- 1
			"#F5A200", -- 2
			"#FCEEA4", -- 3
		},
		{ -- Fifth Team (Fuchsia)
			"#F80889", -- 1
			"#FF68EA", -- 2
			"#FFAAF3", -- 3
		},
		{ -- Sixth Team (Orange)
			"#FF6107", -- 1
			"#FFBB7C", -- 2
			"#DD783F", -- 3
		},
		{ -- Seventh Team (Cyan)
			"#09F5F5", -- 1
			"#0B849B", -- 2
			"#D8EEFF", -- 3
		},
	},

	{ -- Eight Teams (24 colors)
		{ -- First Team (Blue)
			"#004DFF", -- 1
			"#7CA1FF", -- 2
			"#2C32AC", -- 3
		},
		{ -- Second Team (Red)
			"#FF1005", -- 1
			"#FF6058", -- 2
			"#9F0D05", -- 3
		},
		{ -- Third Team (Green)
			"#0CE818", -- 1
			"#B4FF39", -- 2
			"#097E1C", -- 3
		},
		{ -- Fourth Team (Yellow)
			"#FFD200", -- 1
			"#F5A200", -- 2
			"#FCEEA4", -- 3
		},
		{ -- Fifth Team (Fuchsia)
			"#F80889", -- 1
			"#FF68EA", -- 2
			"#971C48", -- 3
		},
		{ -- Sixth Team (Orange)
			"#FF6107", -- 1
			"#FFBB7C", -- 2
			"#DD783F", -- 3
		},
		{ -- Seventh Team (Cyan)
			"#09F5F5", -- 1
			"#0B849B", -- 2
			"#D8EEFF", -- 3
		},
		{ -- Eigth Team (Purple)
			"#872DFA", -- 1
			"#6809A1", -- 2
			"#C4A9FF", -- 3
		},
	},
}

local r = math.random(1,100000)
math.randomseed(1)	-- make sure the next sequence of randoms can be reproduced
local teamRandoms = {}
for i = 1, #teamList do
	teamRandoms[teamList[i]] = { math.random(), math.random(), math.random() }
end
math.randomseed(r)


local iconDevModeColors = {
	armblue = armBlueColor,
	corred = corRedColor,
	scavpurp = scavPurpColor,
	raptororange = raptorOrangeColor,
	gaiagray = gaiaGrayColor,
	leggren = legGreenColor,
}
local iconDevMode = Spring.GetModOptions().teamcolors_icon_dev_mode
local iconDevModeColor = iconDevModeColors[iconDevMode]

-- Get color of a gradient by interpolating between the colors in the gradient.
-- The gradient is a list of RGB colors
-- Assumed ratio is in [0, 1]
local function interpolateGradient(gradient, ratio)
	if ratio >= 1.0 then
		return gradient[#gradient]
	end
	-- For instance, with a gradient of 3 colors and ratio = 0.6
	-- gradientRatio = 0.6 * (3 - 1) = 1.2
	local gradientRatio = ratio * (#gradient - 1)
	-- colorId = floor(1.2) = 1
	local colorId = math.floor(gradientRatio)
	local colorA = gradient[colorId + 1]
	local colorB = gradient[colorId + 2]
	-- lerpRatio = 1.2 - 1 = 0.2
	local lerpRatio = gradientRatio - colorId

	-- Interpolate between each RGB value in colorA and colorB
	return {
		math.clamp(math.floor((colorB[1] - colorA[1]) * lerpRatio + colorA[1]), 0, 255),
		math.clamp(math.floor((colorB[2] - colorA[2]) * lerpRatio + colorA[2]), 0, 255),
		math.clamp(math.floor((colorB[3] - colorA[3]) * lerpRatio + colorA[3]), 0, 255)}
end

local function shuffleTable(Table)
	local originalTable = {}
	table.append(originalTable, Table)
	local shuffledTable = {}
	if #originalTable > 0 then
		repeat
			local r = math.random(#originalTable)
			table.insert(shuffledTable, originalTable[r])
			table.remove(originalTable, r)
		until #originalTable == 0
	else
		shuffledTable = originalTable
	end
	return shuffledTable
end

local function shuffleAllColors()
	ffaColors = shuffleTable(ffaColors)
	survivalColors = shuffleTable(survivalColors)
	for i = 1, #teamColors do
		for j = 1, #teamColors[i] do
			teamColors[i][j] = shuffleTable(teamColors[i][j])
		end
	end
end

local function hex2RGB(hex)
	hex = hex:gsub("#", "")
	return { tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)) }
end

-- we don't want to use FFA colors for TeamFFA, because we want each team to have its own color theme
local useFFAColors = Spring.Utilities.Gametype.IsFFA() and not Spring.Utilities.Gametype.IsTeams()
if not useFFAColors and not teamColors[allyTeamCount] and not isSurvival then -- Edge case for TeamFFA with more than supported number of teams
	useFFAColors = true
end

local teamColorsTable = {}
local trueTeamColorsTable = {} -- run first as if we were specs so when we become specs, we can restore the true intended team colors
local trueFfaColors = table.copy(ffaColors) -- run first as if we were specs so when we become specs, we can restore the true intended ffa colors
local trueSurvivalColors = table.copy(survivalColors) -- run first as if we were specs so when we become specs, we can restore the true intended survival colors

-- Legacy procedurally generate a color for given team ID and ally team ID.
-- Each ally team is assigned a color from the ffaColors table. The color is generated by changing the brightness of the assigned color and
-- by randomly changing the RGB value.
local function legacyFFAColorGeneration(teamID, allyTeamID)
	local color = hex2RGB(ffaColors[allyTeamID+1] or '#333333')

	local maxIterations =  math.floor((allyTeamID+1)/(#ffaColors))
	-- So if you're the Nth player of a team with M players:
	-- brightnessVariation = (0.6 - N / M) * 255   , so the range is in -0.4*255 to 0.6*255  or -102 to 153
	local brightnessVariation = (0.6 - ((1 / #Spring.GetTeamList(allyTeamID)) * dimmingCount[allyTeamID])) * 255
	-- brightnessVariation *= math.min(M*0.7 - 1, 1)
	-- For M == 1 -> -0.3
	-- For M == 2 -> 0.4
	-- For M >= 3 -> 1
	brightnessVariation = brightnessVariation * math.min((#Spring.GetTeamList(allyTeamID) * 0.7)-1, 1)	-- dont change brightness too much in tiny teams

	-- Basically maxColorVariation gets lower and lower as the number of team increase
	-- maxColorVariation = 120 / max(1, num_team)
	-- So for #P team        1   2   3   4   5   6   7   8
	-- maxColorVariation = 120, 60, 40, 30, 24, 20, 17, 15...
	local maxColorVariation = (120 / math.max(1, allyTeamCount-1))
	if #Spring.GetTeamList(allyTeamID) == 1 then
		brightnessVariation = 0
		maxColorVariation = 0
	end
	-- Basically if there are more player than the table of ffacolors
	-- This is make no sense, because this is trying to add a per team variation, instead of a per player variation
	if maxIterations > 1 then
		-- iteration = 1 + math.floor((allyTeamID+1) / 30 )
		-- iteration = 1 + (allyTeamID+1) // 30
		local iteration = 1 + math.floor((allyTeamID+1)/(#ffaColors))
		-- ffacolor = (allyTeamID+1) - (#ffaColors*(iteration-1)) + 1
		--          = (allyTeamID+1) - (30*((allyTeamID+1) // 30)) + 1
		--          = (allyTeamID+1) % 30
		local ffaColor = (allyTeamID+1) - (#ffaColors*(iteration-1)) + 1
		if iteration ~= 1 then
			color = hex2RGB(ffaColors[ffaColor])
		end
		if iteration == 1 then
			color[1] = color[1] + 40
			color[2] = color[2] + 40
			color[3] = color[3] + 40
		elseif iteration == 2 then
			color[1] = color[1] - 70
			color[2] = color[2] - 70
			color[3] = color[3] - 70
		elseif iteration == 3 then
			color[1] = color[1] + 130
			color[2] = color[2] + 130
			color[3] = color[3] + 130
		end
	end
	if teamID == gaiaTeamID then
		brightnessVariation = 0
		maxColorVariation = 0
		color = hex2RGB(gaiaGrayColor)
	end
	-- = clamp(floor( r + brightnessVariation + 2 * random * maxColorVariation - maxColorVariation)
	--  ), 0, 255)
	-- = clamp(floor( r + brightnessVariation + (2 * random - 1.0) * maxColorVariation)
	--  ), 0, 255)
	-- = clamp(floor( r + brightnessVariation + random(-1., 1.) * maxColorVariation)
	--  ), 0, 255)
	-- brightnessVariation is between -0.4*255 to 0.6*255 for large team
	color[1] = math.clamp(math.floor(color[1] + brightnessVariation + ((teamRandoms[teamID][1] * (maxColorVariation * 2)) - maxColorVariation)), 0, 255)
	color[2] = math.clamp(math.floor(color[2] + brightnessVariation + ((teamRandoms[teamID][2] * (maxColorVariation * 2)) - maxColorVariation)), 0, 255)
	color[3] = math.clamp(math.floor(color[3] + brightnessVariation + ((teamRandoms[teamID][3] * (maxColorVariation * 2)) - maxColorVariation)), 0, 255)
	return color
end

-- Procedurally generate a color for given team ID and ally team ID.
-- Each ally team is assigned N gradients and the player's color is generated by sampling the color gradient(s).
local function ffaColorGeneration(teamID, allyTeamID)
	if teamID == gaiaTeamID then
		return hex2RGB(gaiaGrayColor)
	end

	-- Asumptions: The last ally team is gaia and can be ignored
	local totalNumAllyTeams = allyTeamCount
	local numPlayerInTeam = #Spring.GetTeamList(allyTeamID)
	-- 0-indexed, [0, numPlayerInTeam[
	local nthPlayerInTeam = dimmingCount[allyTeamID] - 1
	local useGradientGroup = not (not gradientGroupPerNumTeams[totalNumAllyTeams])

	-- Case 1: If gradient groups are used, each ally team is assigned N gradients
	-- e.g. team #1 warm gradient (red, orange, yellow) vs team #2 cold gradients (blue, green, purple)
	if useGradientGroup then
		local teamGradientGroup = gradientGroupPerNumTeams[totalNumAllyTeams][allyTeamID + 1]

		-- (edge case) If there are more gradient than player, each player just take the middle color of a gradient
		if numPlayerInTeam <= #teamGradientGroup then
			local gradient = gradients[teamGradientGroup[nthPlayerInTeam + 1]]
			local ratioWithinGradient = 0.5
			return interpolateGradient(gradient, ratioWithinGradient)
		end
		-- Regular case, where we sample thru the group of gradients

		-- Find which gradient is used by the player
		local playerRatio = nthPlayerInTeam / numPlayerInTeam
		local playerGradientId = math.floor(playerRatio * #teamGradientGroup)
		local playerGradientName = teamGradientGroup[playerGradientId + 1]
		local gradient = gradients[playerGradientName]

		local ratioWithinGradient = playerRatio * #teamGradientGroup - playerGradientId 
		return interpolateGradient(gradient, ratioWithinGradient)
	end
	 -- Case 2: Each ally team use one gradient, this gradient might be share with other ally team(s)
	 -- e.g one team is bright green, another is dark green

	local gradientId = math.floor(allyTeamID % #allGrandientNames)
	local gradName = allGrandientNames[gradientId + 1]
	local gradient = gradients[gradName]

	-- How many ally team share the same gradient?
	local numAllyTeamWithGradient = math.floor(totalNumAllyTeams / #allGrandientNames)
	-- Not all gradients will share the same number of ally team
	if gradientId < totalNumAllyTeams % #allGrandientNames then
		numAllyTeamWithGradient = numAllyTeamWithGradient + 1
	end
	local nthAllyTeamWithGradient = math.floor(allyTeamID / #allGrandientNames)

	-- If there is only a single player in a team, take the color at the center of the gradient
	local playerGradientRatio = 0.5
	-- Otherwise, we distribute the players amount the gradient
	if numPlayerInTeam > 1 then
		-- We divide by numPlayerInTeam-1, not by numPlayerInTeam, because we want this ratio to be between [0,1], not [0, 1[
		playerGradientRatio = nthPlayerInTeam / (numPlayerInTeam-1)
		local ratioPerPlayer = 1.0 / (numPlayerInTeam-1)

		-- When there are fewer than 5 players in an ally team, the brighness change between player is large, so instead of sampling the entire gradient
		-- we only sample near the middle of the gradient.
		local maxPerPlayerRatio = 0.25
		if ratioPerPlayer > maxPerPlayerRatio then
			-- Basically, space every player by 25% of the gradient, but the range is centered on the middle of the gradient
			-- player 0th in ally team of 3 players:
			-- = 0.5 + 0.25 * (N - (M-1) / 2)
			-- = 0.5 + 0.25 * (0 - 2 / 2)
			-- = 0.5 - 0.25
			-- So the playerGradientRatio will be 0.25, 0.5, 0.75 for this team
			playerGradientRatio = 0.5 + maxPerPlayerRatio * (nthPlayerInTeam - (numPlayerInTeam-1) / 2.0)
		end
	end

	-- If multiple ally team share the same gradient, create a gap between the end of one team's and the start of the next one
	if numAllyTeamWithGradient > 1 and nthAllyTeamWithGradient + 1 ~= numAllyTeamWithGradient then
		playerGradientRatio = 0.9 * playerGradientRatio
	end
	local gradientRatio =  playerGradientRatio / numAllyTeamWithGradient + nthAllyTeamWithGradient / numAllyTeamWithGradient

	return interpolateGradient(gradient, gradientRatio)
end

local function setupTeamColor(teamID, allyTeamID, isAI, localRun)
	if iconDevModeColor then
		teamColorsTable[teamID] = {
			r = hex2RGB(iconDevModeColor)[1],
			g = hex2RGB(iconDevModeColor)[2],
			b = hex2RGB(iconDevModeColor)[3],
		}

	-- Simple Team Colors
	elseif localRun and
		(Spring.GetConfigInt("SimpleTeamColors", 0) == 1 or (anonymousMode == "allred" and not mySpecState))
	then
		local brightnessVariation = 0
		local maxColorVariation = 0
		if Spring.GetConfigInt("SimpleTeamColorsUseGradient", 0) == 1 then
			local totalEnemyDimmingCount = 0
			for allyTeamID, count in pairs(dimmingCount) do
				if allyTeamID ~= myAllyTeamID then
					totalEnemyDimmingCount = totalEnemyDimmingCount + count
				end
			end
			brightnessVariation = (0.7 - ((1 / #Spring.GetTeamList(allyTeamID)) * dimmingCount[allyTeamID])) * 255
			brightnessVariation = brightnessVariation * math.min((#Spring.GetTeamList(allyTeamID) * 0.8)-1, 1)	-- dont change brightness too much in tiny teams
			maxColorVariation = 60
		end
		local color = hex2RGB(ffaColors[allyTeamID+1] or '#333333')
		if teamID == gaiaTeamID then
			brightnessVariation = 0
			maxColorVariation = 0
			color = hex2RGB(gaiaGrayColor)
		elseif teamID == myTeamID then
			brightnessVariation = 0
			maxColorVariation = 0
			color = {Spring.GetConfigInt("SimpleTeamColorsPlayerR", 0), Spring.GetConfigInt("SimpleTeamColorsPlayerG", 77), Spring.GetConfigInt("SimpleTeamColorsPlayerB", 255)}
		elseif allyTeamID == myAllyTeamID then
			color = {Spring.GetConfigInt("SimpleTeamColorsAllyR", 0), Spring.GetConfigInt("SimpleTeamColorsAllyG", 255), Spring.GetConfigInt("SimpleTeamColorsAllyB", 0)}
		elseif allyTeamID ~= myAllyTeamID then
			color = {Spring.GetConfigInt("SimpleTeamColorsEnemyR", 255), Spring.GetConfigInt("SimpleTeamColorsEnemyG", 16), Spring.GetConfigInt("SimpleTeamColorsEnemyB", 5)}
		end
		color[1] = math.min(color[1] + brightnessVariation, 255) + ((teamRandoms[teamID][1] * (maxColorVariation * 2)) - maxColorVariation)
		color[2] = math.min(color[2] + brightnessVariation, 255) + ((teamRandoms[teamID][2] * (maxColorVariation * 2)) - maxColorVariation)
		color[3] = math.min(color[3] + brightnessVariation, 255) + ((teamRandoms[teamID][3] * (maxColorVariation * 2)) - maxColorVariation)
		teamColorsTable[teamID] = {
			r = color[1],
			g = color[2],
			b = color[3],
		}

	elseif isAI and string.find(isAI, "Scavenger") then
		teamColorsTable[teamID] = {
			r = hex2RGB(scavPurpColor)[1],
			g = hex2RGB(scavPurpColor)[2],
			b = hex2RGB(scavPurpColor)[3],
		}
	elseif isAI and string.find(isAI, "Raptor") then
		teamColorsTable[teamID] = {
			r = hex2RGB(raptorOrangeColor)[1],
			g = hex2RGB(raptorOrangeColor)[2],
			b = hex2RGB(raptorOrangeColor)[3],
		}
	elseif teamID == gaiaTeamID then
		teamColorsTable[teamID] = {
			r = hex2RGB(gaiaGrayColor)[1],
			g = hex2RGB(gaiaGrayColor)[2],
			b = hex2RGB(gaiaGrayColor)[3],
		}

	elseif isSurvival and survivalColors[#Spring.GetTeamList()-2] then
		teamColorsTable[teamID] = {
			r = hex2RGB(survivalColors[survivalColorNum])[1]
				+ math.random(-survivalColorVariation, survivalColorVariation),
			g = hex2RGB(survivalColors[survivalColorNum])[2]
				+ math.random(-survivalColorVariation, survivalColorVariation),
			b = hex2RGB(survivalColors[survivalColorNum])[3]
				+ math.random(-survivalColorVariation, survivalColorVariation),
		}
		survivalColorNum = survivalColorNum + 1 -- Will start from the next color next time

	-- Auto FFA gradient colored for huge player games
	elseif useFFAColors or
	-- or Number of player in last non-gaia team is larger than one and there is not a color palette for it
		(#Spring.GetTeamList(allyTeamCount-1) > 1 and (not teamColors[allyTeamCount] or not teamColors[allyTeamCount][1][#Spring.GetTeamList(allyTeamCount-1)]))
	-- or There is more than 29 players (ignores gaia)
		or #Spring.GetTeamList() > 30
	-- or the number of players in the last non-gaia team is one and there is more than team than ffaColor
	    or (#Spring.GetTeamList(allyTeamCount-1) == 1 and not ffaColors[allyTeamCount])
	then
		local color = nil
		-- If there is less than 30 players and only one player per ally team use legacy FFA colors
		if #Spring.GetTeamList(allyTeamCount-1) == 1 and #Spring.GetTeamList() -1 <= 30 then
			color = legacyFFAColorGeneration(teamID, allyTeamID)
		else
			color = ffaColorGeneration(teamID, allyTeamID)
		end
		teamColorsTable[teamID] = {
			r = color[1],
			g = color[2],
			b = color[3],
		}
	-- Use the color palette defined in the teamColors table
	else
		if not teamSizes[allyTeamID] then
			allyTeamNum = allyTeamNum + 1
			teamSizes[allyTeamID] = { allyTeamNum, 1, 0 } -- Team number, Starting color number, Color variation
		end

		if teamColors[allyTeamCount] -- If we have the color set for this number of teams
			and teamColors[allyTeamCount][teamSizes[allyTeamID][1]]
		then -- And this team number exists in the color set
			if not teamColors[allyTeamCount][teamSizes[allyTeamID][1]][teamSizes[allyTeamID][2]] then -- If we have no color for this player anymore
				teamSizes[allyTeamID][2] = 1 -- Starting from the first color again..
			end

			-- Assigning R,G,B values with specified color variations
			local color = hex2RGB(teamColors[allyTeamCount][teamSizes[allyTeamID][1]][teamSizes[allyTeamID][2]])
			local colorVariation = teamSizes[allyTeamID][3] -- This is always zero
			teamColorsTable[teamID] = {
				r = color[1] + math.random(-colorVariation, colorVariation),
				g = color[2] + math.random(-colorVariation, colorVariation),
				b = color[3] + math.random(-colorVariation, colorVariation),
			}
			teamSizes[allyTeamID][2] = teamSizes[allyTeamID][2] + 1 -- Will start from the next color next time

		else
			Spring.Echo("[AUTOCOLORS] Error: Team Colors Table is broken or missing for this allyteam set")
			teamColorsTable[teamID] = {
				r = 255,
				g = 255,
				b = 255,
			}
		end
	end
end

local function setupAllTeamColors(localRun)
	survivalColorNum = 1 -- Starting from color #1
	survivalColorVariation = 0 -- Current color variation
	allyTeamNum = 0
	teamSizes = {}

	dimmingCount = {}
	for _, allyTeamID in ipairs(Spring.GetAllyTeamList()) do
		dimmingCount[allyTeamID] = 0
	end
	for i = 1, #teamList do
		local teamID = teamList[i]
		local allyTeamID = select(6, Spring.GetTeamInfo(teamID))
		dimmingCount[allyTeamID] = dimmingCount[allyTeamID] + 1
		local isAI = Spring.GetTeamLuaAI(teamID)
		setupTeamColor(teamID, allyTeamID, isAI, localRun)
	end
end
setupAllTeamColors(false)
trueTeamColorsTable = table.copy(teamColorsTable) -- store the true team colors so we can restore them when we become a spec


if gadgetHandler:IsSyncedCode() then	--- NOTE: STUFF DONE IN SYNCED IS FOR REPLAY WEBSITE

	local AutoColors = {}
	for i = 1, #teamList do
		local teamID = teamList[i]
		AutoColors[i] = {
			teamID = teamID,
			r = trueTeamColorsTable[teamID].r,
			g = trueTeamColorsTable[teamID].g,
			b = trueTeamColorsTable[teamID].b,
		}
	end
	Spring.SendLuaRulesMsg("AutoColors" .. Json.encode(AutoColors))


else	-- UNSYNCED

	local myPlayerID = Spring.GetLocalPlayerID()
	local mySpecState = Spring.GetSpectatingState()

	if anonymousMode == "local" then
		shuffleAllColors()
	end
	if anonymousMode == "local" or Spring.GetConfigInt("SimpleTeamColors", 0) == 1 then
		setupAllTeamColors(true)
	end

	local function isDiscoEnabled()
		return anonymousMode == "disco" and not mySpecState
	end

	-- shuffle colors for all teams except ourselves
	local function discoShuffle(myTeamID)
		-- store own color and do regular shuffle
		local myColor = teamColorsTable[myTeamID]
		shuffleAllColors()
		setupAllTeamColors(true)

		-- swap color with any team that might have been assigned own color
		local teamIDToSwapWith = nil
		for teamID, color in pairs(teamColorsTable) do
			if myColor.r == color.r and myColor.g == color.g and myColor.b == color.b then
				teamIDToSwapWith = teamID
				break
			end
		end
		if teamIDToSwapWith ~= nil then
			teamColorsTable[teamIDToSwapWith] = teamColorsTable[myTeamID]
		end

		-- restore own color
		teamColorsTable[myTeamID] = myColor
	end

	local function updateTeamColors()
		if isDiscoEnabled() then
			discoShuffle(Spring.GetMyTeamID())
		end
		for teamID, color in pairs(teamColorsTable) do
			Spring.SetTeamColor(teamID, color.r / 255, color.g / 255, color.b / 255)
		end
	end
	updateTeamColors()

	local discoTimer = 0
	local discoTimerThreshold = 2 * 60 -- shuffle every 2 minutes with disco mode enabled
	function gadget:Update()
		if isDiscoEnabled() then
			discoTimer = discoTimer + Spring.GetLastUpdateSeconds()
			if discoTimer > discoTimerThreshold then
				discoTimer = 0
				updateTeamColors()
			end
		elseif Spring.GetConfigInt("UpdateTeamColors", 0) == 1 then
			setupAllTeamColors(true)
			updateTeamColors()
			Spring.SetConfigInt("UpdateTeamColors", 0)
			Spring.SetConfigInt("SimpleTeamColors_Reset", 0)
		end
	end

	function gadget:PlayerChanged(playerID)
		if playerID ~= myPlayerID then
			return
		end
		myAllyTeamID = Spring.GetMyAllyTeamID()
		local prevMyTeamID = myTeamID
		myTeamID = Spring.GetMyTeamID()
		if mySpecState and prevMyTeamID ~= myTeamID and Spring.GetConfigInt("SimpleTeamColors", 0) == 1 then
			Spring.SetConfigInt("UpdateTeamColors", 1)
  		end
		if mySpecState ~= Spring.GetSpectatingState() then
			mySpecState = Spring.GetSpectatingState()
			teamColorsTable = table.copy(trueTeamColorsTable)
			ffaColors = table.copy(trueFfaColors)
			survivalColors = table.copy(trueSurvivalColors)
			Spring.SetConfigInt("UpdateTeamColors", 1)
		end
	end
end
