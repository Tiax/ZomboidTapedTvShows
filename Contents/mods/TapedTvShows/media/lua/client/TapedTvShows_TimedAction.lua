require "TimedActions/ISBaseTimedAction"
TapedTvShows = TapedTvShows or {};
ISInsertVideoTape = ISBaseTimedAction:derive("ISInsertVideoTape");

function ISInsertVideoTape:new(character, tv, tape)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.stopOnWalk = true;
  o.stopOnRun = true;
  o.maxTime = 70;
  o.tape = tape;
  o.tv = tv;
  o.character  = character;
  return o;
end

function ISInsertVideoTape:isValid()
  --self.tv:updateFromIsoObject()
  return instanceof(self.tv, "IsoTelevision")
end

function ISInsertVideoTape:waitToStart()
  self.character:faceThisObject(self.tv)
  return self.character:shouldBeTurning()
end

function ISInsertVideoTape:update()
  self.character:faceThisObject(self.tv)
  self.character:setMetabolicTarget(Metabolics.LightDomestic);
end

function ISInsertVideoTape:start()
  self:setActionAnim("Loot")
  self.character:SetVariable("LootPosition", "Mid")
end

function ISInsertVideoTape:stop()
  ISBaseTimedAction.stop(self);
end

function ISInsertVideoTape:perform()
  TapedTvShows.playBroadCastFromTape(self.character, self.tv, self.tape)
  
  -- needed to remove from queue / start next.
  ISBaseTimedAction.perform(self);
end

ISEjectVideoTape = ISBaseTimedAction:derive("ISInsertVideoTape");

function ISEjectVideoTape:new(character, tv)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.stopOnWalk = true;
  o.stopOnRun = true;
  o.maxTime = 30;
  o.tv = tv;
  o.character  = character;
  return o;
end

function ISEjectVideoTape:isValid()
  return instanceof(self.tv, "IsoTelevision")
end

function ISEjectVideoTape:waitToStart()
  self.character:faceThisObject(self.tv)
  return self.character:shouldBeTurning()
end

function ISEjectVideoTape:update()
  self.character:faceThisObject(self.tv)
  self.character:setMetabolicTarget(Metabolics.LightDomestic);
end

function ISEjectVideoTape:start()
  self:setActionAnim("Loot")
  self.character:SetVariable("LootPosition", "Mid")
end

function ISEjectVideoTape:stop()
  ISBaseTimedAction.stop(self);
end

function ISEjectVideoTape:perform()
  TapedTvShows.stopBroadCastEjectTape(self.character, self.tv)
  
  -- needed to remove from queue / start next.
  ISBaseTimedAction.perform(self);
end
