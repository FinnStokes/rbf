-- weapons.lua
local robot = require "robot"

local M = {}

function M.weapon(arg)
   arg = arg or {}
   local self = {
   }
   local object = robot.ctsOutput(arg)
   object.power = 0.0
   object.robot = arg.robot

   local super = {
      update = object.update
   }

   function object.output()
     local n = 0
     for i = 1,#arg.robot.weapons do
       if arg.robot.weapons[i].on then
         n = n + 1
       end
     end
     object.power = 1.0/n
   end
   
   if arg.robot then
      if not arg.robot.weapons then
         arg.robot.weapons = {}
      end
      arg.robot.weapons[#arg.robot.weapons+1] = object
   end
   
   return object
end

function M.laser(arg)
   arg = arg or {}
   local self = {
      target = arg.target,
      damage = arg.damage or 1,
   }
   local object = M.weapon(arg)

   local super = {
      output = object.output
   }

   function object.output()
      super.output()
      self.target.health = self.target.health - self.damage*object.power
   end
   
   return object
end

function M.rocket(arg)
   arg = arg or {}
   local self = {
      target = arg.target,
      threshold = arg.threshold or 10,
      damage = arg.damage or 1,
      cooldown = arg.cooldown or 32
   }
   local object = M.weapon(arg)

   local super = {
      output = object.output,
      update = object.update,
   }

   local cooldown = 0

   function object.update(circuit)
     cooldown = cooldown - 1
     super.update(circuit)
   end

   function object.output()
      super.output()
      if cooldown <= 0 then
        self.target.health = self.target.health - self.damage*object.power
        if math.abs(100 - object.robot.position - self.target.position) <= self.threshold then
          object.robot.health = object.robot.health - self.damage*object.power
        end
        cooldown = self.cooldown
      end
   end
   
   return object
end

function M.claw(arg)
   arg = arg or {}
   local self = {
      target = arg.target,
      threshold = arg.threshold or 10,
      damage = arg.damage or 1,
   }
   local object = M.weapon(arg)

   local super = {
      output = object.output
   }

   function object.output()
      super.output()
      if object.on then
         if math.abs(100 - object.robot.position - self.target.position) <= self.threshold then
            self.target.health = self.target.health - self.damage*object.power
         end
      end
   end
   
   return object
end

return M