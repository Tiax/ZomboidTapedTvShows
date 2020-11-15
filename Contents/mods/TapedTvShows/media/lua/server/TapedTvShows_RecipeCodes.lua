function Recipe.GetItemTypes.DismantleVideoTape(scriptItems)
  local allScriptItems = getScriptManager():getAllItems();
  
  for i=1, allScriptItems:size() do
    local item = allScriptItems:get(i-1);

    if item:getType() == Type.Normal and string.sub(item:getFullName(), 1, string.len("TapedTvShows.VideoTape")) == "TapedTvShows.VideoTape" then
      scriptItems:add(item);
    end
  end
end

--function Recipe.OnCreate.DismantleVideoTape(items, result, player)
--  --player:getInventory():AddItem("Base.X");
--end
