-- Overwrite the ISRadioInteractions.OnDeviceText implementation, so we can limit XP gain or react in different ways to a broadcast's line
TapedTvShows = TapedTvShows or {};

TapedTvShows.playerOnDeviceText = function (player, _interactCodes, _x, _y, _z, _line, source)
  -- these are the same checks as ISRadioInteractions.checkPlayer
  local src = (not (_x==-1 and _y==-1 and _z==-1)) and getCell():getGridSquare(_x,_y,_z) or nil;
  local plrsquare = player:getSquare();
  
  --print(string.format("TapedTvShows.playerOnDeviceText player[%s] codes[%q]", tostring(player), _interactCodes))
  
  if src and src:isOutside() ~= plrsquare:isOutside() then
      return _interactCodes;
  end

  if player:isAsleep() then
      return _interactCodes;
  end
  
  -- custom handling:
  if not instanceof(source, "IsoTelevision") then
    return _interactCodes
  end

  local deviceData = source:getDeviceData()
  local channel = TapedTvShows.getChannelByFreq(deviceData:getChannel())
  local broadCast = channel:getAiringBroadcast()
  
  -- trigger OnSeeVhsTapeLine
  local codes = _interactCodes:split(",") -- pass those by reference as a table to any event to handle/override

  triggerEvent("OnSeeVhsTapeLine", player, broadCast, codes, _line, source)

  _interactCodes = table.concat(codes, ",")

  return _interactCodes
end

TapedTvShows.OnDeviceText = function (_interactCodes, _x, _y, _z, _line, source)
  -- mimic the original implementation, as we need to pass the source param:
  if _interactCodes ~= nil and _interactCodes:len() > 0 and _line ~=nil then
    for playerNum=1, 4 do
      local radioInteractions = ISRadioInteractions:getInstance()
      local player = getSpecificPlayer(playerNum-1)
      
      if player and player:isDead() then 
        player = nil
      end

      if player ~=nil and ((_x==-1 and _y==-1 and _z==-1) or radioInteractions.playerInRange(player, _x, _y, _z)) then
        -- but instead we call our own function (which may change the _interactCodes):
        --print(string.format("TapedTvShows.OnDeviceText player[%s] _interactCodes[%q] _line[%q] source[%q]", tostring(player:getPlayerNum()), tostring(_interactCodes), tostring(_line), tostring(source)))
        
        _interactCodes = TapedTvShows.playerOnDeviceText(player, _interactCodes, _x, _y, _z, _line, source)
        
        -- and then we call the original implementation (grants original or changed stats)
        radioInteractions.checkPlayer(player, _interactCodes, _x, _y, _z, _line)
      end
    end
  end
end

Events.OnDeviceText.Remove(ISRadioInteractions:getInstance().OnDeviceText)
Events.OnDeviceText.Add(TapedTvShows.OnDeviceText)
