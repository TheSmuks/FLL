obs = obslua

-- Internal variables
local text_source_name = ""
local sound_a_name = ""
local sound_b_name = ""
local sound_c_name = ""

local active_min = 2
local active_sec = 30

-- Sound B Trigger Time
local b_trig_min = 1
local b_trig_sec = 0

local wait_before_cool = 5 

local cool_min = 1
local cool_sec = 0

local current_state = "stopped"
local time_left = 0
local is_paused = false
local is_muted = false -- NEW: Tracks if we should play sound

function script_description()
    return "Looping Stage Timer\n\n1. Plays Sound A on Start.\n2. Plays Sound B at Warning Time.\n3. Plays Sound C ONCE at zero.\n4. Counts down Cooldown time.\n5. Loops."
end

function script_properties()
    local props = obs.obs_properties_create()
    
    local p_text = obs.obs_properties_add_list(props, "text_source", "Text Source (The Clock)", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local p_sound_a = obs.obs_properties_add_list(props, "sound_a", "Sound A (Start Sound)", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local p_sound_b = obs.obs_properties_add_list(props, "sound_b", "Sound B (Warning Sound)", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local p_sound_c = obs.obs_properties_add_list(props, "sound_c", "Sound C (End Sound)", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    
    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source in ipairs(sources) do
            local source_id = obs.obs_source_get_unversioned_id(source)
            local s_name = obs.obs_source_get_name(source)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                obs.obs_property_list_add_string(p_text, s_name, s_name)
            elseif source_id == "ffmpeg_source" then
                obs.obs_property_list_add_string(p_sound_a, s_name, s_name)
                obs.obs_property_list_add_string(p_sound_b, s_name, s_name)
                obs.obs_property_list_add_string(p_sound_c, s_name, s_name)
            end
        end
    end
    obs.source_list_release(sources)

    -- Test Buttons
    obs.obs_properties_add_button(props, "btn_test_a", "🔊 TEST SOUND A", test_sound_a)
    obs.obs_properties_add_button(props, "btn_test_b", "🔊 TEST SOUND B", test_sound_b)
    obs.obs_properties_add_button(props, "btn_test_c", "🔊 TEST SOUND C", test_sound_c)

    -- Main Timer Settings
    obs.obs_properties_add_int(props, "a_min", "Active Timer (Minutes)", 0, 120, 1)
    obs.obs_properties_add_int(props, "a_sec", "Active Timer (Seconds)", 0, 59, 1)
    
    -- Sound B Config
    obs.obs_properties_add_int(props, "b_t_min", "Sound B Warning Trigger (Minutes Left)", 0, 120, 1)
    obs.obs_properties_add_int(props, "b_t_sec", "Sound B Warning Trigger (Seconds Left)", 0, 59, 1)

    -- Sound C Delay
    obs.obs_properties_add_int(props, "wait_cooldown", "Wait AFTER Sound C (Seconds)", 0, 3600, 1)
    
    -- Cooldown Settings
    obs.obs_properties_add_int(props, "c_min", "Cooldown Timer (Minutes)", 0, 120, 1)
    obs.obs_properties_add_int(props, "c_sec", "Cooldown Timer (Seconds)", 0, 59, 1)
    
    -- NEW: Mute Checkbox
    obs.obs_properties_add_bool(props, "mute_sounds", "🔇 MUTE ALL SOUNDS")
    
    -- Control Buttons
    obs.obs_properties_add_button(props, "btn_start", "▶ START / RESTART", start_timer)
    obs.obs_properties_add_button(props, "btn_pause", "⏸ PAUSE / RESUME", pause_timer)
    obs.obs_properties_add_button(props, "btn_reset", "⏹ STOP & RESET", reset_timer)
    
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_int(settings, "a_min", 2)
    obs.obs_data_set_default_int(settings, "a_sec", 30)
    
    obs.obs_data_set_default_int(settings, "b_t_min", 1)
    obs.obs_data_set_default_int(settings, "b_t_sec", 0)
    
    obs.obs_data_set_default_int(settings, "wait_cooldown", 5)
    
    obs.obs_data_set_default_int(settings, "c_min", 1)
    obs.obs_data_set_default_int(settings, "c_sec", 0)
    
    obs.obs_data_set_default_bool(settings, "mute_sounds", false)
end

function script_update(settings)
    text_source_name = obs.obs_data_get_string(settings, "text_source")
    sound_a_name = obs.obs_data_get_string(settings, "sound_a")
    sound_b_name = obs.obs_data_get_string(settings, "sound_b")
    sound_c_name = obs.obs_data_get_string(settings, "sound_c")
    
    active_min = obs.obs_data_get_int(settings, "a_min")
    active_sec = obs.obs_data_get_int(settings, "a_sec")
    
    b_trig_min = obs.obs_data_get_int(settings, "b_t_min")
    b_trig_sec = obs.obs_data_get_int(settings, "b_t_sec")
    
    wait_before_cool = obs.obs_data_get_int(settings, "wait_cooldown")
    
    cool_min = obs.obs_data_get_int(settings, "c_min")
    cool_sec = obs.obs_data_get_int(settings, "c_sec")
    
    -- Handle Mute Updates
    local new_mute_state = obs.obs_data_get_bool(settings, "mute_sounds")
    if new_mute_state == true and is_muted == false then
        -- If we just checked the mute box, instantly stop any playing sounds
        stop_sound(sound_a_name)
        stop_sound(sound_b_name)
        stop_sound(sound_c_name)
    end
    is_muted = new_mute_state
end

function update_text(mins, secs)
    local source = obs.obs_get_source_by_name(text_source_name)
    if source then
        local text = string.format("%02d:%02d", mins, secs)
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", text)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

function play_sound(s_name)
    if is_muted then return end -- If muted, abort playing!
    
    if s_name and s_name ~= "" then
        local sound = obs.obs_get_source_by_name(s_name)
        if sound then
            obs.obs_source_media_restart(sound)
            obs.obs_source_release(sound)
        end
    end
end

function stop_sound(s_name)
    if s_name and s_name ~= "" then
        local sound = obs.obs_get_source_by_name(s_name)
        if sound then
            obs.obs_source_media_stop(sound)
            obs.obs_source_release(sound)
        end
    end
end

function test_sound_a() play_sound(sound_a_name) end
function test_sound_b() play_sound(sound_b_name) end
function test_sound_c() play_sound(sound_c_name) end

function tick()
    if current_state == "active" then
        
        -- Check if it is time to play the Sound B warning
        local b_trigger_total = (b_trig_min * 60) + b_trig_sec
        if time_left == b_trigger_total and b_trigger_total > 0 then
            play_sound(sound_b_name)
        end
        
        if time_left > 0 then
            time_left = time_left - 1
            update_text(math.floor(time_left / 60), time_left % 60)
        else
            -- Phase 1 over. Play Sound C ONCE.
            play_sound(sound_c_name)
            current_state = "waiting"
            time_left = wait_before_cool
            update_text(0, 0)
        end
        
    elseif current_state == "waiting" then
        if time_left > 0 then
            time_left = time_left - 1
        else
            -- Custom wait is over. Start Cooldown clock
            stop_sound(sound_c_name)
            current_state = "cooldown"
            time_left = (cool_min * 60) + cool_sec
            update_text(math.floor(time_left / 60), time_left % 60)
        end
        
    elseif current_state == "cooldown" then
        if time_left > 0 then
            time_left = time_left - 1
            update_text(math.floor(time_left / 60), time_left % 60)
        else
            -- Phase 3 over. Loop back to the beginning!
            obs.timer_remove(tick)
            start_timer()
        end
    end
end

function start_timer()
    obs.timer_remove(tick)
    current_state = "active"
    is_paused = false
    time_left = (active_min * 60) + active_sec
    
    play_sound(sound_a_name)
    update_text(math.floor(time_left / 60), time_left % 60)
    
    obs.timer_add(tick, 1000)
end

function pause_timer()
    if current_state == "stopped" then return end 
    
    if is_paused then
        -- It was paused, so resume it!
        obs.timer_add(tick, 1000)
        is_paused = false
    else
        -- It was running, so pause it!
        obs.timer_remove(tick)
        is_paused = true
    end
end

function reset_timer()
    obs.timer_remove(tick)
    current_state = "stopped"
    is_paused = false
    stop_sound(sound_a_name)
    stop_sound(sound_b_name)
    stop_sound(sound_c_name)
    
    local initial_time = (active_min * 60) + active_sec
    update_text(math.floor(initial_time / 60), initial_time % 60)
end