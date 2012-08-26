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
      position = arg.position or 0,
      inputs = {},
      outputs = {},
   }
   
   function object.update()
      self.circuit.update()
      for _,i in ipairs(object.inputs) do
         i.update(self.circuit)
      end
      for _,o in ipairs(object.outputs) do
         o.update(self.circuit)
      end
   end

   function object.reset()
      object.health = arg.health or 100
      object.position = arg.position or 0
      
      for _,i in ipairs(object.inputs) do
         i.reset()
      end
      for _,o in ipairs(object.outputs) do
         o.reset()
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
      self.ticks = self.ticks - 1
      if self.ticks <= 0 and object.on then
         self.ticks = self.period
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
   }
   local object = M.output(arg)
   
   object.on = false

   local super = {
      update = object.update,
      reset = object.reset,
   }  
   
   function object.output()
      object.on = true
      self.ticks = self.period
   end
   
   function object.update(circuit)
      super.update(circuit)
      self.ticks = self.ticks - 1
      if self.ticks < 0 then
         object.on = false
      end
   end
   
   function object.reset()
      super.reset()
      object.on = false
   end

   return object
end

return M