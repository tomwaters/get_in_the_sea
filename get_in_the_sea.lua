-- spirals
-- @tomw
--
-- E1 start/stop
-- E2 reset

engine.name = "PolyPerc"

local Seafarer = include("lib/seafarer")

audio_engines = {"PolyPerc"}
mxsamples_instruments = {}

local draw_metro = metro.init()

local seafarers = {}

function init()
  if libInstalled("mx.samples/lib/mx.samples") then
    mxsamples = include("mx.samples/lib/mx.samples")
    table.insert(audio_engines, "MxSamples")
    skeys = mxsamples:new()
    mxsamples_instruments = skeys:list_instruments()
  end
  
  -- add polyperc params
  params:add_group("PolyPerc", 6)
  cs_AMP = controlspec.new(0,1,'lin',0,0.5,'')
  params:add{type="control",id="amp",controlspec=cs_AMP, action=function(x) engine.amp(x) end}  
  
  cs_PW = controlspec.new(0,100,'lin',0,50,'%')
  params:add{type="control",id="pw",controlspec=cs_PW,
    action=function(x) engine.pw(x/100) end}

  cs_REL = controlspec.new(0.1,3.2,'lin',0,1.2,'s')
  params:add{type="control",id="release",controlspec=cs_REL,
    action=function(x) engine.release(x) end}

  cs_CUT = controlspec.new(50,5000,'exp',0,800,'hz')
  params:add{type="control",id="cutoff",controlspec=cs_CUT,
    action=function(x) engine.cutoff(x) end}

  cs_GAIN = controlspec.new(0,4,'lin',0,1,'')
  params:add{type="control",id="gain",controlspec=cs_GAIN,
    action=function(x) engine.gain(x) end}
  
  cs_PAN = controlspec.new(-1,1, 'lin',0,0,'')
  params:add{type="control",id="pan",controlspec=cs_PAN,
    action=function(x) engine.pan(x) end}
  
  params:add{type = "option", id = "audio_engine", name = "audio engine",
    options = audio_engines,
    action = function(value)
      if audio_engines[value] ~= engine.name then
        -- change engine and resume play when done
        engine.load(audio_engines[value], function()
          if audio_engines[value] == "MxSamples" then
            mxSamplesInit()
          end
        end
        )
      end
    end
  }
  
  -- add seafarers and their params
  table.insert(seafarers, Seafarer:new(1))
  table.insert(seafarers, Seafarer:new(2))
  table.insert(seafarers, Seafarer:new(3))
  table.insert(seafarers, Seafarer:new(4))
  
  params:default()

  screen.aa(0)

  draw_metro.event = update
  draw_metro:start(1/60)
end

function mxSamplesInit()
  skeys:reset()
end

function libInstalled(file)
  local dirs = {norns.state.path, _path.code, _path.extn}
  for _, dir in ipairs(dirs) do
    local p = dir..file..'.lua'
    if util.file_exists(p) then
      return true
    end
  end
  return false
end


function enc(n, d)
end

function key(n, z)
  if z == 1 then
    for s = 1, #seafarers do
      if n == 2 then
        seafarers[s].playing = not seafarers[s].playing
      elseif n == 3 then
        seafarers[s]:reset()
      end
    end
  end
end

function update()
  redraw()
end

function redraw()
  screen.clear()
  screen.font_face(24)
  screen.font_size(12)
  screen.level(15)
  
  screen.move(0, 10)
  screen.text("Get in the sea!")
  
  screen.font_size(10)
  local all_end = true
  for s = 1, #seafarers do
    
    -- check if all players have reached the end (probably shouldn't be here)
    if seafarers[s].phrase ~= #phrases then
      all_end = false
    end

    screen.move((s-1) * 30, 40)
    screen.text(string.format("%02d", seafarers[s].phrase))
  end
  
  -- if all players have reached the end, let them all know they can stop
  if all_end then
    for s = 1, #seafarers do
      seafarers[s].all_at_end = true
    end
  end
  
  screen.font_size(8)
  screen.move(0, 60)
  if seafarers[1].playing then
    screen.text("Stop   Reset")
  else
    screen.text("Start  Reset")
  end

  screen.update()
end

function cleanup()
end

function demo()
  for s = 1, #seafarers do
      seafarers[s].playing = not seafarers[s].playing
  end
end
