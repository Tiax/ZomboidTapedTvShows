-- Overwrite the ISRadioInteractions.OnDeviceText implementation, so we can limit XP gain
--local originalISRadioInteractionsOnDeviceText = radioInteractions.OnDeviceText

TapedTvShows.playerOnDeviceText = function (player, _interactCodes, _x, _y, _z, _line, source)
  -- these are the same checks as ISRadioInteractions.checkPlayer
  local src = (not (_x==-1 and _y==-1 and _z==-1)) and getCell():getGridSquare(_x,_y,_z) or nil;
  local plrsquare = player:getSquare();
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
  
  local seen = false -- has the player seen this line?
  local playerModData = player:getModData()

  local deviceData = source:getDeviceData()
  local channel = TapedTvShows.getChannelByFreq(deviceData:getChannel())
  local broadCast = channel:getAiringBroadcast()
  
  -- get the line's UUID
  local key = broadCast:getID()
  
  -- check if it's a show we're supplying via video tape (so we don't interfere with other shows)
  if TapedTvShows.TapeMappingContains(broadCast:getID()) then
    --print(("TapedTvShows.TapeMappingContains: %q --> %s"):format(key, "true"))
    
    key = key .. ":" .. broadCast:getCurrentLineNumber()
    
    -- see if it's in the player's modData
    if playerModData["SeenDeviceText"] == nil then
      playerModData["SeenDeviceText"] = {}
    end
    
    if playerModData["SeenDeviceText"][key] ~= nil then
      -- we've already seen this, let's override the XP gains
      --print(("Seen: %s %q"):format(key, _line))
      
      local codes = _interactCodes:split(",")

      for i=1, #codes do
        local stat = codes[i]:sub(0,3)
        
        if stat == "CRP" or stat == "COO" or stat == "FRM" or stat == "DOC" or stat == "ELC" or stat == "MTL" or stat == "FIS" or stat == "TRA" or stat == "FOR" then
          -- flip a coin for BOR or STS reduction, stat may occur multiple times in list after replace, doesn't matter!
          if ZombRand(2) == 0 then
            codes[i] = "BOR-1"
          else
            codes[i] = "STS-1"
          end
        end
      end
      
      _interactCodes = table.concat(codes, ",")
    else
      -- we're seeing it for the first time, let's simply remember we saw it for next time
      --print(("Not seen: %s %q"):format(key, _line))
      playerModData["SeenDeviceText"][key] = true
    end
  else
    --print(("TapedTvShows.TapeMappingContains: %q --> %s"):format(key, "false"))
  end
  
  return _interactCodes
end

TapedTvShows.OnDeviceText = function (_interactCodes, _x, _y, _z, _line, source)
  -- mimic the original implementation, as we need to pass the source param:
  local radioInteractions = ISRadioInteractions:getInstance()
  
  if _interactCodes ~= nil and _interactCodes:len() > 0 and _line ~=nil then
    for playerNum=1, 4 do
      local player = getSpecificPlayer(playerNum-1)
      
      if player and player:isDead() then 
        player = nil 
      end

      if player ~=nil and ((_x==-1 and _y==-1 and _z==-1) or radioInteractions.playerInRange(player, _x, _y, _z)) then
        -- but instead we call our own function (may change the _interactCodes):
        _interactCodes = TapedTvShows.playerOnDeviceText(player, _interactCodes, _x, _y, _z, _line, source)
        
        -- and then we call the original implementation (grants original or changed stats)
        radioInteractions.checkPlayer(player, _interactCodes, _x, _y, _z, _line)
      end
    end
  end
end

Events.OnDeviceText.Remove(ISRadioInteractions:getInstance().OnDeviceText)
Events.OnDeviceText.Add(TapedTvShows.OnDeviceText)
