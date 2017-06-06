local Data = {}

-- INIT

local function hasNido()
	for idx=0, 5 do
		local pokeID = memory.readbyte(0x116B + idx * 0x2C)
		if pokeID == 3 or pokeID == 167 or pokeID == 7 then
			return true
		end
	end
end

function Data.init()
	local version = 0
	if VERSION then
		local vIndex = 2
		for segment in string.gmatch(VERSION, "([^.]+)") do
			version = version + tonumber(segment) * 100 ^ vIndex
			vIndex = vIndex - 1
		end
	end

	local gameHash = gameinfo.getromhash()
	local gameName
	if gameHash == "EA9BCAE617FDF159B045185467AE58B2E4A48B9A" then
		gameName = "red"
	elseif gameHash == "D7037C83E1AE5B39BDE3C30787637BA1D4C48CE2" then
		gameName = "blue"
	elseif gameHash == "CC7D03262EBFAF2F06772C1A480C7D9D5F4A38E1" then
		gameName = "yellow"
	else
		print("ERR: Unknown game ROM", version, gameHash)
	end

	Data.run = {}
	Data.red = gameName == "red"
	Data.blue = gameName == "blue"
	Data.yellow = gameName == "yellow"
	Data.gameName = gameName
	Data.versionNumber = version
end

-- PRIVATE

local function increment(amount)
	if not amount then
		return 1
	end
	return amount + 1
end

-- HELPERS

function Data.setFrames()
	Data.run.frames = require("util.utils").frames()
end

function Data.increment(key)
	local incremented = increment(Data.run[key])
	Data.run[key] = incremented
	return incremented
end

-- REPORT

function Data.reset(reason, areaName, map, px, py, stats)
	if STREAMING_MODE then
		local report = Data.run
		report.cutter = require("storage.pokemon").hasCutter()

		for key,value in pairs(report) do
			if value == true or value == false then
				report[key] = value == true and 1 or 0
			end
		end

		local ns = stats.nidoran
		if ns then
			report.nido_attack = ns.attackDV
			report.nido_defense = ns.defenseDV
			report.nido_speed = ns.speedDV
			report.nido_special = ns.specialDV
			report.nido_level = ns.level4 and 4 or 3
		end
		local ss = stats.starter
		if ss then
			report.starter_attack = ss.attackDV
			report.starter_defense = ss.defenseDV
			report.starter_speed = ss.speedDV
			report.starter_special = ss.specialDV
		end

		report.version = Data.versionNumber
		report.reset_area = areaName
		report.reset_map = map
		report.reset_x = px
		report.reset_y = py
		report.reset_reason = reason

		if not report.frames then
			Data.setFrames()
		end

		require("util.bridge").report(report)
	end
	Data.run = {}
end

return Data
