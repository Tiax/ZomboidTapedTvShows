-- see media\lua\server\Items\Distributions.lua
Distributions = Distributions or {}

local distributionTable = {
  -- will be populated dynamically from the loot.ini config file
}

local function lootTableContains(tbl, item)
  if type(tbl) ~= "table" then
    return false -- not a table...
  end

  for i=1, #tbl, 2 do
    if tbl[i] and tostring(tbl[i]) == tostring(item) then
      return true
    end
  end

  return false
end

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

local function insertByItemName(itemName, chance)
  -- go through the base game's SuburbsDistributions and look for a key item "itemName"
  -- construct a "dotted key" of the loot table, if found
  for k1, v1 in pairs(SuburbsDistributions) do
    local parts = { k1 } -- e.g. "conveniencestore", "Bag_WeaponBag", ...
    
    if v1["items"] ~= nil or v1["junk"] ~= nil then
      -- items directly on first level, usually a bag, e.g. "Bag_WeaponBag.items"
      local found = nil

      if lootTableContains(v1["items"], itemName) then
        found = "items"
      elseif lootTableContains(v1["junk"], itemName) then
        found = "junk"
      end

      if found then
        table.insert(parts, found) -- "items" or "junk"

        if getDebug() then 
          print(string.format("[TapedTvShows] Inserting tapes into loot table \"%s\" by key item \"%s\" with chance %f ...", table.concat(parts, "."), itemName, chance)) 
        end

        insertByDottedKey(parts, chance)
      end
    else
      -- items on second level, e.g. "conveniencestore.freezer.items"
      -- check in each sub table:
      for k2, v2 in pairs(v1) do
        if type(v2) == "table" then
          table.insert(parts, k2) -- e.g. "freezer"

          if lootTableContains(v2["items"], itemName) then
            table.insert(parts, "items")
          elseif v2["junk"] ~= nil and lootTableContains(v2["junk"]["items"], itemName) then
            table.insert(parts, "junk")
            table.insert(parts, "items")
          end

          if #parts > 2 then -- more than 2 levels - we got a match something
            if getDebug() then 
              print(string.format("[TapedTvShows] Inserting into loot table \"%s\" by key item \"%s\" with chance %f ...", table.concat(parts, "."), itemName, chance)) 
            end

            insertByDottedKey(parts, chance)

            while #parts > 2 do
              table.remove(parts)
            end
          end

          table.remove(parts) -- k2
        end
      end
    end
  end
end

local function insertByTableName(key, chance)
  if (key:sub(-6) ~= ".items") then
    -- assume .items, when omitted at the end
    key = key .. ".items"
  end

  print(string.format("[TapedTvShows] Inserting into loot table by table key \"%s\" with chance %f ...", key, chance)) 

  insertByDottedKey(key, chance)
end

local function createDefaultConfigFile()
  local writer = getModFileWriter("TapedTvShows", "loot.ini", true, false)
  
  writer:writeln("# TapedTvShows: loot configuration file")
  writer:writeln("")
  
  writer:writeln("[InsertByItem]")
  writer:writeln("# Insert a drop by looking for an existing item in the drop tables")
  writer:writeln("# lines below are in format: Item type=base chance to drop")
  writer:writeln("")
  
  writer:writeln("# make tapes appear anywhere CDs (Disc) appear. Covers mostly shops and shelves.")
  writer:writeln("Disc=" .. tostring(0.025))
  writer:writeln("")
  
  writer:writeln("[InsertByTable]")
  writer:writeln("# Insert a drop by directly inserting into an existing drop table")
  writer:writeln("# See ProjectZomboid\\media\\lua\\server\\Items\\Distributions.lua for the table names")
  writer:writeln("# lines below are in format: table name=base chance to drop")
  writer:writeln("")
  writer:writeln("# make tapes appear on zombie corpses")
  writer:writeln("all.inventorymale=-1.0")
  writer:writeln("all.inventoryfemale=-1.0")
  writer:writeln("")

  writer:writeln("# makes tapes appear on shelves, e.g. living rooms, general stores")
  writer:writeln("all.shelves=" .. tostring(0.025))

  writer:close()
end

local function parseConfigFile(reader)
  print("[TapedTvShows] Parsing config file \"loot.ini\"...")
  
  local section = ""
  
  while true do
    local line = reader:readLine()
    
    if line == nil then
      break -- EOF
    end
    
    if line == "" or line:sub(0, 1) ~= "#" then -- ignore empty or comments
      if line:sub(0, 1) == "[" then
        section = line:gsub("^%[%s*", ""):gsub("%s*%]$", "")
      else
        local index = line:find("=", 1, true)
        
        if index ~= nil then
          local key = line:sub(0, index-1):gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
          local value = line:sub(index+1):gsub("^%s*(.-)%s*$", "%1") -- trim whitespace

          if section == "InsertByItem" then
            insertByItemName(key, tonumber(value)) -- i.e. look for existing "CreditCard" drops in vanilla loot and insert our loot there
          elseif section == "InsertByTable" then
            insertByTableName(key, tonumber(value)) -- i.e. insert into a loot table by name, e.g. "gasstore.shelves"
          end
        end
      end
    end
  end

  reader:close()
end

local function preDistributionMerge()
  --print("[TapedTvShows] preDistributionMerge")

  local configFile = getModFileReader("TapedTvShows", "loot.ini", false)

  if configFile == nil then -- !fileExists()
    -- create the config file
    createDefaultConfigFile()
    configFile = getModFileReader("TapedTvShows", "loot.ini", false)
  end
  
  -- read values from the file and update local distributionTable accordingly
  parseConfigFile(configFile)

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
