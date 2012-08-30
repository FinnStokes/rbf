local circuit = require "circuit"
local robot = require "robot"
local weapons = require "weapons"
local http = require("socket.http")

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
local smallfont = nil
local bigfont = nil
local status = "Welcome"

local stepTime = 0.05

local server = "http://rbf-game.appspot.com/"

function putCircuit(c)
   local string = c.cells[1]
   for i = 2,#c.cells do
      string = string .. "," .. c.cells[i]
   end
   --http.request(server,"cells="..string)
end

function getCircuit(c)
   local inputstr = ""--http.request(server)
   for i = 2,32*32 do
     inputstr = inputstr .. ",0"
   end
   t={} ; i=1
   for str in string.gmatch(inputstr, "([^,]+)") do
      t[i] = tonumber(str)
      i = i + 1
   end
   c.cells = t
end

function copyCircuit(a,b)   
   for i = 1,#a.cells do
      b.cells[i] = a.cells[i]
   end
end

function love.load()
   c1 = circuit.new({size=512,width=32,height=32,xOffset=128,yOffset=64})
   r1 = robot.new({circuit = c1})
   c2 = circuit.new({size=512,width=32,height=32,xOffset=128,yOffset=64})
   r2 = robot.new({circuit = c2})
   
   r1.inputs[1] = robot.range({robot=r1,target=r2,upper=50,lower=20,position=5,label="Far"})
   r1.inputs[2] = robot.range({robot=r1,target=r2,upper=20,lower=10,position=10,label="Mid"})
   r1.inputs[3] = robot.range({robot=r1,target=r2,upper=10,lower=0,position=15,label="Close"})
   r1.inputs[4] = robot.direction({robot=r1,target=r2,position=22,label="Behind"})
   r1.inputs[5] = robot.damage({target=r1,position=27,label="Damage"})
   r1.outputs[1] = weapons.laser({robot=r1,target=r2,damage=0.5,position=5,label="Laser"})
   r1.outputs[2] = weapons.rocket({robot=r1,target=r2,damage=0.7,position=10,label="Rocket"})
   r1.outputs[3] = weapons.claw({robot=r1,target=r2,damage=0.7,position=15,label="Claw"})
   r1.outputs[4] = robot.walk({robot=r1,vel=1,position=22,label="Forwards"})
   r1.outputs[5] = robot.walk({robot=r1,vel=-1,position=27,label="Backwards"})

   r2.inputs[1] = robot.range({robot=r2,target=r1,upper=50,lower=20,position=5,label="Far"})
   r2.inputs[2] = robot.range({robot=r2,target=r1,upper=20,lower=10,position=10,label="Mid"})
   r2.inputs[3] = robot.range({robot=r2,target=r1,upper=10,lower=0,position=15,label="Close"})
   r2.inputs[4] = robot.direction({robot=r2,target=r1,position=22,label="Behind"})
   r2.inputs[5] = robot.damage({target=r2,position=27,label="Damage"})
   r2.outputs[1] = weapons.laser({robot=r2,target=r1,damage=0.5,position=5,label="Laser"})
   r2.outputs[2] = weapons.rocket({robot=r2,target=r1,damage=0.7,position=10,label="Rocket"})
   r2.outputs[3] = weapons.claw({robot=r2,target=r1,damage=0.7,position=15,label="Claw"})
   r2.outputs[4] = robot.walk({robot=r2,vel=1,position=22,label="Forwards"})
   r2.outputs[5] = robot.walk({robot=r2,vel=-1,position=27,label="Backwards"})

   bigfont = love.graphics.newFont(18)
   smallfont = love.graphics.newFont(12)
   love.graphics.setFont(smallfont)
end

local function pasting()
   return selected and (selected.width() > 1 or selected.height() > 1)
end

function love.draw()
   r1.draw()

   love.graphics.setColor({255,255,255})
   love.graphics.setFont(bigfont)
   love.graphics.printf(math.floor(r1.health),130,10,50,'left')
   love.graphics.printf(math.floor(r2.health),595,10,50,'right')
   love.graphics.printf(status,330,10,125,'center')
   love.graphics.setFont(smallfont)
   love.graphics.line(200,50,575,50)
   love.graphics.rectangle("fill", 195+r1.position*3.75, 30, 10, 15)
   love.graphics.rectangle("fill", 570-r2.position*3.75, 30, 10, 15)
   

   if selecting and paused then
      love.graphics.setLine(1, "smooth")
      love.graphics.setColor({200,200,200})
      local scale = c1.scale()
      local x = math.floor(math.min(love.mouse.getX(),startX)/scale)
      local y = math.floor(math.min(love.mouse.getY(),startY)/scale)
      local w = math.ceil(math.max(love.mouse.getX(),startX)/scale)-x
      local h = math.ceil(math.max(love.mouse.getY(),startY)/scale)-y
      love.graphics.rectangle("line", x*scale, y*scale, w*scale, h*scale)
   elseif pasting() and paused then
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
   while time > stepTime do
      r1.update()
      r2.update()
      time = time - stepTime
   end
   if r1.dead then
      status = "You lose"
      c1.undo()
      c2.undo()
      r2.reset()
      r1.reset()
      paused = true
   end
   if r2.dead then
      status = "You win"
      c1.undo()
      c2.undo()
      r1.reset()
      r2.reset()
      paused = true
   end
   
   if dragAction >= 0 then
      local x = love.mouse.getX()
      local y = love.mouse.getY()
      c1.setCell(x, y, dragAction)
      if oldX > 0 and oldY > 0 then
         local dx = x-oldX
         local dy = y-oldY
         local norm = math.sqrt(dx*dx+dy*dy)
         if norm > 1 then
            dx = dx/norm
            dy = dy/norm
            for dist = 1,math.floor(norm) do
               c1.setCell(oldX+dist*dx, oldY+dist*dy, dragAction)
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
         c1.save()
         if pasting() then
            c1.pasteWires(x,y,selected)
         elseif (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
            c1.cycleWire(x,y)
         else
            dragAction = c1.toggleOff(x,y)
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
      c1.save()
      selecting = false
      selected = c1.getSubCircuit(startX,startY,x,y)
      if startY ~= y and startX ~= x then
         for cy = math.min(startY,y),math.max(startY,y) do
            for cx = math.min(startX,x),math.max(startX,x) do
               c1.setCell(cx, cy, 0)
            end
         end
      end
      selected.colourmap = cmap
   end
end

local save = nil

function love.keypressed(key, unicode)
   if key == 'escape' then
      (love.event.quit or love.event.push)('q')
   elseif key == ' ' then
      paused = not paused
      if not paused then
         status = "Loading"
         putCircuit(c1)
         getCircuit(c2)
         c1.save()
         c2.save()
         status = "Running"
      else
         c1.undo()
         c2.undo()
         status = "Aborted"
      end
      r1.reset()
      r2.reset()
   elseif key == 'l' and paused then
      c1.save()
      copyCircuit(c2,c1)
   elseif key == '1' then
      stepTime = 0.5
   elseif key == '2' then
      stepTime = 0.05
   elseif key == '3' then 
      stepTime = 0.025
   elseif key == '4' then
      stepTime = 0.0125
   elseif key == 'z' and paused and (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
      c1.undo()
   end
end