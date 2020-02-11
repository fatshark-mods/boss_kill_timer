return {
	run = function()
		fassert(rawget(_G, "new_mod"), "BossTimer must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("BossTimer", {
			mod_script       = "scripts/mods/BossTimer/BossTimer",
			mod_data         = "scripts/mods/BossTimer/BossTimer_data",
			mod_localization = "scripts/mods/BossTimer/BossTimer_localization"
		})
	end,
	packages = {
		"resource_packages/BossTimer/BossTimer"
	}
}
