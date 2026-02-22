obs = obslua

local scene_name = "Website_Feed"
local browser_name = "Browser A"
local curtain_name = "Update_Curtain"
local text_source_name = "Status Text"
local custom_message = "UPDATING STANDINGS..."

local interval_min = 5
local interval_sec = 0
local wait_time = 12

local current_state = "stopped"
local is_paused = false
local time_left = 0

function script_description()
    return "Automated Scoreboard Curtain\n\nAutomatically fades in a cover graphic, updates its text, hard-refreshes the scoreboard behind it, and reveals it once loaded."
end

function script_properties()
    local props = obs.obs_properties_create()
    
    -- OBS Source Names
    obs.obs_properties_add_text(props, "scene", "Scene Name", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "browser", "Scoreboard Browser Name", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "curtain", "Curtain Group/Source Name", obs.OBS_TEXT_DEFAULT)
    
    -- Custom Text Options
    obs.obs_properties_add_text(props, "text_source", "Text Source Name (Inside Curtain)", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "custom_msg", "Message to Display", obs.OBS_TEXT_DEFAULT)
    
    -- Timings
    obs.obs_properties_add_int(props, "i_min", "Time Between Updates (Minutes)", 0, 120, 1)
    obs.obs_properties_add_int(props, "i_sec", "Time Between Updates (Seconds)", 0, 59, 1)
    obs.obs_properties_add_int(props, "delay", "Wait Time Behind Curtain (Seconds)", 3, 60, 1)
    
    -- Controls
    obs.obs_properties_add_button(props, "btn_start", "▶ START AUTOMATION", start_automation)
    obs.obs_properties_add_button(props, "btn_pause", "⏸ PAUSE / RESUME", pause_automation)
    obs.obs_properties_add_button(props, "btn_stop", "⏹ STOP AUTOMATION", stop_automation)
    
    obs.obs_properties_add_button(props, "btn_force", "🔄 FORCE UPDATE NOW", force_update)
    
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "scene", "Website_Feed")
    obs.obs_data_set_default_string(settings, "browser", "Browser A")
    obs.obs_data_set_default_string(settings, "curtain", "Update_Curtain")
    obs.obs_data_set_default_string(settings, "text_source", "Status Text")
    obs.obs_data_set_default_string(settings, "custom_msg", "UPDATING STANDINGS...")
    
    obs.obs_data_set_default_int(settings, "i_min", 5)
    obs.obs_data_set_default_int(settings, "i_sec", 0)
    obs.obs_data_set_default_int(settings, "delay", 12)
end

function script_update(settings)
    scene_name = obs.obs_data_get_string(settings, "scene")
    browser_name = obs.obs_data_get_string(settings, "browser")
    curtain_name = obs.obs_data_get_string(settings, "curtain")
    text_source_name = obs.obs_data_get_string(settings, "text_source")
    custom_message = obs.obs_data_get_string(settings, "custom_msg")
    
    interval_min = obs.obs_data_get_int(settings, "i_min")
    interval_sec = obs.obs_data_get_int(settings, "i_sec")
    wait_time = obs.obs_data_get_int(settings, "delay")
end

function get_item(name)
    local source = obs.obs_get_source_by_name(scene_name)
    if not source then return nil end
    local scene = obs.obs_scene_from_source(source)
    obs.obs_source_release(source)
    return obs.obs_scene_find_source(scene, name)
end

function update_curtain_text()
    if text_source_name and text_source_name ~= "" then
        local text_source = obs.obs_get_source_by_name(text_source_name)
        if text_source then
            local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", custom_message)
            obs.obs_source_update(text_source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(text_source)
        end
    end
end

function trigger_refresh()
    local source = obs.obs_get_source_by_name(browser_name)
    if source then
        local properties = obs.obs_source_properties(source)
        if properties then
            local property = obs.obs_properties_get(properties, "refreshnocache")
            if property then
                obs.obs_property_button_clicked(property, source)
            end
            obs.obs_properties_destroy(properties)
        end
        obs.obs_source_release(source)
    end
end

function set_curtain_visible(visible)
    local curtain_item = get_item(curtain_name)
    if curtain_item then
        obs.obs_sceneitem_set_visible(curtain_item, visible)
    end
end

function tick()
    if is_paused then return end

    if current_state == "running" then
        if time_left > 0 then
            time_left = time_left - 1
        else
            execute_update_sequence()
        end
        
    elseif current_state == "curtain_active" then
        if time_left > 0 then
            time_left = time_left - 1
        else
            -- Loading is done. Hide the curtain.
            set_curtain_visible(false)
            current_state = "running"
            time_left = (interval_min * 60) + interval_sec
        end
    end
end

function execute_update_sequence()
    update_curtain_text()
    set_curtain_visible(true)
    trigger_refresh()
    
    current_state = "curtain_active"
    time_left = wait_time
end

function force_update()
    if current_state == "curtain_active" then return end -- Prevent overlapping
    
    -- If the automation is stopped, temporarily start the timer just to handle the curtain drop
    if current_state == "stopped" then
        obs.timer_add(tick, 1000)
    end
    
    is_paused = false
    execute_update_sequence()
end

function start_automation()
    obs.timer_remove(tick)
    set_curtain_visible(false)
    current_state = "running"
    is_paused = false
    time_left = (interval_min * 60) + interval_sec
    obs.timer_add(tick, 1000)
end

function pause_automation()
    if current_state ~= "stopped" then
        is_paused = not is_paused
    end
end

function stop_automation()
    obs.timer_remove(tick)
    current_state = "stopped"
    is_paused = false
    set_curtain_visible(false)
end