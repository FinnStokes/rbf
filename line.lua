-- line.lua
local circuit = require "circuit"

local M = {}

function M.new(arg)
   arg = arg or {}
   
   local self = {}
   self.xoff = arg.xOffset or 0
   self.yoff = arg.yOffset or 0
   self.x1 = arg.x or arg.x1 or 0
   self.y1 = arg.y or arg.y1 or 0
   self.x2 = nil
   self.y2 = nil
   self.scale = arg.scale or 32
   
   local object = {}
   
   local function drawLine(c,x1,y1,x2,y2)
      local steep = math.abs(y2 - y1) > math.abs(x2 - x1)
      if steep then
         x1,y1 = y1,x1
         x2,y2 = y2,x2
      end
      if x1 > x2 then
         x1,x2 = x2,x1
         y1,y2 = y2,y1
      end
      x1 = math.floor((x1-self.xoff)/self.scale)
      x2 = math.ceil((x2-self.xoff)/self.scale)
      local deltax = x2 - x1
      local deltay = 0
      local y = 1
      local ystep = 0
      if y1 < y2 then
         y1 = math.floor((y1-self.yoff)/self.scale)
         y2 = math.ceil((y2-self.yoff)/self.scale)
         ystep = 1
         deltay = y2 - y1
         y = 1
      else
         y1 = math.ceil((y1-self.yoff)/self.scale)
         y2 = math.floor((y2-self.yoff)/self.scale)
         ystep = -1
         deltay = y1 - y2
         y = deltay
      end
      local error = -0.5
      local deltaerr = deltay / deltax
      for x = 1,deltax do
         if steep then
            c.cells[y+(x-1)*c.width()] = 3
         else
            c.cells[x+(y-1)*c.width()] = 3
         end
         error = error + deltaerr
         if error >= 0.5 then
            y = y + ystep
            error = error - 1.0
         end
      end
   end

   function object.to(x,y)
      if x~= self.x2 or y ~= self.y2 then
         self.x2, self.y2 = x, y
         local left = math.floor((math.min(self.x1,x) - self.xoff)/self.scale)
         local right = math.ceil((math.max(self.x1,x) - self.xoff)/self.scale)
         local top = math.floor((math.min(self.y1,y) - self.yoff)/self.scale)
         local bottom = math.ceil((math.max(self.y1,y) - self.yoff)/self.scale)
      
         arg.scale = self.scale
         arg.width = right - left
         arg.height = bottom - top
         arg.xOffset = self.xoff + left*self.scale
         arg.yOffset = self.yoff + top*self.scale
         
         self.circuit = circuit.new(arg)
         
         drawLine(self.circuit,self.x1-self.xoff,self.y1-self.yoff,self.x2-self.xoff,self.y2-self.yoff)
      end
   end

   function object.pasteInto(c)
      c.pasteWires(math.min(self.x1,self.x2),math.min(self.y1,self.y2),self.circuit)
   end
   
   function object.draw()
      self.circuit.draw()
   end
   
   object.to(arg.x2 or self.x1, arg.y2 or self.y1)

   return object
end

return M