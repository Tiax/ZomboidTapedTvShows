require "TimedActions/ISBaseTimedAction"

TapedTvShows = TapedTvShows or {};

ISInsertVideoTape = ISBaseTimedAction:derive("ISInsertVideoTape");

function ISInsertVideoTape:new(character, tv, tape)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.stopOnWalk = true;
  o.stopOnRun = true;
  o.maxTime = 60*5;
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
  self.sound = getSoundManager():PlayWorldSound("vhs_insert", self.tv:getSquare(), 0.0, 10, 1.0, true)
end

function ISInsertVideoTape:stop()
  if self.sound and self.sound:isPlaying() then
    self.sound:stop();
  end

  ISBaseTimedAction.stop(self);
end

function ISInsertVideoTape:perform()
  local channel = TapedTvShows.getVhsChannel(self.tv)

  triggerEvent("OnPlayVhsTape", self.character, self.tape, self.tv, channel)
  
  --if self.sound and self.sound:isPlaying() then
    --self.sound:stop();
  --end

  -- needed to remove from queue / start next.
  ISBaseTimedAction.perform(self);
end

ISEjectVideoTape = ISBaseTimedAction:derive("ISEjectVideoTape");

function ISEjectVideoTape:new(character, tv)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.stopOnWalk = true;
  o.stopOnRun = true;
  o.maxTime = 60*2;
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
  self.sound = getSoundManager():PlayWorldSound("vhs_eject", self.tv:getSquare(), 0.0, 10, 1.0, true)
end

function ISEjectVideoTape:stop()
  if self.sound and self.sound:isPlaying() then
    self.sound:stop();
  end

  ISBaseTimedAction.stop(self);
end

function ISEjectVideoTape:perform()
  local channel = TapedTvShows.getVhsChannel(self.tv)
  
  triggerEvent("OnEjectVhsTape", self.character, self.tv, channel)
  
  --if self.sound and self.sound:isPlaying() then
    --self.sound:stop();
  --end

  -- needed to remove from queue / start next.
  ISBaseTimedAction.perform(self);
end
