-- see media\lua\server\Items\Distributions.lua

local function insertTvShowTapes(items)
  local chance_corpse = 0.005
  local chance_other = 0.1

  for i=1, #items, 2 do
    local itemName = items[i]
    if itemName == "CreditCard" then
      for j=1, 25 do
        table.insert(items, "TapedTvShows.VideoTape" .. j)
        table.insert(items, chance_corpse)
      end
      break
    elseif itemName == "SheetPaper2" or itemName == "Disc" then
      for j=1, 25 do
        table.insert(items, "TapedTvShows.VideoTape" .. j)
        table.insert(items, chance_other)
      end
      break
    end
  end
end

--print("Inserting video tapes into loot tables...")

for k1,v1 in pairs(SuburbsDistributions) do
  local items = v1["items"]
  
  if items then
    insertTvShowTapes(items)
  else
    for k2,v2 in pairs(v1) do
      items = v2["items"]
      if items then
        insertTvShowTapes(items)
      end
    end
  end
end
