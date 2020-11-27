local mod = get_mod("BossTimer")


-- map [unit hash -> string name]
mod.bossname = {}

-- start times of all boss fights
mod.start = {}

-- if we want to skip messages
mod.skip = false
mod.skip_terror_events = {
	"mines_end_event_intro_trolls",
	"mines_end_event_trolls",
}

-- map [unit -> true/false]
mod.intro_started = {}

-- used because naglfahr transforms intro regular chaos spawn
mod.time_start_fighting_naglfahr = nil

mod.text = nil
mod.start_display_time = nil
mod.text_rasknitt = nil
mod.start_display_time_rasknitt = nil

-- rasknitt or deathrattler died - save time to compute difference
mod.oneDead = nil

mod.text_duration = 5 -- in seconds


mod.get_game_time = function()
	return Managers.time:time("game")
end

mod.is_me = function(unit)
	return (unit == Managers.player:local_player().player_unit)
end


mod.skip_event = function(event_name)
	local skp = false
	for _,item in ipairs(mod.skip_terror_events) do
		if item == event_name then
			skp = true
		end
	end
	return skp
end


-- variable to save rasknitt unit hash when he spawns
mod.rasknitt = nil
mod.deathrattler = nil

mod:hook_safe(LevelTransitionHandler, "load_level", function (self, level_key, ...)

	-- reset all variables when loading level
	mod.time_start_fighting_naglfahr = nil
	mod.text = nil
	mod.start_display_time = nil
	mod.text_rasknitt = nil
	mod.start_display_time_rasknitt = nil
	
	mod.oneDead = nil
	mod.rasknitt_fight = false
	
	mod.deathrattler_intro = false
	mod.rasknitt = nil
	mod.burb_intro = false
	
	mod.is_warcamp_mission = level_key == "warcamp"
	
	-- no timers should be carried over from earlier games
	mod.bossname = {}

	mod.start = {}
end)


-- message when boss killed
mod:hook(IngameUI, "update", function (func, self, ...)

	if mod.text and mod:get("activated") then
		if mod.get_game_time() - mod.start_display_time < mod.text_duration then
			mod.show_display_kill_message(self, mod.text, false)
		else
			mod.text = nil
			mod.start_display_time = nil
		end
	end
	
	if mod.text_rasknitt and mod.start_display_time_rasknitt then
		if mod.get_game_time() - mod.start_display_time_rasknitt < mod.text_duration then
			mod.show_display_kill_message(self, mod.text_rasknitt, true)
		else
			mod.text_rasknitt = nil
			mod.start_display_time_rasknitt = nil
		end
	end
	
	-- original function
	return func(self, ...)

end)


mod.show_display_kill_message = function(self, text, is_second_line)
	
	local font_name = "gw_head"
	local font_mtrl = "materials/fonts/" .. font_name

	local w, h = UIResolution()
	local font_size = h / 40   -- 27 for 1080p and 36 for 1440p

	mod:pcall(function()
		local width, height = UIRenderer.text_size(self.ui_top_renderer, text, font_mtrl, font_size)
		width, height = width * RESOLUTION_LOOKUP.scale, height * RESOLUTION_LOOKUP.scale
		
		if is_second_line then
			height = 3*height
		end
		
		height_perc = h / 4*3
		width_perc = w / 2
		UIRenderer.draw_text(self.ui_top_renderer, text, font_mtrl, font_size, font_name, UIInverseScaleVectorToResolution({width_perc - width/2, height_perc - height/2}), Colors.color_definitions.white)
	end)

end

