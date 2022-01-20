-- This project aims to be very commented.
-- It is based on https://tobiasvl.github.io/blog/write-a-chip-8-emulator/



function love.load() -- called once at the very start of execution
  
  function pr(id,x)
    if prgconf.chatty then -- helper function to print only if its asked for
      if not x then
        x = id
        id = 'all'
      end
      if prgconf.choutput[id] or prgconf.choutput.all then
        print(id..': '..x)
      end
    end
  end
  
  lovebird = require('lovebird/lovebird') -- load lovebird debugging library
  
  
  
  nacho = require('nacho8/nacho') -- load the chip8 interpreter
  
  nacho.setup() -- load bit ops (pass no arguments to just use luajit)
  
  
  function getparentdir(fname)
    local fname2 = ""
    local offset = 0
    if string.sub(fname,-1) == "/" then
      fname = string.sub(fname,1,-2)
    end
    fname2 = fname:match(".*/(.*)")
    if fname2 then
      fname = string.sub(fname,1,-(string.len(fname2)+1))
      return fname
    else
      return ""
    end
  end
  
  
  function nchcompile(nch)
    
    
    nacho.loadspritepng = function(fn)
      local imagedata = love.image.newImageData(getparentdir(nch)..fn)
      local spritedata = {}
      local sprite = {}
      for y=0,imagedata:getHeight()-1 do
        local r, g, b = imagedata:getPixel(0, y)
        if r == 1 and b == 0 then
          table.insert(spritedata,sprite)
          sprite = {}
        else
          local strip = 0
          for x=0,7 do
            r, g, b = imagedata:getPixel(x, y)
            strip = strip + (128/2^x)*r
          end
          table.insert(sprite,strip)
        end
      end
      if sprite ~= {} then
        table.insert(spritedata,sprite)
      end
      return spritedata
      
    end
    
    
    
    local contents, size = love.filesystem.read(nch)
    return nacho.compile(contents,basefile)
    
    
    
    
    
  end
  
  function nchdecompile(ccode)
    local file = io.open(prgconf.outfile,'w')
    local dump = nacho.decompile(ccode)
    file:write(dump)
    print(dump)
    file:close()
  end
  
  function loadtochip(file,chip) --load a file into chip8's memory
    local contents, size = love.filesystem.read(file)
    pr('loading file:')
    for i=1,size do
      local byte = string.byte(string.sub(contents,i,i))
      pr(nacho.bit.tohex(byte))
      chip.mem[0x200+(i-1)] = byte
      
    end
    return chip
  end
  
 
  
  
  chip = nacho.init(prgconf.mode,prgconf.custom,prgconf.extras) -- init chip 8
  chip = loadtochip(prgconf.file,chip) --load file defined in conf.lua
  
  chip.keys = {}
  
  for k,v in pairs(prgconf.keys) do
    chip.keys[k] = {pressed=false,released=false,down=false}
  end
  
  love.graphics.setDefaultFilter("nearest", "nearest") -- make the graphics nice and pixelly
  love.graphics.setLineStyle("rough")
  love.graphics.setLineJoin("miter")
  
  chipcanvas = love.graphics.newCanvas(chip.cf.sw,chip.cf.sh)
  
  leftoverinstructions = 0

  love.window.setMode(chip.cf.sw*prgconf.scale, chip.cf.sh*prgconf.scale, {resizable=true}) -- set the love2d window size to that of the config

  if prgconf.runonload then
    prgconf.runonload()
  end
  
end

function love.keypressed(key, scancode, isrepeat)
  for k,v in pairs(prgconf.keys) do
    
    if key == v then
      chip.keys[k].pressed = true
      chip.keys[k].down = true
    end
  end
  
  if prgconf.framebyframe then
    if key == prgconf.hotkeys.frameadvance then
      if chip.cf.dotimedupdate then
        local ops = chip.timedupdate()
        pr('ops',ops)
        pr('ums',chip.microseconds)
      else
        chip.timerdec()
        chip.update()
      end
    end
  end
  
  if key == prgconf.hotkeys.savedump then
    local file = io.open(prgconf.outfile,'w')
    local dump = chip.savedump()
    file:write(dump)
    print(dump)
    file:close()
  end
  
end

function love.keyreleased(key, scancode, isrepeat)
  for k,v in pairs(prgconf.keys) do
    if key == v then
      chip.keys[k].down = false
      chip.keys[k].released = true
    end
  end
end


function love.update()
  if not prgconf.framebyframe then
    chip.timerdec()
    if chip.cf.dotimedupdate then
      local ops = chip.timedupdate()
      pr('ops',ops)
      pr('ums',chip.microseconds)
    else
      local bonusframes = 0
      leftoverinstructions = leftoverinstructions + chip.cf.ips % 60
      if leftoverinstructions >= 60 then
        bonusframes = math.floor(leftoverinstructions / 60)
        leftoverinstructions = leftoverinstructions - (bonusframes * 60)
      end
      for i=1,math.floor(chip.cf.ips/60) do
        chip.update()
      end
    end
  else
    if love.keyboard.isDown(prgconf.hotkeys.fastforward) then
      if chip.cf.dotimedupdate then
        local ops = chip.timedupdate()
        pr('ops',ops)
        pr('ums',chip.microseconds)
      else
        chip.timerdec()
        chip.update()
      end
    end
  end
  
  for k,v in pairs(prgconf.keys) do
    chip.keys[k].pressed = false
    chip.keys[k].released = false
  end
  lovebird.update()
  
  
end

function love.draw()
  love.graphics.setColor(1,1,1,1)
  love.graphics.setCanvas(chipcanvas)
    love.graphics.setBlendMode("alpha")
    if chip.screenupdated then
      pr('drawing screen')
      love.graphics.clear()
      for x=0,chip.cf.sw-1 do
        for y=0,chip.cf.sw-1 do
          if chip.display[x][y] then
            love.graphics.points(x,y)
          end
        end
      end
      chip.screenupdated = false
    end
    love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  love.graphics.draw(chipcanvas,0,0,0,prgconf.scale,prgconf.scale)

end