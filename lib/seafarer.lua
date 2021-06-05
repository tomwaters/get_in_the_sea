MusicUtil = require "musicutil"


--!! = rest
--64 = e4
phrases = {
  {"64:1", "64:1", "64:1"},
  {"64:0.5", "65:0.5", "64:1"},
  {"!!:0.5", "64:0.5", "65:0.5", "64:0.5"},
  {"!!:0.5", "64:0.5", "65:0.5", "67:0.5"},
  {"64:0.5", "65:0.5", "67:0.5", "!!:0.5"},
  {"72:4", "72:4"},
  {"!!:1", "!!:1", "!!:1", "!!:0.5", "60:0.25", "60:0.25", "60:0.5", "!!:0.5", "!!:1", "!!:1", "!!:1", "!!:1"},
  {"67:6", "65:4", "65:4"},
  {"71:0.25", "67:0.25", "!!:0.5", "!!:1", "!!:1", "!!:1"},
  {"71:0.25", "67:0.25"},
  {"65:0.25", "67:0.25", "71:0.25", "67:0.25", "71:0.25", "67:0.25"},
  {"65:0.5", "67:0.5", "71:4", "71:1"}
}

options = {
  OUTPUT = {"audio", "midi", "audio + midi", "crow out 1+2", "crow ii JF"}
}


Seafarer = {}
Seafarer.__index = Seafarer
  
function Seafarer:new(id)
  local o = {
    id = id,
    playing = false,
    
    phrase = 1,
    phrase_note = 1,
    all_at_end = false,
    
    output = 0,
    midi_out_device = midi.connect(1),
    midi_out_channel = 0,
    mx_instrument = "",
    
    active_notes = {},
  }

  setmetatable(o, Seafarer)
  o:init_params()

  clock.run(Seafarer.step, o)
  
  return o
end


function Seafarer:init_params()
  local param_count = mxsamples == nil and 3 or 4
  
  params:add_group("seafarer "..self.id, param_count)
  
  params:add{type = "option", id = self.id.."_output", name = "output",
    options = options.OUTPUT,
    action = function(value)
      self:all_notes_off()

      if value == 4 then crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      end
      self.output = value
    end
  }
  
  if mxsamples ~= nil then
    params:add{type = "option", id = self.id.."_mxsamples_instrument", name = "mx inst.", options = mxsamples_instruments, 
      action = function(value)
        self:all_notes_off()
        self.mx_instrument = mxsamples_instruments[value]
      end
    }
  end
  
  params:add{type = "number", id = self.id.."midi_out_device", name = "midi out device",
    min = 1, max = 4, default = 1, action = function(value)
      self:all_notes_off()
      self.midi_out_device = midi.connect(value)
    end
  }
    
  params:add{type = "number", id = self.id.."_midi_out_channel", name = "midi out channel",
    min = 1, max = 16, default = 1,
    action = function(value)
      self:all_notes_off()
      self.midi_out_channel = value
    end}

end

function Seafarer:reset()
  self.phrase = 1
  self.phrase_note = 1
end

function Seafarer:all_notes_off()
  for _, a in pairs(self.active_notes) do
    if self.output == 2 or self.output == 3 then
      self.midi_out_device:note_off(a, nil, self.midi_out_channel)
    end
    
    if (self.output == 1 or self.output == 3) and engine.name == "MxSamples" then
      skeys:off({name=self.mx_instrument, midi=a})
    end
  end
  self.active_notes = {}
end

function Seafarer:step()
  clock.sync(1)
  while true do
    if self.playing then
      self:all_notes_off()
      
      -- get current step in the phrase
      local this_step = phrases[self.phrase][self.phrase_note]

      -- play the note
      local velocity = 100
      local note_num = string.sub(this_step, 1, 2)
      
      if note_num ~= "!!" then
        local freq = MusicUtil.note_num_to_freq(note_num)
  
        if self.output == 1 or self.output == 3 then
          -- Mx.Samples
          if audio_engines[params:get("audio_engine")] == "MxSamples" then
            skeys:on({name=self.mx_instrument, midi=note_num, velocity=velocity})
            table.insert(self.active_notes, note_num)
          else
            engine.hz(freq)
          end
        elseif self.output == 4 then
          crow.output[1].volts = (note_num-60)/12
          crow.output[2].execute()
        elseif self.output == 5 then
          crow.ii.jf.play_note((note_num-60)/12,5)
        end
    
        -- MIDI out
        if (self.output == 2 or self.output == 3) then
          self.midi_out_device:note_on(note_num, velocity, self:get_param("midi_out_channel"))
          table.insert(self.active_notes, note_num)
        end        
      end
      
      
      -- move through the phrase
      self.phrase_note = self.phrase_note + 1
      if self.phrase_note > #phrases[self.phrase] then
        self.phrase_note = 1
        
        -- TODO: handle staying within a few phrases of others etc
        if math.random() > 0.8 then
          self.phrase = self.phrase + 1
          if self.phrase > #phrases then
            self.phrase = #phrases
            
            -- if all players are at the end we can stop
            if self.all_at_end then
              self.playing = false
            end
            
          end
        end
      end
      
      -- wait for the note end
      local note_len = string.sub(this_step, 4, -1)
      clock.sync(1 * note_len)

    else
      clock.sync(1)
    end
  end

end

return Seafarer