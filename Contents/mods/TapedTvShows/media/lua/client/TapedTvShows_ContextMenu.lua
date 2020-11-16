TapedTvShows = TapedTvShows or {};

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
    local tapes = {}
    
    triggerEvent("OnEnumerateVhsTapes", player, tapes, isoTelevision)

    for _, tape in pairs(tapes) do
      local option = subMenu:addOption(getText("ContextMenu_VCR_InsertVideoTape", tape:getDisplayName()), worldObjects, TapedTvShows.onInsertTape, player, isoTelevision, tape)
      local tooltip = ISWorldObjectContextMenu.addToolTip()
      tooltip.name = getText("ContextMenu_VCR_InsertVideoTape_ToolTip_Title", tape:getDisplayName())
      tooltip.description = getText("ContextMenu_VCR_InsertVideoTape_ToolTip_Text", tape:getTooltip())
      tooltip:setTexture(tape:getTexture():getName())
      option.toolTip = tooltip
    end
  end

  if getDebug() then
    TapedTvShows.addDebugMenuOptions(subMenu, player, isoTelevision) -- debug options
  end
  
  if subMenu.numOptions > 1 then -- I don't know why this is off by one
    context:addSubMenu(context:addOption(getText("ContextMenu_VCR_Menu"), worldobjects, nil), subMenu)
  end
end

Events.OnFillWorldObjectContextMenu.Add(TapedTvShows.createVcrPlayerMenu)
