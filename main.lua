local circuit = require "circuit"
local robot = require "robot"

local c = {}

local cmap = {{16,16,16,0}, {0,0,255,64}, {255,0,0,64}, {255,255,0,64}}

local paused = true
local selecting = false
local selected = nil
local time = 0
local dragAction = -1
local startX = -1
local startY = -1
local oldX = -1
local oldY = -1

function love.load()
   c = circuit.new({size=512,width=32,height=32,xOffset=128,yOffset=64})
   r = robot.new({circuit = c})
   r.inputs[1] = robot.ctsInput({position=5})
   local ctsout = robot.ctsOutput({position=5,period=6})
   local update = ctsout.update
   ctsout.update = function (circuit)
                      update(circuit)
                      if ctsout.on then
                         print("output")
                      else
                         print("no output")
                      end
                   end
   r.outputs[1] = ctsout
end

local function pasting()
   return selected and (selected.width() > 1 or selected.height() > 1)
end

function love.draw()
   c.draw()
   if selecting then
      love.graphics.setLine(1, "smooth")
      love.graphics.setColor({200,200,200})
      local scale = c.scale()
      local x = math.floor(math.min(love.mouse.getX(),startX)/scale)
      local y = math.floor(math.min(love.mouse.getY(),startY)/scale)
      local w = math.ceil(math.max(love.mouse.getX(),startX)/scale)-x
      local h = math.ceil(math.max(love.mouse.getY(),startY)/scale)-y
      love.graphics.rectangle("line", x*scale, y*scale, w*scale, h*scale)
   elseif pasting() then
      local scale = selected.scale()
      local x = math.floor(love.mouse.getX()/scale)
      local y = math.floor(love.mouse.getY()/scale)
      love.graphics.translate(x*scale, y*scale)
      selected.draw()
      love.graphics.translate(-x*scale, -y*scale)
      love.graphics.rectangle("line", x*scale, y*scale, selected.width()*scale, selected.height()*scale)
   end
end

function love.update(dt)
   if not paused then
      time = time + dt
   end
   while time > 0.25 do
      r.update()
      time = time - 0.25
   end
   
   if dragAction >= 0 then
      local x = love.mouse.getX()
      local y = love.mouse.getY()
      c.setCell(x, y, dragAction)
      if oldX > 0 and oldY > 0 then
         local dx = x-oldX
         local dy = y-oldY
         local norm = math.sqrt(dx*dx+dy*dy)
         if norm > 1 then
            dx = dx/norm
            dy = dy/norm
            for dist = 1,math.floor(norm) do
               c.setCell(oldX+dist*dx, oldY+dist*dy, dragAction)
            end
         end
      end
      oldX = x
      oldY = y
   else
      oldX = -1
      oldy = -1
   end
end

function love.mousepressed(x, y, button)
   if paused then
      if button == 'l' then
         c.save()
         if pasting() then
            c.pasteWires(x,y,selected)
         elseif (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
            c.cycleWire(x,y)
         else
            dragAction = c.toggleOff(x,y)
            oldX = x
            oldY = y
         end
      elseif button == 'r' then
         selecting = true
         startX = x
         startY = y
      end
   end
end

function love.mousereleased(x, y, button)
   if button == 'l' then
      dragAction = -1
   elseif paused and button == 'r' and selecting then
      c.save()
      selecting = false
      selected = c.getSubCircuit(startX,startY,x,y)
      if startY ~= y and startX ~= x then
         for cy = math.min(startY,y),math.max(startY,y) do
            for cx = math.min(startX,x),math.max(startX,x) do
               c.setCell(cx, cy, 0)
            end
         end
      end
      selected.colourmap = cmap
   end
end

function love.keypressed(key, unicode)
   if key == 'escape' then
      (love.event.quit or love.event.push)('q')
   elseif key == ' ' then
      paused = not paused
   elseif key == 'z' and paused and (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
      c.undo()
   end
end