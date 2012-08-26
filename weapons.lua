-- weapons.lua
local robot = require "robot"

local M = {}

function M.laser(arg)
   arg = arg or {}
   local self = {
      target = arg.target,
      damage = arg.damage or 1,
   }
   local object = robot.ctsOutput(arg)

   local super = {
      update = object.update
   }

   function object.update(circuit)
      super.update(circuit)
      if object.on then
         self.target.health = self.target.health - self.damage
      end
   end
   
   return object
end

return M