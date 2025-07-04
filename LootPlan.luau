--!strict

-- Original Module can be found at - https://create.roblox.com/store/asset/4710697524/
-- API Documentation can be found at - https://devforum.roblox.com/t/lootplan-random-loot-generation-made-easy/463702
-- Two example scripts can be found within the explorer, inside this module

local LootPlan = {}

-- Classes --

local SingleLootPlan = {}
SingleLootPlan.__index = SingleLootPlan

local MultiLootPlan = {}
MultiLootPlan.__index = MultiLootPlan

-- Types

type SingleLoot = {
	name:string;
	weight:number;
}

type SingleProperties = {
	Randomizer: Random;
	Loot: {[string]:SingleLoot};
	LootList: {[number]:SingleLoot};
	LootCount: number;
	TotalWeight: number;
}

export type SingleLootPlan = typeof(setmetatable({}::SingleProperties, SingleLootPlan))

type MultiLoot = {
	name:string;
	chance:number;
}

type MultiProperties = {
	Randomizer: Random;
	Loot: {[string]:MultiLoot};
}

export type MultiLootPlan = typeof(setmetatable({}::MultiProperties, MultiLootPlan))

--> SingleLootPlan <--

function SingleLootPlan.new(seed:number?) : SingleLootPlan
	local SingleLootPlan = setmetatable({},SingleLootPlan)
	SingleLootPlan.Randomizer = Random.new(seed or (tick()%1)*1e10)
	SingleLootPlan.Loot = {}
	SingleLootPlan.LootList = {}
	SingleLootPlan.LootCount = 0
	SingleLootPlan.TotalWeight = 0
	return SingleLootPlan
end

-- adds loot at a specific weight. the more weight, the higher the chance in proportion to other loot
function SingleLootPlan.AddLoot(self:SingleLootPlan, name:string, weight:number)
	if self.Loot[name] then
		error(`Error adding loot: Loot "{name}"" already exists.`)
	end
	local newLoot: SingleLoot = {
		name = name;
		weight = weight;
	}
	self.Loot[name] = newLoot
	self.LootCount += 1
	self.TotalWeight += weight
	self:_updateLootList()
	return self
end

-- adds loot from a table
function SingleLootPlan.AddLootFromTable(self:SingleLootPlan, list:{[string]:number})
	for name, chance in list do
		self:AddLoot(name, chance)
	end
	return self
end

-- returns loot weight used for calculating chance
function SingleLootPlan.GetLootWeight(self:SingleLootPlan, name:string)
	local loot = self.Loot[name]
	if loot then
		return loot.weight
	else
		error("Error getting weight: Loot with name '"..tostring(name).."' does not exist")
	end
end

-- returns loot chance as percentage, after adjusting for total weight
function SingleLootPlan.GetLootChance(self:SingleLootPlan, name:string)
	local loot = self.Loot[name]
	if loot then
		return (loot.weight/self.TotalWeight)*100
	else
		error("Error getting chance: Loot with name '"..tostring(name).."' does not exist")
	end
end

function SingleLootPlan.RemoveLoot(self:SingleLootPlan, name:string)
	local loot = self.Loot[name]
	if loot then
		self.TotalWeight -= loot.weight
		self.LootCount -= 1
		self.Loot[name] = nil
		self:_updateLootList()
	end
	return self
end

function SingleLootPlan.ChangeLootWeight(self:SingleLootPlan, name:string, weight:number)
	local loot = self.Loot[name]
	if loot then
		self.TotalWeight += weight - loot.weight
		loot.weight = weight
		self:_updateLootList()
	else
		error("Error changing weight: Loot with name '"..tostring(name).."' does not exist")
	end
	return self
end

function SingleLootPlan.GetRandomLoot(self:SingleLootPlan, luck:number?) : string
	local luck = luck or 1
	local lootName: string
	if luck >= 1 then
		local total = self.TotalWeight
		local result = self.Randomizer:NextNumber()
		local aggregate = 0
		for i, loot in self.LootList do
			local chance = loot.weight * luck
			if result < (chance + aggregate) / total then
				lootName = loot.name
				break
			end
			aggregate += chance
		end
	else
		local luck = 1/luck
		local total = self.TotalWeight
		local result = self.Randomizer:NextNumber()
		local aggregate = 0
		for i = self.LootCount, 1, -1 do
			local loot = self.LootList[i]
			local chance = loot.weight * luck
			if result < (chance + aggregate) / total then
				lootName = loot.name
				break
			end
			aggregate += chance
		end
	end
	return lootName
end

function SingleLootPlan._updateLootList(self:SingleLootPlan)
	local LootList = {}

	for Name,Loot in self.Loot do
		table.insert(LootList, Loot)
	end

	table.sort(LootList, function(a,b)
		return a.weight < b.weight
	end)

	self.LootList = LootList

	return self
end

--> MultiLootPlan <--

function MultiLootPlan.new(seed:number?)
	local MultiLootPlan = setmetatable({},MultiLootPlan)
	MultiLootPlan.Randomizer = Random.new(seed or (tick()%1)*1e10)
	MultiLootPlan.Loot = {}
	return MultiLootPlan
end

function MultiLootPlan.AddLoot(self:MultiLootPlan, name:string, chance:number)
	local newLoot: MultiLoot = {
		name = name;
		chance = chance;
	}
	self.Loot[name]=newLoot
	return self
end

function MultiLootPlan.AddLootFromTable(self:MultiLootPlan, list:{[string]:number})
	for name, chance in list do
		self:AddLoot(name, chance)
	end
	return self
end

function MultiLootPlan.GetLootChance(self:MultiLootPlan, name:string)
	local loot = self.Loot[name]
	if loot then
		return loot.chance
	else
		error("Error getting chance: Loot with name '"..tostring(name).."' does not exist")
	end
end

function MultiLootPlan.RemoveLoot(self:MultiLootPlan, name:string)
	self.Loot[name] = nil
	return self
end

function MultiLootPlan.ChangeLootChance(self:MultiLootPlan, name:string, newChance:number)
	local loot = self.Loot[name]
	if loot then
		loot.chance = newChance
	else
		error("Error changing chance: Loot with name '"..tostring(name).."' does not exist")
	end
	return self
end

function MultiLootPlan.GetRandomLoot(self:MultiLootPlan, luck:number?, iterations:number?)
	local LootTable = {} :: {[string]:number}
	for i = 1, iterations or 1 do
		for name,loot in self.Loot do
			local result = self.Randomizer:NextNumber()
			local chance = (loot.chance/100) * (luck or 1)
			if result < chance then
				LootTable[name] = LootTable[name] and LootTable[name]+1 or 1
			end
		end
	end
	return LootTable
end

return {
	newSingle = SingleLootPlan.new;
	newMulti = MultiLootPlan.new;
}
