-- see media\lua\server\Items\Distributions.lua
local insertByItemName = {}
local insertByTableName = {}

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
  print("Parsing config file loot.ini ...")
  
  local section = ""
  
  while true do
    local line = reader:readLine()
    
    if line == nil then
      break
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
            insertByItemName[key] = tonumber(value)
          elseif section == "InsertByTable" then
            insertByTableName[key] = tonumber(value)
          end
        end
      end
    end
  end

  reader:close()
end

local function insertAllTvShowTapes(items, chance)
  for n=1, 25 do
    table.insert(items, "TapedTvShows.VideoTape" .. n)
    table.insert(items, tonumber(chance))
  end
end

local function modifyLootTable(key, items)
  --print("modifyLootTable " .. key)
  
  -- insert by looking for a key item in the table
  for i=1, #items, 2 do
    local lootName = items[i]
    
    for itemName, chance in pairs(insertByItemName) do
      if itemName == lootName then
        print(string.format("[TapedTvShows] Inserting tapes into loot table \"%s\" because of item key \"%s\" with chance %f ...", key, itemName, chance))
        insertAllTvShowTapes(items, chance)
        return true -- loot table was changed, we're done with this table
      end
    end
  end
  
  -- insert by directly specifying the table's name
  for tableName, chance in pairs(insertByTableName) do
    if tableName == key then
      print(string.format("[TapedTvShows] Inserting tapes into loot table \"%s\" because of table key \"%s\" with chance %f ...", key, tableName, chance))
      insertAllTvShowTapes(items, chance)
      return true -- loot table was changed, we're done with this table
    end
  end
  
  return false
end

local configFile = getModFileReader("TapedTvShows", "loot.ini", false)

if configFile == nil then -- fileExists()
  -- create the config file
  createDefaultConfigFile()
  configFile = getModFileReader("TapedTvShows", "loot.ini", false)
end

-- read values from the file and update local vars
parseConfigFile(configFile)

local function preDistributionMerge()
  --print("[TapedTvShows] preDistributionMerge")

  for k1, v1 in pairs(SuburbsDistributions) do
    local items = v1["items"]
    local junk
    
    if items then
      if not modifyLootTable(k1, items) then
        junk = v1["junk"]
      
        if junk and junk["items"] then
          modifyLootTable(k1 .. ".junk", junk["items"])
        end
      end
    else
      for k2, v2 in pairs(v1) do
        items = v2["items"]
        
        if items then
          if not modifyLootTable(k1 .. "." .. k2, items) then
            junk = v2["junk"]
            
            if junk and junk["items"] then
              modifyLootTable(k1 .. "." .. k2 .. ".junk", junk["items"])
            end
          end
        end
      end
    end
  end
end

local function postDistributionMerge()
  if getDebug() then
    print("[TapedTvShows] postDistributionMerge")
    debugLuaTable(SuburbsDistributions, -5)
    --DeepPrintDistributionTable(SuburbsDistributions,"")
    print("---------------------------------------------")
  end
end

Events.OnPreDistributionMerge.Add(preDistributionMerge);
Events.OnPostDistributionMerge.Add(postDistributionMerge);
