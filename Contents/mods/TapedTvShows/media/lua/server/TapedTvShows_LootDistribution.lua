-- see media\lua\server\Items\Distributions.lua
Distributions = Distributions or {}
ProceduralDistributions = ProceduralDistributions or {}
VehicleDistributions = VehicleDistributions or {}

local distributionTable = {
  -- will be populated dynamically from the loot.ini config file
}

local function insertAllTvShowTapes(tbl, chance)
  for n=1, 25 do
    table.insert(tbl, "TapedTvShows.VideoTape" .. n)
    table.insert(tbl, tonumber(chance))
  end
end

local function insertByDottedKey(key, chance)
  local parts

  if type(key) == "table" then
    parts = key -- key is a table of parts
  else -- assume string: key is a dot delimited string, let's split it into parts
    parts = {}
    for part in key:gmatch("[^.]+") do
      table.insert(parts, part)
    end
  end

  local node = distributionTable -- start at root node

  -- make sure all the sub tables exist, before trying to add stuff to the leaf node
  for i, part in ipairs(parts) do
    if node[part] == nil then
      node[part] = {}
    end

    node = node[part]
  end

  -- all sub tables created -> we can start inserting our stuff
  insertAllTvShowTapes(node, chance)
end

local function preDistributionMerge()
  --print("[TapedTvShows] preDistributionMerge")

  -- TODO: We might revisit the loot.ini method later.
  -- The 41.52 update broke most of it, anyway

  local cookingTapes = { 2, 5, 8, 11, 14, 17, 20, 23, 25 }
  local woodcraftTapes = { 3, 6, 9, 12, 15, 18, 21, 24 }
  local survivalTapes = { 1, 4, 7, 10, 13, 16, 19, 22, 24 }
  local farmingTapes = { 7 }
  local trappingTapes = { 19 }
  local foragingTapes = { 16, 22 }
  local fishingTapes = { 1, 4, 10 }

  -- Make all tapes appear on Zombie Corpses (rarely)
  -- make sure "junk" exists on inventorymale/female
  distributionTable = {
    ["all"] = {
      ["inventorymale"] = {
        junk = {
          rolls = 1,
          items = {}
        }
      },
      ["inventoryfemale"] = {
        junk = {
          rolls = 1,
          items = {}
        }
      }
    }
  }
  
  insertByDottedKey("all.inventorymale.junk.items", 0.01)
  insertByDottedKey("all.inventoryfemale.junk.items", 0.01)
  
  -- Make all tapes appear in these procedural loot lists:
  insertAllTvShowTapes(ProceduralDistributions.list["CrateBooks"].items, 0.25)
  insertAllTvShowTapes(ProceduralDistributions.list["CrateElectronics"].items, 0.5)
  insertAllTvShowTapes(ProceduralDistributions.list["CrateMagazines"].items, 0.1)
  insertAllTvShowTapes(ProceduralDistributions.list["CrateTV"].items, 5)
  insertAllTvShowTapes(ProceduralDistributions.list["CrateTVWide"].items, 10)
  insertAllTvShowTapes(ProceduralDistributions.list["ElectronicStoreMagazines"].items, 0.1)
  insertAllTvShowTapes(ProceduralDistributions.list["GigamartHouseElectronics"].items, 0.2)
  insertAllTvShowTapes(ProceduralDistributions.list["LivingRoomShelf"].items, 0.1)
  insertAllTvShowTapes(ProceduralDistributions.list["StoreShelfElectronics"].items, 0.1)
  
  -- Make all tapes appear in TV/Radio vehicle loot
  insertAllTvShowTapes(VehicleDistributions["Radio"]["TruckBed"].items, 1.0)

  -- Make all Fishing tapes appear in related crates & shelves
  for _, v in ipairs(fishingTapes) do
    -- Note: this table has 0 rolls in current version. Probably unused, at this time...
    table.insert(ProceduralDistributions.list["CrateFishing"].items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["CrateFishing"].items, 5.0)
  end

  -- Make all Cooking tapes appear in related crates & shelves
  for _, v in ipairs(cookingTapes) do
    table.insert(ProceduralDistributions.list["KitchenBook"].items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["KitchenBook"].items, 0.6)
  end
  
  -- Make all Carpentry tapes appear in related crates & shelves
  for _, v in ipairs(woodcraftTapes) do
    table.insert(ProceduralDistributions.list["GarageCarpentry"].items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["GarageCarpentry"].items, 0.5)
    
    table.insert(ProceduralDistributions.list["CrateTools"].items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["CrateTools"].items, 0.5)
  end
  
  -- Make all Farming tapes appear in related crates & shelves
  for _, v in ipairs(farmingTapes) do
    table.insert(ProceduralDistributions.list["CrateFarming"].items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["CrateFarming"].items, 1.0)
    
    table.insert(ProceduralDistributions.list["GardenStoreMisc"].items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["GardenStoreMisc"].items, 1.0)
    
    table.insert(ProceduralDistributions.list["GigamartFarming"].items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["GigamartFarming"].items, 2.0)
  end

  -- Make all Exposure Survival tapes appear in related crates & shelves:
  for _, v in ipairs(survivalTapes) do
    table.insert(ProceduralDistributions.list["CampingStoreBooks"].junk.items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["CampingStoreBooks"].junk.items, 10.0)
    
    -- Note: this distribution does not currently seem to be in use...
    table.insert(ProceduralDistributions.list["CrateCamping"].items, "TapedTvShows.VideoTape" .. v)
    table.insert(ProceduralDistributions.list["CrateCamping"].items, 0.2)
  end
  
  -- add our loot table additions to the end of Distributions, so the game will take care of merging it
  table.insert(Distributions, distributionTable)
  
  -- dump our loot table additions to logfile in debug mode:
  if getDebug() then
    print("[TapedTvShows] preDistributionMerge: distributionTable =")
    debugLuaTable(distributionTable, -5)
    print("[TapedTvShows] -----------------------------------------")
  end
end

local function postDistributionMerge()
  -- dump the final loot table (post merge) to logfile in debug mode:
  if getDebug() then
    print("[TapedTvShows] postDistributionMerge: SuburbsDistributions =")
    debugLuaTable(SuburbsDistributions, -5)
    print("[TapedTvShows] ---------------------------------------------")
  end
end

Events.OnPreDistributionMerge.Add(preDistributionMerge);
Events.OnPostDistributionMerge.Add(postDistributionMerge);
