local mod = get_mod("BossTimer")

-- Everything here is optional. You can remove unused parts.
return {
	name = "BossKillTimer",                             -- Readable mod name
	description = mod:localize("mod_description"),  -- Mod description
	is_togglable = true,                            -- If the mod can be enabled/disabled
	is_mutator = false,                             -- If the mod is mutator
	mutator_settings = {},                          -- Extra settings, if it's mutator
	options_widgets = {                             -- Widget settings for the mod options menu
		{
			["setting_name"] = "activated",
			["widget_type"] = "checkbox",
			["text"] = mod:localize("box"),
			["default_value"] = true
		},
		{
			["setting_name"] = "activated_text",
			["widget_type"] = "checkbox",
			["text"] = mod:localize("box2"),
			["default_value"] = true
		},
	}
}