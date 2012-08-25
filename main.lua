local circuit = require "circuit"

local c = {}

local paused = false
local selecting = false
local selected = nil
local time = 0
local dragAction = -1
local startX = -1
local startY = -1

function love.load()
   c = circuit.new({size=512,width=32,height=32})
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
      love.graphics.rectangle("fill", x*scale, y*scale, w*scale, h*scale)
   elseif selected and (selected.width() > 1 or selected.height() > 1) then
      local scale = selected.scale()
      local x = math.floor(love.mouse.getX()/scale)
      local y = math.floor(love.mouse.getY()/scale)
      love.graphics.translate(x*scale, y*scale)
      selected.draw()
   end
end

function love.update(dt)
   if not paused then
      time = time + dt
   end
   while time > 0.5 do
      c.update()
      time = time - 0.5
   end
   
   if dragAction >= 0 then
      local x = love.mouse.getX()
      local y = love.mouse.getY()
      c.setcell(x, y, dragAction)
   end
end

function love.mousepressed(x, y, button)
   if button == 'l' then
      dragAction = c.toggleoff(x,y)
   elseif button == 'r' then
      selecting = true
      startX = x
      startY = y
   end
end

function love.mousereleased(x, y, button)
   if button == 'l' then
      dragAction = -1
   elseif button == 'r' then
      selecting = false
      selected = c.getsubcircuit(startX,startY,x,y)
      selected.colourmap = {{16,16,16,100}, {0,0,255,100}, {255,0,0,100}, {255,255,0,100}}
      selected.linecolour = {200,200,200}
   end
end

function love.keypressed(key, unicode)
   if key == 'escape' then
      (love.event.quit or love.event.push)('q')
   elseif key == ' ' then
      paused = not paused
   end
end