TapedTvShows = TapedTvShows or {};

-- See media\radio\RadioData.xml
local TapeMapping = {
  ["VideoTape1"]  = "465ef67d-21a8-4c22-a6f4-257eea64e8a3", -- Exposure Survival, day 0
  ["VideoTape2"]  = "75d511c5-cb3f-41cc-81c9-b47df52957ae", -- Cookshow, day 0
  ["VideoTape3"]  = "aece616a-4883-4e09-bd35-39aed89fe655", -- Woodcraft, day 0
  ["VideoTape4"]  = "4e3d8faf-8e30-4f80-9eac-a7fcb32b3900", -- Exposure Survival, day 0
  ["VideoTape5"]  = "87fd2783-9fe4-4605-becf-5875a5616f28", -- Cookshow, day 1
  ["VideoTape6"]  = "0f2c6233-c94b-4cfc-933a-64a20d41c803", -- Woodcraft, day 1
  ["VideoTape7"]  = "42301cfa-ead1-4c3f-81db-b7369279aa4c", -- Exposure Survival, day 1
  ["VideoTape8"]  = "a24b3295-6241-401c-a7d2-0c1bf0bba426", -- Cook Show, day 2
  ["VideoTape9"]  = "c8da05a5-8df9-4969-af46-65f415a0d321", -- Woodcraft, day 2
  ["VideoTape10"] = "e7f7c2e2-ec25-4098-99be-f9f423a2e79a", --  Exposure Survival, day 2
  ["VideoTape11"] = "d969e014-5392-469d-9981-1e93d12ccfac", -- Cook Show, day 3
  ["VideoTape12"] = "8d8676b0-4498-47ad-830a-01c584b46eb7", -- Woodcraft, day 3
  ["VideoTape13"] = "cae4e722-4ef4-4553-b926-542341ad9192", -- Exposure Survival, day 3; this one only gives minus BOR?!
  ["VideoTape14"] = "48af015e-a0fa-4d24-b0fd-006d107d9069", -- Cook Show, day 4
  ["VideoTape15"] = "f1b5054b-6152-418f-993c-ad477bdbd0ce", -- Woodcraft, day 4
  ["VideoTape16"] = "3166434a-ce11-4df5-acb6-4a023bb45c67", -- Exposure Survival, day 4
  ["VideoTape17"] = "18dce784-0448-4b0e-8cba-18d16d2b6601", -- Cook Show, day 5
  ["VideoTape18"] = "6c8629da-1997-4087-ad9d-f4908e7a8b39", -- Woodcraft, day 5
  ["VideoTape19"] = "40dacfdc-3473-40e8-8276-eb5faf42dea3", -- Exposure Survival, day 5
  ["VideoTape20"] = "3f4b01a9-a596-4445-9adb-128e95e1ed3e", -- Cook show, day 6
  ["VideoTape21"] = "35a2653b-10db-423a-8dfa-fb0e31a01200", -- Woodcraft, day 6
  ["VideoTape22"] = "c20ef080-6050-4a1c-8428-277f61010dcf", -- Exposure Survival, day 6
  ["VideoTape23"] = "7cb6038a-1f23-440a-ad95-68d01a657885", -- Cook Show, day 7
  ["VideoTape24"] = "7a1469c5-0f2f-48e4-b8e6-df2ead207b53", -- Exposure Survival, day 7
  ["VideoTape25"] = "a06dd29c-78cf-4a0b-bba9-600a517bf4a4", -- Cook Show, day 8
}

-- returns the existing broadcast ID according to TapeMapping
local getBroadCastUuidForTape = function (tapeItem)
  local k = TapeMapping[tapeItem:getType()]
  
  if k ~= nil then
    return k
  end
  
  return nil
end

-- wrapper for TapeMapping table
local tapeMappingContains = function (key)
  for _, v in pairs(TapeMapping) do
    if v == key then
      return true
    end
  end
  
  return false
end

-- checks whether an InventoryItem is a relevant tape for this mod
local isRelevantVideoTape = function (item)
  if item == nil or not instanceof(item, "InventoryItem") then
    return false
  end

  if string.sub(item:getFullType(), 1, string.len("TapedTvShows.VideoTape")) == "TapedTvShows.VideoTape" then
    return true
  end
  
  return false
end

-- Implement the OnEnumerateVhsTapes event:
-- Populate the table "tapes" with relevant items from the player's inventory
local OnEnumerateVhsTapes = function (player, tapes, tv)
  local tapesInInventory = player:getInventory():getAllEvalRecurse(isRelevantVideoTape, ArrayList.new())

  for i = 0, tapesInInventory:size() - 1 do
    local tape = tapesInInventory:get(i)
    
    -- make sure we only put each unique tape once
    if tapes[tape:getFullType()] == nil then
      tapes[tape:getFullType()] = tape
    end
  end

