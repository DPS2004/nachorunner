function love.conf(t) -- love2d config

  t.externalstorage = true
  t.console = true
  
  prgconf = { --chip8 config
    file = "nacho8/roms/waitforkey.ch8", -- file to load into memory
    outfile = "nacho8/roms/out.nch", -- output file for dumps
    scale = 8, -- screen scale
    chatty = true, 
    choutput = {-- what things do we want to hear about from chatty?
      all = true, 
      ops = true,
      ums = true,
    },
    -- valid modes:
    -- common
    -- schip
    -- cosmac
    -- bisqwit
    -- custom
    mode = "common",
    framebyframe = true,
    -- the custom mode gets loaded from this table
    custom = {
      sw = 64, -- screen width
      sh = 32, -- screen height
      ips = 700, -- number of instructions to execute per second
      memsize = 4096, -- how many bytes of memory
      vyshift = false, --set vx to vy in 8xy6 and 8xye
      vxoffsetjump = false, -- false for bnnn, true for bxnn
      indexoverflow = true, -- true to set vf to 1 if index goes over 1000
      tempstoreload = true, -- set false to increment i for fx55 and fx65 instead of using a temporary variable
      waitforrelease = false, -- wait for the key to be released for fx0a
      timedupdate = false, -- set to true to emulate the vip cosmac's timing. overides ips.
      pagesize = 256, -- only used if timedupdate = true, this is just a guess!!
    },
    
    
    hotkeys = {
      frameadvance = 'return',
      fastforward = '\\',
      savedump = '5'
    },
    extras = {-- misc things to pass directly to chip 8, mostly debug
      dumper = false, -- see nacho.lua for information on dumper mode
    }
    
    
    
  }
  
  prgconf.keys = {}
  -- key mapping
  -- 1,2,3,C
  -- 4,5,6,D
  -- 7,8,9,E
  -- A,0,B,F
  prgconf.keys[0x1] = '1'
  prgconf.keys[0x2] = '2'
  prgconf.keys[0x3] = '3'
  prgconf.keys[0xc] = '4'
  
  prgconf.keys[0x4] = 'q'
  prgconf.keys[0x5] = 'w'
  prgconf.keys[0x6] = 'e'
  prgconf.keys[0xd] = 'r'
  
  prgconf.keys[0x7] = 'a'
  prgconf.keys[0x8] = 's'
  prgconf.keys[0x9] = 'd'
  prgconf.keys[0xe] = 'f'
  
  prgconf.keys[0xa] = 'z'
  prgconf.keys[0x0] = 'x'
  prgconf.keys[0xb] = 'c'
  prgconf.keys[0xf] = 'v'
  
  
  prgconf.runonload = function()
  
    ccode = nchcompile('nacho8/roms/waitforkey.nch')
    chip = nacho.loadtabletochip(ccode,chip)
    nchdecompile(ccode,prgconf.mode,prgconf.custom)
  end
  
  
end
