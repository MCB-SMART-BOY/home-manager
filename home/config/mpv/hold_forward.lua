local HOLD_SPEED = 3.0
local SEEK_SECONDS = 5
local msg = require("mp.msg")

local state = {
  is_down = false,
  is_long = false,
  saved_speed = nil,
}

local function reset_state()
  state.is_down = false
  state.is_long = false
  state.saved_speed = nil
end

local function restore_speed()
  if state.saved_speed ~= nil then
    mp.set_property_number("speed", state.saved_speed)
  end
  reset_state()
end

local function seek_forward()
  mp.commandv("seek", SEEK_SECONDS, "relative")
end

local function handle_forward(event)
  if event.event == "down" then
    if state.is_down then
      restore_speed()
    end
    state.is_down = true
    return
  end

  if event.event == "repeat" then
    state.is_down = true
    if state.is_long then
      if mp.get_property_bool("pause") then
        seek_forward()
      end
      return
    end

    state.saved_speed = mp.get_property_number("speed")
    if state.saved_speed == nil then
      msg.error("hold_forward: unable to read current playback speed")
      reset_state()
      return
    end

    state.is_long = true
    if mp.get_property_bool("pause") then
      seek_forward()
    else
      mp.set_property_number("speed", HOLD_SPEED)
    end
    return
  end

  if event.event == "up" then
    if event.canceled then
      restore_speed()
    elseif state.is_long then
      restore_speed()
    else
      seek_forward()
      reset_state()
    end
    return
  end

  if event.event == "press" then
    seek_forward()
    reset_state()
  end
end

mp.add_key_binding(nil, "forward", handle_forward, { complex = true })