end

-- Implement the OnPlayVhsTape event:
-- Generate a new broadcast or retrieve an existing one and play it on the channel
local OnPlayVhsTape = function (player, tape, tv, channel)
  if not isRelevantVideoTape(tape) then
    return false -- not one of "our" tapes
  end
  
  local deviceData = tv:getDeviceData()
  local modData = tv:getModData()

  -- retrieve the respective broadcast
  local uuid = getBroadCastUuidForTape(tape)
  
  if uuid == nil then
    return false -- unknown tape?
  end
  
  local broadcast = TapedTvShows.cloneExistingBroadCast(TapedTvShows.LifeAndLivingFreq, uuid)
  
  if broadcast == nil then
    return false -- no broadcast assigned?
  end
  
  -- store the tape "in" the IsoTelevision
  if modData["movableData"] == nil then
    modData["movableData"] = {}
  end
  
  modData["movableData"]["VhsTapeItem"] = tostring(tape:getFullType())
  
  -- remove the tape from the player's inventory
  local playerInventory = player:getInventory()
  playerInventory:removeItemWithIDRecurse(tape:getID())
  playerInventory:setDrawDirty(true)

  -- set the AV1 channel to send our broadcast and switch to it:
  channel:setAiringBroadcast(broadcast);
  deviceData:setChannelRaw(channel:GetFrequency())

end

-- Implement the OnEjectVhsTape event:
-- Stop any current playback and return the correct tape item to the player's inventory
local OnEjectVhsTape = function (player, tv, channel)
  -- stop the broadcast and TV animation
  local deviceData = tv:getDeviceData()
  
  deviceData:setRandomChannel()
  deviceData:cleanSoundsAndEmitter()
  deviceData:playSoundSend("RadioButton", true)

  channel:setActiveScriptNull()

  -- delete the AV1 channel
  getZomboidRadio():getScriptManager():RemoveChannel(channel:GetFrequency())

  -- return the tape to the player and remove it from the TV
  local modData = tv:getModData()

  if modData["VhsTapeItem"] or (modData["movableData"] and modData["movableData"]["VhsTapeItem"]) then
    local tapeItem = modData["VhsTapeItem"] -- legacy key
    
    if tapeItem == nil then
      tapeItem = modData["movableData"]["VhsTapeItem"] -- new key in movableData
    end
    
    player:getInventory():AddItem(tapeItem)
    player:getInventory():setDrawDirty(true)
    
    modData["VhsTapeItem"] = nil
    
    if modData["movableData"] ~= nil then
      --modData["movableData"] = {}
      modData["movableData"]["VhsTapeItem"] = nil
    end

  end
end

-- Implement the OnSeeVhsTapeLine event:
-- Do something, when a broadcast line is seen.
-- For Life and Living shows, we should make sure we don't get XP multiple times!
local OnSeeVhsTapeLine = function (player, broadCast, codes, line)
  -- check if it's a show we're supplying via video tape (so we don't interfere with other broadcasts etc.)
  local key = broadCast:getID() .. ":" .. broadCast:getCurrentLineNumber()

  if tapeMappingContains(broadCast:getID()) then
    --print(("TapedTvShows.TapeMappingContains: %q --> %s"):format(key, "true"))
    
    -- see if it's in the player's modData
    local playerModData = player:getModData()

    if playerModData["SeenDeviceText"] == nil then
      playerModData["SeenDeviceText"] = {}
    end

    if playerModData["SeenDeviceText"][key] ~= nil then
      -- we've already seen this, let's override the XP gains
      --print(("Seen: %s %q"):format(key, line))

      for i=1, #codes do
        local stat = codes[i]:sub(0,3)
        
        if stat ~= "BOR" and stat ~= "STS" and stat ~= "UHP" then
          -- stat == "CRP" or stat == "COO" or stat == "FRM" or stat == "DOC" or stat == "ELC" or stat == "MTL" or stat == "FIS" or stat == "TRA" or stat == "FOR"
          -- flip a coin for BOR or STS reduction, stat may occur multiple times in list after replace, doesn't matter!
          if ZombRand(2) == 0 then
            codes[i] = "BOR-1"
          else
            codes[i] = "STS-1"
          end
        end
      end
    else
      -- we're seeing it for the first time, let's simply remember we saw it for next time
      --print(("Not seen: %s %q"):format(key, line))
      playerModData["SeenDeviceText"][key] = true
    end
  else
    --print(("TapedTvShows.TapeMappingContains: %q --> %s"):format(key, "false"))
  end
end

Events.OnEnumerateVhsTapes.Add(OnEnumerateVhsTapes)
Events.OnPlayVhsTape.Add(OnPlayVhsTape)
Events.OnEjectVhsTape.Add(OnEjectVhsTape)
Events.OnSeeVhsTapeLine.Add(OnSeeVhsTapeLine)
