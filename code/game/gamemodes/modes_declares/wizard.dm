/datum/game_mode/wizard
	name = "Wizard"
	config_name = "wizard"
	probability = 80
	factions_allowed = list(
		/datum/faction/wizards,
		/datum/faction/traitor, // Because just a wizards is too boring.
		)

	minimum_player_count = 2
	minimum_players_bundles = 10

/datum/game_mode/wizard/announce()
	to_chat(world, "<B>Текущий режим игры - Маг!</B>")
	to_chat(world, "<B>Это <span class='warning'>КОСМИЧЕСКИЙ МАГ</span> на станции. Нельзя допустить, чтобы он достиг своей цели!</B>")
	to_chat(world, "<B>Кроме того, на станции находятся агенты Cиндиката. Не дайте агентам добиться успеха!</B>")

