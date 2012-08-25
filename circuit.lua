-- circuit.lua
local M = {}

M.new = function (arg)
   arg = arg or {}
   local self = {
      width = arg.width or 16,
      height = arg.height or 16,
      cmap = arg.colourmap or {{16,16,16}, {0,0,255}, {255,0,0}, {255,255,0}},
   }
   self.scale = arg.scale or (arg.size or 512) / self.width
   local object = {}
   if arg.cells then
      if #arg.cells ~= self.width*self.height then
         error("Invalid circuit layout")
      end
      object.cells = arg.cells
   else
      object.cells = {}
      for y = 1,self.height do
         for x = 1,self.width do
            object.cells[x + (y-1)*self.width] = 0
         end
      end
   end
   
   object.draw = function()
      for y = 1,self.height do
         for x = 1,self.width do
            local colour = self.cmap[object.cells[x+(y-1)*self.width]+1] or {0,0,0}
            love.graphics.setColor(colour)
            love.graphics.rectangle("fill",(x-1)*self.scale, (y-1)*self.scale, self.scale, self.scale)
         end
      end
      love.graphics.setColor({0,0,0})
      love.graphics.setLine(1, "smooth")
      for y = 0,self.height do
         love.graphics.line(0, y*self.scale, self.width*self.scale, y*self.scale)
      end
      for x = 0,self.width do
         love.graphics.line(x*self.scale, 0, x*self.scale, self.height*self.scale)
      end
      love.graphics.setColor({255,255,255})
   end
   
   local isActive = function (x,y) 
      if x <= 0 then return false end
      if y <= 0 then return false end
      if x > self.width then return false end
      if y > self.height then return false end
      return object.cells[x+(y-1)*self.width] == 1
  end
   
   object.update = function()
      local new = {}
      for y = 1,self.height do
         for x = 1,self.width do
            local i = x+(y-1)*self.width
            local c = object.cells[i]
            if c == 0 then
               new[i] = 0
            elseif c == 1 then
               new[i] = 2
            elseif c == 2 then
               new[i] = 3
            elseif c == 3 then
               local active = 0
               if isActive(x-1,y-1) then active = active + 1 end
               if isActive(x,y-1) then active = active + 1 end
               if isActive(x+1,y-1) then active = active + 1 end
               
               if isActive(x-1,y) then active = active + 1 end
               if isActive(x+1,y) then active = active + 1 end
               
               if isActive(x-1,y+1) then active = active + 1 end
               if isActive(x,y+1) then active = active + 1 end
               if isActive(x+1,y+1) then active = active + 1 end

               if active == 1 or active == 2 then
                  new[i] = 1
               else
                  new[i] = 3
               end
            else
               new[x+(y-1)*self.width] = c
            end
         end
      end

      object.cells = new
   end
   
   object.toggleoff = function (x,y)
      if x < 0 then return -1 end
      if y < 0 then return -1 end
      if x > self.width*self.scale then return -1 end
      if y > self.width*self.scale then return -1 end
      local i =  math.ceil(x / self.scale) + math.ceil(y / self.scale - 1)*self.width
      if object.cells[i] == 0 then
         object.cells[i] = 3
      else
         object.cells[i] = 0
      end
      return object.cells[i]
   end

   object.cyclewire = function (x,y)
      if x < 0 then return -1 end
      if y < 0 then return -1 end
      if x > self.width*self.scale then return -1 end
      if y > self.width*self.scale then return -1 end
      local i =  math.ceil(x / self.scale) + math.ceil(y / self.scale - 1)*self.width
      if object.cells[i] ~= 0 then
         object.cells[i] = object.cells[i] % 3 + 1
      end
      return object.cells[i]
   end
   
   object.setcell = function (x,y,val)
      if x < 0 then return end
      if y < 0 then return end
      if x > self.width*self.scale then return end
      if y > self.width*self.scale then return end
      local i =  math.ceil(x / self.scale) + math.ceil(y / self.scale - 1)*self.width
      object.cells[i] = val
   end
   return object
end

return M