-- remember spawn time
mod:hook(World, "spawn_unit", function (func, self, unit_name, ...)

	local unit = func(self, unit_name, ...)
	
	-- mod:echo("spawn: "..tostring(unit_name))
	
	if mod.skip then
		-- mod:echo("skip "..tostring(unit))
		return unit
	end
	
	if unit_name == "units/beings/enemies/skaven_stormfiend/chr_skaven_stormfiend" then
		mod.bossname[unit] = "Stormfiend"
		mod.start[unit] = mod.get_game_time()
	elseif unit_name == "units/beings/enemies/skaven_rat_ogre/chr_skaven_rat_ogre" then
		mod.bossname[unit] = "Rat Ogre"
		mod.start[unit] = mod.get_game_time()
	elseif unit_name == "units/beings/enemies/chaos_troll/chr_chaos_troll" then
		mod.bossname[unit] = "Bile Troll"
		mod.start[unit] = mod.get_game_time()
	elseif unit_name == "units/beings/enemies/beastmen_minotaur/chr_beastmen_minotaur" then
		mod.bossname[unit] = "Minotaur"
		mod.start[unit] = mod.get_game_time()
	elseif unit_name == "units/beings/enemies/chaos_spawn/chr_chaos_spawn" then
		
		--------------------------------------------------------
		-- Naglfahr transformation also spawns chaos spawn :( --
		--------------------------------------------------------
		
		if mod.time_start_fighting_naglfahr ~= nil then
			mod.bossname[unit] = "Gatekeeper Naglfahr"
			
			mod.start[unit] = mod.time_start_fighting_naglfahr
			mod.time_start_fighting_naglfahr = nil
		else
			mod.bossname[unit] = "Chaos Spawn"
			mod.start[unit] = mod.get_game_time()
		end
	
	elseif unit_name == "units/beings/enemies/skaven_stormvermin_champion/chr_skaven_stormvermin_warlord" then
		mod.bossname[unit] = "Skarrik Spinemanglr"
	elseif unit_name == "units/beings/enemies/chaos_sorcerer_boss/chr_chaos_sorcerer_boss" then
		mod.bossname[unit] = "Burblespue Halescourge"
	elseif unit_name == "units/beings/enemies/chaos_warrior_boss/chr_chaos_warrior_boss" then
		if mod.is_warcamp_mission then
			mod.bossname[unit] = "Bödvarr Ribspreader"
		else
			mod.bossname[unit] = "Gatekeeper Naglfahr"
			mod.time_start_fighting_naglfahr = mod.get_game_time()
		end
		
	elseif unit_name == "units/beings/enemies/skaven_grey_seer/chr_skaven_grey_seer" then
		mod.bossname[unit] = "Rasknitt"
		mod.rasknitt = unit
	elseif unit_name == "units/beings/enemies/skaven_stormfiend/chr_skaven_stormfiend_boss" then
		mod.bossname[unit] = "Deathrattler"
		mod.deathrattler = unit
	elseif unit_name == "units/beings/enemies/chaos_sorcerer_boss_drachenfels/chr_chaos_sorcerer_boss_drachenfels" then
		mod.bossname[unit] = "Nurgloth the Eternal"
	end
	
	return unit
	
end)



--------------------------------------------------------
-- time difference of rasknitt and deathrattler death --
--------------------------------------------------------


mod:hook(DeathSystem, "kill_unit", function(func, self, unit, ...)
	
	if mod.start[unit] then -- not nil
			
		local time_end = mod.get_game_time()
		
		if mod.bossname[unit] then
			
			--visual
			mod.text = mod.bossname[unit] .. " died after"
			if math.floor((time_end - mod.start[unit])/60) > 0 then
				local time_min = math.floor((time_end - mod.start[unit])/60)
				mod.text = mod.text .. " " .. tostring(time_min) .. " minute"
				if time_min > 1 then
					mod.text = mod.text .. "s"
				end
			end
			mod.text = mod.text .. " " .. tostring(math.floor((time_end - mod.start[unit])%60)) .. " seconds."
			if mod:get("activated_text") then
				local pop_chat = true
				Managers.chat:add_local_system_message(1, mod.text, pop_chat)
			end
			mod.start_display_time = mod.get_game_time()
		
			-- if rasknitt dies
			if mod.rasknitt_fight then
				if mod.oneDead == nil then
					-- rasknitt or deathrattler still alive
					mod.oneDead = time_end - mod.start[unit]
				else
					-- both bosses dead
					local diff = math.floor((time_end - mod.start[unit]) - mod.oneDead)
					
					-- visual
					mod.text_rasknitt = "The Grey Seer Rasknitt died " .. tostring(diff) .. " sec after his buddy Deathrattler."
					mod.start_display_time_rasknitt = mod.get_game_time()
					if mod:get("activated_text") then
						local pop_chat = true
						Managers.chat:add_local_system_message(1, mod.text_rasknitt, pop_chat)
					end
					
					-- reset
					mod.oneDead = nil
					mod.rasknitt = nil
					mod.deathrattler = nil
					mod.rasknitt_fight = false
				end
			end
		
		end
		
		-- reset
		mod.bossname[unit] = nil
		mod.start[unit] = nil
		
	else
		-- mod:echo("unit died, boss alive since " .. tostring(mod.start))
	end
	
	return func(self, unit, ...)
end)



--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- SKIP SOME NOTIFICATIONS (troll kills at the ending of the darkness mission)
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

mod:hook(ConflictDirector, "start_terror_event", function (func, self, event_name, ...)
	
	mod.skip = mod.skip_event(event_name)
	
	return func(self, event_name, ...)
end)

-- TelemetryEvents.terror_event_started = function (self, event_name)


mod.update = function(self)
	
	for unit,name in pairs(mod.bossname) do
		local ai_extension = ScriptUnit.extension(unit, "ai_system")
		if ai_extension then
			
			local bt_node_name = ai_extension:current_action_name()
			if not mod.intro_started[unit] and (bt_node_name == "intro_idle" or bt_node_name == "dual_shoot_intro") then
				-- mod:echo("start intro")
				mod.intro_started[unit] = true
			end
			
			if mod.intro_started[unit] and not (bt_node_name == "intro_idle" or bt_node_name == "dual_shoot_intro") then
				-- mod:echo("intro finished")
				
				mod.intro_started[unit] = nil
				mod.start[unit] = mod.get_game_time()
				if unit == mod.deathrattler and mod.rasknitt then
					mod.start[mod.rasknitt] = mod.get_game_time()
					mod.rasknitt_fight = true
				end
			end
			
			-- mod:echo(tostring(mod.intro_started[unit]).." "..tostring(bt_node_name))
		end
		
	end
	
end

