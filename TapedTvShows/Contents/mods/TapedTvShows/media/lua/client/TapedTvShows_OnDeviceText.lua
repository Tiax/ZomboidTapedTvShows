-- Overwrite the ISRadioInteractions.OnDeviceText implementation, so we can limit XP gain
local originalISRadioInteractionsOnDeviceText = ISRadioInteractions:getInstance().OnDeviceText

TapedTvShows.OnDeviceText = function (_interactCodes, _x, _y, _z, _line, isoTelevision)
  local seen = false

  if _interactCodes ~= "" and isoTelevision then
    -- it's a TV broadcast line and it has interact codes
    -- check if we've already seen it
    local player = getPlayer()
    local playerModData = player:getModData()
    
    local deviceData = isoTelevision:getDeviceData()
    local channel = TapedTvShows.getChannelByFreq(deviceData:getChannel())
    local broadCast = channel:getAiringBroadcast()
    
    -- get the line's UUID
    local key = broadCast:getID() .. ":" .. broadCast:getCurrentLineNumber()
    
    -- see if it's in the player's modData
    if playerModData["SeenDeviceText"] == nil then
      playerModData["SeenDeviceText"] = {}
    end
    
    if playerModData["SeenDeviceText"][key] ~= nil then
      seen = true
    end
    
    -- remember we saw it
    playerModData["SeenDeviceText"][key] = true
  end
  
  if not seen then
    --print("Calling original \"ISRadioInteractions.OnDeviceText\"...")
    originalISRadioInteractionsOnDeviceText(_interactCodes, _x, _y, _z, _line)
  else
    --print("Skipping original \"ISRadioInteractions.OnDeviceText\"...")
  end
end

Events.OnDeviceText.Remove(originalISRadioInteractionsOnDeviceText)
Events.OnDeviceText.Add(TapedTvShows.OnDeviceText)
