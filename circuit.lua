-- circuit.lua
local M = {}

function M.new(arg)
   arg = arg or {}
   local self = {
      width = arg.width or 16,
      height = arg.height or 16,
      history = {}
   }
   self.scale = arg.scale or (arg.size or 512) / self.width
   local object = {
      colourmap = arg.colourmap or {{16,16,16}, {0,0,255}, {255,0,0}, {255,255,0}},
      linecolour = arg.linecolour or {0,0,0},
      xoff = arg.xOffset or 0,
      yoff = arg.yOffset or 0,
   }
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

   function object.save()
      self.history[#self.history+1] = {}
      for i = 1,#object.cells do
         self.history[#self.history][i] = object.cells[i]
      end
   end

   function object.undo()
      if #self.history > 0 then
         object.cells = table.remove(self.history)
      end
   end
   
   function object.draw()
      love.graphics.translate(object.xoff, object.yoff)
      for y = 1,self.height do
         for x = 1,self.width do
            local colour = object.colourmap[object.cells[x+(y-1)*self.width]+1] or {0,0,0}
            love.graphics.setColor(colour)
            love.graphics.rectangle("fill",(x-1)*self.scale, (y-1)*self.scale, self.scale, self.scale)
         end
      end
      love.graphics.setColor(object.linecolour)
      love.graphics.setLine(1, "smooth")
      for y = 0,self.height do
         love.graphics.line(0, y*self.scale, self.width*self.scale, y*self.scale)
      end
      for x = 0,self.width do
         love.graphics.line(x*self.scale, 0, x*self.scale, self.height*self.scale)
      end
      love.graphics.setColor({255,255,255})
      love.graphics.translate(-object.xoff, -object.yoff)
   end
   
   local function isActive(x,y)
      if x <= 0 then return false end
      if y <= 0 then return false end
      if x > self.width then return false end
      if y > self.height then return false end
      return object.cells[x+(y-1)*self.width] == 1
  end
   
   function object.update()
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
   
   function object.toggleOff(x,y)
      x = x - object.xoff
      y = y - object.yoff
      if x <= 0 then return -1 end
      if y <= 0 then return -1 end
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

   function object.cycleWire(x,y)
      x = x - object.xoff
      y = y - object.yoff
      if x <= 0 then return -1 end
      if y <= 0 then return -1 end
      if x > self.width*self.scale then return -1 end
      if y > self.width*self.scale then return -1 end
      local i =  math.ceil(x / self.scale) + math.ceil(y / self.scale - 1)*self.width
      if object.cells[i] ~= 0 then
         object.cells[i] = object.cells[i] % 3 + 1
      end
      return object.cells[i]
   end
   
   function object.setCell(x,y,val)
      x = x - object.xoff
      y = y - object.yoff
      if x <= 0 then return end
      if y <= 0 then return end
      if x > self.width*self.scale then return end
      if y > self.width*self.scale then return end
      local i =  math.ceil(x / self.scale) + math.ceil(y / self.scale - 1)*self.width
      object.cells[i] = val
   end

   function object.getSubCircuit(x1, y1, x2, y2)
      x1 = math.max(math.min(x1-object.xoff,self.width*self.scale),0)
      y1 = math.max(math.min(y1-object.yoff,self.height*self.scale),0)
      x2 = math.max(math.min(x2-object.xoff,self.width*self.scale),0)
      y2 = math.max(math.min(y2-object.yoff,self.height*self.scale),0)
      if math.abs(x1-x2) < 1  or math.abs(x1-x2) < 1 then
        return M.new({width = 1, height = 1, scale = self.scale})
      end
      local xmin = math.floor(math.min(x1,x2)/self.scale)
      local ymin = math.floor(math.min(y1,y2)/self.scale)
      local width = math.ceil(math.max(x1,x2)/self.scale)-xmin
      local height = math.ceil(math.max(y1,y2)/self.scale)-ymin
      local ret = {width = width, height = height, cells = {}, scale = self.scale}
      for y = 1,ret.height do
         for x = 1,ret.width do
            ret.cells[x + (y-1)*ret.width] = object.cells[xmin + x + (ymin + y - 1)*self.width]
         end
      end
      return M.new(ret)
   end

   function object.pasteWires(x, y, circuit)
      x = x - object.xoff
      y = y - object.yoff
      x = math.floor(x/self.scale)
      y = math.floor(y/self.scale)
      local width = math.min(self.width-x,circuit.width())
      local height = math.min(self.height-y,circuit.height())
      for cy = 1,height do
         for cx = 1,width do
            if x + cx > 0 and y + cy > 0 then
               local cell = circuit.cells[cx + (cy-1)*circuit.width()]
               if cell > 0 then
                  object.cells[x + cx + (y + cy - 1)*self.width] = cell
               end
            end
         end
      end
   end

   function object.width()
      return self.width
   end

   function object.height()
      return self.height
   end

   function object.scale()
      return self.scale
   end

   return object
end

return M