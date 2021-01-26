-- Taped Tv Shows MOD
TapedTvShows = TapedTvShows or {};

TapedTvShows.LifeAndLivingFreq = 203 -- Life and Living TV

-- Does this IsoTelevision have a VCR Player? 
TapedTvShows.canDevicePlayTapes = function (isoTelevision)
  local data = isoTelevision:getDeviceData()
  -- Let's have all TVs, except for the antique TV, support VCR
  return data:getDeviceName() ~= "Antique Television"
end

TapedTvShows.onInsertTape = function (worldobjects, player, isoTelevision, tapeItem)
  if luautils.walkAdj(player, isoTelevision:getSquare()) then
    ISTimedActionQueue.add(ISInsertVideoTape:new(player, isoTelevision, tapeItem))
  end
end

TapedTvShows.onEjectTape = function (worldobjects, player, isoTelevision)
  if luautils.walkAdj(player, isoTelevision:getSquare()) then
    ISTimedActionQueue.add(ISEjectVideoTape:new(player, isoTelevision))
  end
end

-- Helper function to retrieve one of the game's existing broadcasts and return a clone
TapedTvShows.cloneExistingBroadCast = function (channelFrequency, broadcastUuid)
  -- we get the broadcast for our tapes from the Live and Living channel (by broadcast's uuid):
  local channel = TapedTvShows.getChannelByFreq(channelFrequency);
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

-- Helper function to retrieve a TV channel by its frequency
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

-- Helper function to return an "empty" TV channel (let's call it AV1 for nostalgia's sake) on a per-device basis we can play our broadcasts on.
-- We don't want two TVs playing the same show, when we insert a tape into one of them!
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

-- Register some events (fired by the TimedActions)
LuaEventManager.AddEvent("OnEnumerateVhsTapes")
LuaEventManager.AddEvent("OnPlayVhsTape")
LuaEventManager.AddEvent("OnEjectVhsTape")
LuaEventManager.AddEvent("OnSeeVhsTapeLine")
