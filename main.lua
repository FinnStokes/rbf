local circuit = require "circuit"

local c = {}

function love.load()
   c = circuit.new({size=512,width=32,height=32})
end

function love.draw()
   c.draw()
end

local paused = false
local time = 0
local dragAction = -1

function love.update(dt)
   if not paused then
      time = time + dt
   end
   while time > 0.5 do
      c.update()
      time = time - 0.5
   end
   
   if dragAction >= 0 then
      c.setcell(love.mouse.getX(), love.mouse.getY(), dragAction)
   end
end
function love.mousepressed(x, y, button)
   if button == 'l' then
      dragAction = c.toggleoff(x,y)
   elseif button == 'r' then
      c.cyclewire(x,y)
   end
end

function love.mousereleased(x, y, button)
   if button == 'l' then
      dragAction = -1
   end
end

function love.keypressed(key, unicode)
   print(key)
   if key == 'escape' then
      (love.event.quit or love.event.push)('q')
   elseif key == ' ' then
      paused = not paused
   end
end