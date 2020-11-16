-- TapedTvShows.lua
TapedTvShows = TapedTvShows or {};

TapedTvShows.TapeMapping = {
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

TapedTvShows.LifeAndLivingFreq = 203 -- Life and Living TV

-- contextmenu on a telly, let's offer playing tapes!
TapedTvShows.createVcrPlayerMenu = function(playerIndex, context, worldObjects, test)
  if test and ISWorldObjectContextMenu.Test then 
    return true 
  end
  
  --print(string.format("TapedTvShows.createVcrPlayerMenu player[%d] worldObject[%q] test[%s]", playerIndex, tostring(v), tostring(test)))
  
  local isoTelevision = nil
  
  for _, v in ipairs(worldObjects) do
    local square = v:getSquare()
    
    if square then
      for i=0, square:getObjects():size() - 1 do
        local object2 = square:getObjects():get(i)
        if instanceof(object2, "IsoTelevision") then
          isoTelevision = object2
        end
      end
    end
  end
    
  if not isoTelevision then
    return
  end

  if test then
    return ISWorldObjectContextMenu.setTest()
  end
  
  -- found a TV, let's look for tapes in the player's inventory
  local player = getSpecificPlayer(playerIndex)
  local modData = isoTelevision:getModData()
  local deviceData = isoTelevision:getDeviceData()

  local subMenu = ISContextMenu:getNew(context)

  -- check if the television is tape compatible
  if not TapedTvShows.canDevicePlayTapes(isoTelevision) then
    return
  end
  
  if modData["VhsTapeItem"] or (modData["movableData"] and modData["movableData"]["VhsTapeItem"]) then
    -- TV has a tape in it -> Eject option
    subMenu:addOption(getText("ContextMenu_VCR_EjectVideoTape"), worldObjects, TapedTvShows.onEjectTape, player, isoTelevision)
  else
    -- look for tapes in player's inventory and offer to play them
    local lstTapes = player:getInventory():getAllEvalRecurse(TapedTvShows.isVideoTape, ArrayList.new())
    local seen = {} -- list each tape only once
    
    if not lstTapes:isEmpty() then
      for i=0, lstTapes:size() - 1 do
        local tape = lstTapes:get(i)
        
        if not seen[tape:getType()] then
          seen[tape:getType()] = true
          local option = subMenu:addOption(getText("ContextMenu_VCR_InsertVideoTape", tape:getDisplayName()), worldObjects, TapedTvShows.onInsertTape, player, isoTelevision, tape)
          local tooltip = ISWorldObjectContextMenu.addToolTip()
          tooltip.name = getText("ContextMenu_VCR_InsertVideoTape_ToolTip_Title", tape:getDisplayName())
          tooltip.description = getText("ContextMenu_VCR_InsertVideoTape_ToolTip_Text", tape:getTooltip())
          tooltip:setTexture(tape:getTexture():getName())
          option.toolTip = tooltip
        end
      end
    end
  end

  if getDebug() then
    TapedTvShows.addDebugMenuOptions(subMenu, player, isoTelevision) -- debug options
  end
  
  if subMenu.numOptions > 1 then -- I don't know why this is off by one
    context:addSubMenu(context:addOption(getText("ContextMenu_VCR_Menu"), worldobjects, nil), subMenu)
  end
end

TapedTvShows.isVideoTape = function (item)
  return string.sub(item:getType(), 1, string.len("VideoTape")) == "VideoTape"
end

TapedTvShows.canDevicePlayTapes = function (isoTelevision)
  local data = isoTelevision:getDeviceData()
  return data:getDeviceName() ~= "Antique Television"
end

TapedTvShows.onInsertTape = function (worldobjects, player, isoTelevision, tapeItem)
  if luautils.walkAdj(player, isoTelevision:getSquare()) then
    ISTimedActionQueue.add(ISInsertVideoTape:new(player, isoTelevision, tapeItem))
  end
end

TapedTvShows.playBroadCastFromTape = function (player, isoTelevision, tapeItem)
  local deviceData = isoTelevision:getDeviceData()
  
  -- remove the tape from the player's inventory
  local tapeId = tapeItem:getID()
  local playerInventory = player:getInventory()
  playerInventory:removeItemWithIDRecurse(tapeId)
  playerInventory:setDrawDirty(true)
  
  -- store the tape "in" the IsoTelevision
  local modData = isoTelevision:getModData()
  
  if modData["movableData"] == nil then
    modData["movableData"] = {}
  end
  
  --modData["VhsTapeItem"] = tostring(tapeItem:getFullType())
  modData["movableData"]["VhsTapeItem"] = tostring(tapeItem:getFullType())
  
  -- retrieve TV's "VHS channel", switch to it and play tape "as broadcast"
  local uuid = TapedTvShows.getBroadCastUuidForTape(tapeItem)
  local broadcast = TapedTvShows.retrieveBroadCast(uuid)
  
  if broadcast == nil then
    return false -- no broadcast assigned?!
  end

  -- set the channel to broadcast and switch to it:
  local channel = TapedTvShows.getVhsChannel(isoTelevision)
  channel:setAiringBroadcast(broadcast);
  deviceData:setChannelRaw(channel:GetFrequency())
end

TapedTvShows.onEjectTape = function (worldobjects, player, isoTelevision)
  if luautils.walkAdj(player, isoTelevision:getSquare()) then
    ISTimedActionQueue.add(ISEjectVideoTape:new(player, isoTelevision))
  end
end

TapedTvShows.stopBroadCastEjectTape = function (player, isoTelevision)
  -- stop the broadcast and TV animation
  local deviceData = isoTelevision:getDeviceData()
  local channel = TapedTvShows.getVhsChannel(isoTelevision)
  
  channel:setActiveScriptNull()

  deviceData:cleanSoundsAndEmitter()
  deviceData:playSoundSend("RadioButton", true)
  deviceData:setRandomChannel()

  -- delete the channel
  getZomboidRadio():getScriptManager():RemoveChannel(channel:GetFrequency())

  isoTelevision:update()

  -- return the tape to the player and remove it from the TV
  local modData = isoTelevision:getModData()

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

TapedTvShows.getBroadCastUuidForTape = function (tapeItem)
  local k = TapedTvShows.TapeMapping[tapeItem:getType()]
  
  if k ~= nil then
    return k
  end
  
  return nil
end

TapedTvShows.retrieveBroadCast = function (broadcastUuid)
  local channel = TapedTvShows.getLifeAndLivingChannel();
  local script = channel:getRadioScript("main")
  
  -- we need to clone the broadcast here to avoid any unwanted behavior from altering the existing shows
  -- first, grab the original BC from the RadioScript
  local broadcastList = script:getBroadcastList() -- ArrayList<RadioBroadCast>
  local origBc = nil -- Note: script:getBroadcastWithID() does some other stuff we don't want
  
  for i = 0, broadcastList:size() - 1 do
    local bc = broadcastList:get(i)
    
    if bc:getID() == broadcastUuid then
      origBc = bc
      break;
    end
  end
  
  if not origBc then
    return nil -- could not find broadcast?
  end
  
  -- now create a new RadioBroadCast with the same properties
  local bc = RadioBroadCast.new(origBc:getID(), -1, -1);
  local origLines = origBc:getLines()
  
  for i = 0, origLines:size() - 1 do
    local line = origLines:get(i)
    bc:AddRadioLine(RadioLine.new(line:getText(), line:getR(), line:getG(), line:getB(), line:getEffectsString()))
  end

  --bc:setPreSegment(nil)
  --bc:setPostSegment(nil)
  --bc:resetLineCounter()
  
  return bc
end

TapedTvShows.onDebugSpawnTape = function (worldobjects, player, tv)
  local n = ZombRand(25) + 1 -- [1..25]
  print("DEBUG: Spawning tape ", n)
  player:getInventory():AddItem("TapedTvShows.VideoTape" .. n)
end

TapedTvShows.onDebugPlayShow = function (worldobjects, player, tv)
  local deviceData = tv:getDeviceData()
  --local radioApi = getRadioAPI()
  
  local channel = TapedTvShows.getVhsChannel(tv)
  local broadcast = TapedTvShows.retrieveBroadCast("d969e014-5392-469d-9981-1e93d12ccfac") -- day 0 cooking show: You're back with the Cook Show! / Brought to you by Kitten Knives - Fine American Cookware
  
  channel:setAiringBroadcast(broadcast);

  -- set the TV to the channel
  deviceData:setChannel(channel:GetFrequency())
end

TapedTvShows.addDebugMenuOptions = function (menu, player, isoTelevision)
  local modData = isoTelevision:getModData()
  
  --menu:addOption("DEBUG: PLAY A SHOW", worldObjects, TapedTvShows.onDebugPlayShow, player, isoTelevision)
  menu:addOption("DEBUG: Spawn Video Tape", worldObjects, TapedTvShows.onDebugSpawnTape, player, isoTelevision)
  
  local tmp = menu:addOption("DEBUG: IsoTelevision.modData")
  local tt = ISWorldObjectContextMenu.addToolTip()
  tt.name = "ModData"
  tt.description = BCRC.dump(modData)
  tmp.toolTip = tt
  
  local tmp = menu:addOption("DEBUG: Player.modData", worldObjects, function () 
    player:getModData()["SeenDeviceText"] = {} 
  end)
  
  local tt = ISWorldObjectContextMenu.addToolTip()
  tt.name = "ModData"
  tt.description = BCRC.dump(player:getModData()["SeenDeviceText"]) .. "<br><br>Click to CLEAR"
  tmp.toolTip = tt
end

TapedTvShows.getChannelByFreq = function (freq)
  local channels = getZomboidRadio():getScriptManager():getChannelsList()
  local result = nil
  
  for i = 0, channels:size() - 1 do
    if channels:get(i):GetFrequency() == freq then
      result = channels:get(i)
      break
    end
  end
  
  return result
end

TapedTvShows.getLifeAndLivingChannel = function ()
  return TapedTvShows.getChannelByFreq(TapedTvShows.LifeAndLivingFreq)
end

TapedTvShows.getVhsChannel = function (isoTelevision)
  local deviceData = isoTelevision:getDeviceData()
  
  -- note: setting frequency outside of maxChannelRange will prevent it from being added to channel presets. what could go wrong? :D
  local freq = deviceData:getMaxChannelRange() + isoTelevision:getSquare():getID() 
  
  -- look for an existing channel for vhs tapes for this telly
  local channel = TapedTvShows.getChannelByFreq(freq)
  
  if channel ~= nil then
    --print("Using existing vhs channel @ freq=", channel:GetFrequency(), " uuid=", channel:getGUID())
  else  
    -- create a new one, if neccessary
    channel = DynamicRadioChannel.new("(AV1)", freq, ChannelCategory.Television); -- random UUID
    channel:setTimeSynced(false)
    --print("Created new vhs channel @ freq=", channel:GetFrequency(), " uuid=", channel:getGUID())
    getZomboidRadio():getScriptManager():AddChannel(channel, false)
  end
  
  return channel
end

TapedTvShows.TapeMappingContains = function (key)
  for _, v in pairs(TapedTvShows.TapeMapping) do
    if v == key then
      return true
    end
  end
  
  return false
end

Events.OnFillWorldObjectContextMenu.Add(TapedTvShows.createVcrPlayerMenu)
