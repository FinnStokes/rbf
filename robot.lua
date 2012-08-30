-- robot.lua
local circuit = require "circuit"

local M = {}

function M.new(arg)
   arg = arg or {}
   local self = {
      circuit = arg.circuit or circuit.new(),
   }
   local object = {
      health = arg.health or 100,
      position = arg.position or 20,
      inputs = {},
      outputs = {},
      dead = false,
   }
   
   function object.update()
      if object.health <= 0 then
         object.dead = true
      end
      if not object.dead then
         self.circuit.update()
         for _,i in ipairs(object.inputs) do
            i.update(self.circuit)
         end
         for _,o in ipairs(object.outputs) do
            o.update(self.circuit)
         end
      end
   end

   function object.reset()
      object.dead = false
      object.health = arg.health or 100
      object.position = arg.position or 20
      
      for _,i in ipairs(object.inputs) do
         i.reset()
      end
      for _,o in ipairs(object.outputs) do
         o.reset()
      end
   end

   function object.draw()
      self.circuit.draw()
      
      love.graphics.setColor(255, 255, 255, 255)
      
      for _,i in ipairs(object.inputs) do
         i.draw(self.circuit)
      end
      for _,o in ipairs(object.outputs) do
         o.draw(self.circuit)
      end
   end

   return object
end

function M.input(arg)
   arg = arg or {}
   local self = {
      position = arg.position or 1,
   }
   local object = {
   }
   
   function object.draw(circuit)
      local x = circuit.xoff - 128
      local y = circuit.yoff + (self.position-1)*circuit.scale()
      love.graphics.printf(arg.label,x,y,128,"right")
   end
   
   function object.update(circuit)
   end
   
   function object.ping(circuit)
      if circuit.cells[1+(self.position-1)*circuit.width()] ~= 0 then
         circuit.cells[1+(self.position-1)*circuit.width()] = 1
      end
   end
   
   function object.reset()
   end
   
   return object
end

function M.ctsInput(arg)
   arg = arg or {}
   local self = {
      period = arg.period or 8,
      ticks = 0,
   }
   local object = M.input(arg)

   object.on = arg.onFunc or function ()
                                return true 
                             end
   
   local super = {
      update = object.update,
      reset = object.reset,
   }
   function object.update(circuit)
      super.update(circuit)
      self.ticks = self.ticks + 1
      if self.ticks % self.period == 0 and object.on() then
         object.ping(circuit)
      end
   end
   
   function object.reset()
      super.reset()
      self.ticks = 0
   end
   
   return object
end

function M.output(arg)
   arg = arg or {}
   local self = {
      position = arg.position or 1,
   }
   local object = {
   }
   
   function object.draw(circuit)
      local x = circuit.xoff + circuit.width()*circuit.scale() + 5
      local y = circuit.yoff + (self.position-1)*circuit.scale()
      love.graphics.printf(arg.label,x,y,128,"left")
   end
   
   function object.output()
   end
   
   function object.update(circuit)
      if circuit.cells[self.position*circuit.width()] == 1 then
         object.output()
      end
   end
   
   function object.reset()
   end

   return object
end

function M.ctsOutput(arg)
   arg = arg or {}
   local self = {
      period = arg.period or 8,
      ticks = 0,
      pinged = false,
      position = arg.position or 1,
   }
   local object = M.output(arg)
   
   object.on = false

   local super = {
      update = object.update,
      reset = object.reset,
   }  
   
   function object.output()
   end
   
   function object.update(circuit)
      if circuit.cells[self.position*circuit.width()] == 1 then
         self.pinged = true
      end
      self.ticks = self.ticks + 1
      if self.ticks % self.period == 0 and self.pinged then
         self.pinged = false
         object.on = true
         object.output()
      else
        object.on = false
      end
   end
   
   function object.reset()
      super.reset()
      object.on = false
   end

   return object
end

function M.range(arg)
   arg = arg or {}
   local self = {
      threshold = arg.threshold or 50,
      robot = arg.robot,
      target = arg.target,
   }
   local object = M.ctsInput(arg)
   
   function object.on()
      return math.abs(100 - self.robot.position - self.target.position) <= self.threshold
   end
   
   return object
end

function M.walk(arg)
   arg = arg or {}
   local self = {
      velocity = arg.vel or 1,
      robot = arg.robot,
   }
   local object = M.ctsOutput(arg)
   
   function object.output()
     self.robot.position = math.min(math.max(self.robot.position + self.velocity, 0), 100)
   end
   
   return object
end

return M