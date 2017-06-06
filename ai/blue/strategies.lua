local Strategies = require "ai.strategies"

local Combat = require "ai.combat"
local Control = require "ai.control"

local Data = require "data.data"

local Battle = require "action.battle"
local Shop = require "action.shop"
local Textbox = require "action.textbox"
local Walk = require "action.walk"

local Bridge = require "util.bridge"
local Input = require "util.input"
local Memory = require "util.memory"
local Menu = require "util.menu"
local Player = require "util.player"
local Utils = require "util.utils"

local Inventory = require "storage.inventory"
local Pokemon = require "storage.pokemon"

local status = Strategies.status
local stats = Strategies.stats

local strategyFunctions = Strategies.functions

-- TIME CONSTRAINTS

Strategies.timeRequirements = {

	mt_moon = function()
		local timeLimit = 30
		if Pokemon.hasCutter() then
			timeLimit = timeLimit + 0.25
		end
		return timeLimit
	end,

	misty = function() --TWEET
		return 50
	end,

	trash = function()
		return 60
	end,

	victory_road = function() --TWEET PB
		return 110
	end,

	e4center = function()
		return 120
	end,

	champion = function() --PB
		return 130
	end,

}

-- HELPERS

function Strategies.checkSquirtleStats(attack, defense, speed, special)
	Bridge.chat("is checking Squirtle's stats at level 6... "..attack.." attack, "..defense.." defense, "..speed.." speed, "..special.." special.")

	local squirtleStatus = {}
	if attack < 12 then
		table.insert(squirtleStatus, "unrunnable attack")
	end
	if speed < 11 then
		table.insert(squirtleStatus, "unrunnable speed")
	end
	if special < 12 then
		table.insert(squirtleStatus, "unrunnable special")
	end
	if squirtleStatus[1] then
		return Strategies.reset("stats", "Bad Squirtle - "..table.concat(squirtleStatus, ", "))
	end

	local attDV, defDV, spdDV, sclDV = Pokemon.getDVs("squirtle")
	stats.squirtle = {
		attackDV = attDV,
		defenseDV = defDV,
		speedDV = spdDV,
		specialDV = sclDV,
	}
end

-- STRATEGIES

strategyFunctions.antidote = function(data)
	if not data then
		data = {}
	end
	if Combat.firstPoisoned() then
		data.item = "antidote"
		data.poke = Pokemon.inParty("squirtle", "wartortle", "blastoise")
	end
	return Strategies.useItem(data)
end

-- ROUTE

-- squirtleIChooseYou

-- fightBulbasaur

-- fightWeedle

strategyFunctions.grabForestPotion = function()
	if Inventory.contains("potion") then
		return true
	end
	if Strategies.initialize() then
		if Combat.hp() > 15 then
			return true
		end
	end
	if Battle.handleWild() and Memory.value("player", "moving") == 0 then
		Player.interact("Up")
	end
end

strategyFunctions.equipForBrock = function()
	if Strategies.initialize() then
		if Pokemon.info("squirtle", "level") < 8 then
			return Strategies.reset("level8", "Did not reach level 8 before Brock", Pokemon.getExp(), false)
		end
		if not Combat.isPoisoned("squirtle") then
			return true
		end
		if not Inventory.contains("antidote") then
			return Strategies.reset("antidote", "Poisoned, but we risked skipping the antidote")
		end
	end
	return strategyFunctions.antidote()
end

-- 2: BROCK

strategyFunctions.shopPewterMart = function()
	return Shop.transaction {
		buy = {
			{name="pokeball", index=0, amount=3},
			{name="antidote", index=3, amount=4},
			{name="potion", index=1, amount=9},
			{name="escape_rope", index=2, amount=1},
			{name="paralyze_heal", index=6, amount=2},
			-- {name="awakening", index=5, amount=1},
		}
	}
end

strategyFunctions.bugCatcher = function()
	if Strategies.trainerBattle() then
		if Pokemon.isOpponent("caterpie") and Combat.isPoisoned() and Inventory.contains("antidote") then
			Inventory.use("antidote", nil, true)
			return false
		end
		Battle.automate()
	elseif status.foughtTrainer then
		return true
	end
end

-- 3: MISTY

-- 4: NUGGET BRIDGE

-- evolveInBattle

strategyFunctions.shopVermilionMart = function()
	if Strategies.initialize() then
		Strategies.setYolo("vermilion")
	end
	return Shop.transaction {
		sell = {},
		buy = {{name="super_potion",index=1,amount=7}, {name="repel",index=5,amount=3}}
	}
end

-- epicCutscene

-- trashcans

-- 5: SURGE

-- getBicycle

strategyFunctions.shopTM05 = function()
	return Shop.transaction {
		direction = "Up",
		buy = {{name="mega_kick", index=6}},
		sell = {{name="nugget"}, {name="paralyze_heal"}, {name="awakening"}, {name="thunderbolt"}, {name="potion"}, {name="pokeball"}, {name="tm34"}},
	}
end

strategyFunctions.shopVendWaters = function()
	return Shop.vend {
		direction = "Up",
		buy = {{name="fresh_water",index=0,amount=2}}
	}
end

-- giveWater

strategyFunctions.shopBuffs = function()
	return Shop.transaction {
		direction = "Up",
		buy = {{name="x_accuracy",index=0,amount=7}, {name="x_speed",index=5,amount=5}, {name="x_attack",index=3,amount=4}, {name="x_special",index=6,amount=12}}

	}
end


-- PROCESS

function Strategies.initGame(midGame)
	if midGame then
		-- Strategies.setYolo("", true)
		local attDV, defDV, spdDV, sclDV = Pokemon.getDVs("squirtle", "wartortle", "blastoise")
		stats.squirtle = {
			attackDV = attDV,
			defenseDV = defDV,
			speedDV = spdDV,
			specialDV = sclDV,
		}
	end
end

function Strategies.completeGameStrategy()
	status = Strategies.status
end

function Strategies.resetGame()
	status = Strategies.status
	stats = Strategies.stats
end

return Strategies
