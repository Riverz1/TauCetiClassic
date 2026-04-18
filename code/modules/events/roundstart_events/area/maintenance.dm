/datum/event/feature/area/maintenance_spawn
	special_area_types = list(/area/station/maintenance)
	var/list/possible_types = list()
	var/nums = 3

/datum/event/feature/area/maintenance_spawn/proc/spawn_atom(type, turf/T)
	if(T)
		message_admins("RoundStart Event: \"[event_meta.name]\" spawn '[type]' in [COORD(T)] - [ADMIN_JMP(T)]")
		log_game("RoundStart Event: \"[event_meta.name]\" spawn '[type]' in [COORD(T)]")
		new type(T)

/datum/event/feature/area/maintenance_spawn/start()
	for(var/i in 1 to nums)
		var/area/area = get_area_by_type(pick_n_take(targeted_areas))
		var/list/all_turfs = get_area_turfs(area, FALSE, ignore_blocked = TRUE)
		if(length(all_turfs))
			spawn_atom(pick(possible_types), pick(all_turfs))

/datum/event/feature/area/maintenance_spawn/invasion
	possible_types = list(
		/mob/living/simple_animal/hostile/giant_spider,
		/mob/living/simple_animal/hostile/shade,
		/mob/living/simple_animal/hostile/octopus,
		/mob/living/simple_animal/hostile/cyber_horror,
	)

/datum/event/feature/area/maintenance_spawn/invasion/setup()
	nums = rand(8, 12)
	. = ..()

/datum/event/feature/area/maintenance_spawn/antag_meta
	possible_types = list(
		/obj/effect/rune,
		/obj/item/weapon/kitchenknife/ritual,
		/obj/item/clothing/head/wizard,
		/obj/structure/alien/resin/wall/shadowling,
		/obj/structure/alien/resin/wall,
		/obj/structure/alien/weeds/node,
		/obj/item/weapon/card/emag_broken,
	)

/datum/event/feature/area/maintenance_spawn/antag_meta/setup()
	nums = rand(1, 3)
	possible_types += subtypesof(/obj/item/weapon/storage/box/syndie_kit)
	. = ..()

/datum/event/feature/area/maintenance_spawn/antag_meta/spawn_atom(type, turf/T)
	if(ispath(type, /obj/effect/rune))
		new /obj/effect/rune(T, null, null, TRUE)
	else if(ispath(type, /obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = new type(T)
		S.make_empty(TRUE)
	else
		new type(T)

	message_admins("RoundStart Event: \"[event_meta.name]\" spawn '[type]' in [COORD(T)] - [ADMIN_JMP(T)]")
	log_game("RoundStart Event: \"[event_meta.name]\" spawn '[type]' in [COORD(T)]")

/datum/event/feature/area/maintenance_spawn/corpse
	possible_types = list(/mob/living/carbon/human)

/datum/event/feature/area/maintenance_spawn/corpse/setup()
	nums = rand(2, 5)
	. = ..()

/datum/event/feature/area/maintenance_spawn/corpse/spawn_atom(type, turf/T)
	if(!istype(T))
		return

	var/mob/living/carbon/human/H = new(T)

	H.randomize_appearance()

	H.real_name = random_name(H.gender)
	H.name = H.real_name

	H.death()

	var/list/possible_roles = list("Assistant", "Engineer", "Scientist", "Security Officer",
		"Medical Doctor", "Cargo Technician", "Janitor", "Chef", "Bartender", "Chaplain", "Librarian")
	var/role = pick(possible_roles)

	var/cause = pick("brute", "burn", "toxin", "bleeding")
	var/list/body_zones = list("chest","head","l_arm","r_arm","l_leg","r_leg")

	switch(cause)
		if("brute")
			for(var/i in 1 to rand(4,7))
				H.apply_damage(rand(20,50), BRUTE, pick(body_zones))
		if("burn")
			for(var/i in 1 to rand(3,6))
				H.apply_damage(rand(15,40), BURN, pick(body_zones))
			H.adjustFireLoss(rand(30,60))
		if("toxin")
			H.adjustToxLoss(rand(60,100))
		else
			for(var/i in 1 to rand(3,5))
				H.apply_damage(rand(10,25), BRUTE, pick(body_zones))

	var/mutilation_desc = "none"
	if(prob(30))
		var/mutilation_type = pick("decapitate", "missing_limb", "severe_damage", "all")
		mutilation_desc = mutilation_type

		switch(mutilation_type)
			if("decapitate")
				H.apply_damage(200, BRUTE, "head")
				H.visible_message("<span class='danger'>Голова [H] отделяется от тела!</span>")
			if("missing_limb")
				var/limb = pick("l_arm","r_arm","l_leg","r_leg")
				H.apply_damage(200, BRUTE, limb)
				H.visible_message("<span class='danger'>[H] лишается конечности!</span>")
			if("severe_damage")
				for(var/i in 1 to rand(4,8))
					H.apply_damage(rand(30,60), BRUTE, pick(body_zones))
				H.adjustBruteLoss(rand(40,80))
			if("all")
				H.apply_damage(200, BRUTE, "head")
				for(var/limb in list("l_arm","r_arm","l_leg","r_leg"))
					if(prob(70))
						H.apply_damage(200, BRUTE, limb)
				H.visible_message("<span class='danger'>[H] изуродован до неузнаваемости!</span>")

	var/antag_hint = pick("none", "syndicate", "traitor", "unknown")
	var/real_evidence = prob(25)
	var/fake_evidence = prob(50)

	if(prob(80))
		new /obj/effect/decal/cleanable/blood(T)
	if(prob(50))
		var/turf/next = get_step(T, pick(NORTH,SOUTH,EAST,WEST))
		if(next)
			new /obj/effect/decal/cleanable/blood(next)

	equip_corpse(H, role)

	if(real_evidence)
		if(antag_hint == "syndicate")
			var/list/syndie_evidence = list(/obj/item/weapon/card/emag_broken = 50, /obj/item/weapon/storage/belt/military = 15)
			for(var/path in syndie_evidence)
				if(prob(syndie_evidence[path]))
					new path(T)
					break
		else if(antag_hint == "traitor")
			var/list/traitor_evidence = list(/obj/item/weapon/card/id/syndicate = 30, /obj/item/weapon/storage/fancy/donut_box/traitor = 20)
			for(var/path in traitor_evidence)
				if(prob(traitor_evidence[path]))
					new path(T)
					break

	if(fake_evidence)
		if(prob(50))
			new /obj/item/weapon/kitchenknife/ritual(T)
		else
			new /obj/item/weapon/crowbar(T)

		var/list/misc_trash = list(
			/obj/item/clothing/mask/cigarette, /obj/item/trash/cheesie,
			/obj/item/trash/candy, /obj/item/weapon/paper/crumpled, /obj/item/weapon/paper_bin,
			/obj/item/clothing/glasses/regular, /obj/item/clothing/head/that, /obj/item/clothing/shoes/laceup,
			/obj/item/weapon/storage/wallet, /obj/item/weapon/storage/fancy/cigarettes
		)
		if(prob(30))
			var/trash_path = pick(misc_trash)
			new trash_path(T)
		if(prob(10))
			var/trash_path = pick(misc_trash)
			new trash_path(T)

	create_suicide_note(H, T, role, cause, real_evidence, fake_evidence, antag_hint)

	H.nutrition = rand(50, 400)
	H.update_body()
	H.update_icons()

	var/coord = "[T.x],[T.y],[T.z]"
	message_admins("Corpse ([role], cause=[cause], real=[real_evidence], fake=[fake_evidence], mutilation=[mutilation_desc]) at [coord] - [ADMIN_JMP(T)]")
	log_game("Corpse ([role], cause=[cause], real=[real_evidence], fake=[fake_evidence], mutilation=[mutilation_desc]) at [coord]")

/datum/event/feature/area/maintenance_spawn/corpse/proc/equip_corpse(mob/living/carbon/human/H, role)
	var/static/list/uniform_map = list(
		"Engineer" = /obj/item/clothing/under/rank/engineer,
		"Scientist" = /obj/item/clothing/under/rank/scientist,
		"Security Officer" = /obj/item/clothing/under/rank/security,
		"Medical Doctor" = /obj/item/clothing/under/rank/medical,
		"Cargo Technician" = /obj/item/clothing/under/rank/cargotech,
		"Janitor" = /obj/item/clothing/under/rank/janitor,
		"Chef" = /obj/item/clothing/under/rank/chef,
		"Bartender" = /obj/item/clothing/under/rank/bartender,
		"Chaplain" = /obj/item/clothing/under/rank/chaplain,
		"Librarian" = /obj/item/clothing/under/suit_jacket/red,
		"Assistant" = /obj/item/clothing/under/color/grey
	)
	var/static/list/suit_map = list(
		"Engineer" = /obj/item/clothing/suit/storage/hazardvest,
		"Security Officer" = /obj/item/clothing/suit/storage/flak,
		"Scientist" = /obj/item/clothing/suit/storage/labcoat,
		"Medical Doctor" = /obj/item/clothing/suit/storage/labcoat,
		"Cargo Technician" = /obj/item/clothing/suit/apron/overalls,
		"Chef" = /obj/item/clothing/suit/chef,
		"Bartender" = /obj/item/clothing/suit/armor/vest,
		"Chaplain" = /obj/item/clothing/suit/hooded/skhima
	)
	var/static/list/backpack_map = list(
		"Security Officer" = /obj/item/weapon/storage/backpack/security,
		"Engineer" = /obj/item/weapon/storage/backpack/industrial,
		"Scientist" = /obj/item/weapon/storage/backpack/backpack_tox,
		"Medical Doctor" = /obj/item/weapon/storage/backpack/medic
	)
	var/static/list/belt_map = list(
		"Security Officer" = /obj/item/weapon/storage/belt/security,
		"Engineer" = /obj/item/weapon/storage/belt/utility,
		"Scientist" = /obj/item/weapon/storage/belt/utility,
		"Medical Doctor" = /obj/item/weapon/storage/belt/medical
	)
	var/static/list/headset_map = list(
		"Engineer" = /obj/item/device/radio/headset/headset_eng,
		"Security Officer" = /obj/item/device/radio/headset/headset_sec,
		"Scientist" = /obj/item/device/radio/headset/headset_sci,
		"Medical Doctor" = /obj/item/device/radio/headset/headset_med,
		"Cargo Technician" = /obj/item/device/radio/headset/headset_cargo
	)
	var/static/list/glasses_map = list(
		"Medical Doctor" = /obj/item/clothing/glasses/hud/health,
		"Security Officer" = /obj/item/clothing/glasses/sunglasses/hud/sechud,
		"Scientist" = /obj/item/clothing/glasses/science,
		"Engineer" = /obj/item/clothing/glasses/welding
	)
	var/static/list/gloves_map = list(
		"Medical Doctor" = /obj/item/clothing/gloves/latex,
		"Security Officer" = /obj/item/clothing/gloves/security,
		"Scientist" = /obj/item/clothing/gloves/latex,
		"Engineer" = /obj/item/clothing/gloves/insulated
	)
	var/static/list/id_map = list(
		"Engineer" = /obj/item/weapon/card/id/eng,
		"Scientist" = /obj/item/weapon/card/id/sci,
		"Security Officer" = /obj/item/weapon/card/id/sec,
		"Medical Doctor" = /obj/item/weapon/card/id/med,
		"Cargo Technician" = /obj/item/weapon/card/id/cargo
	)
	var/static/list/civilian_roles = list("Janitor", "Chef", "Bartender", "Chaplain", "Librarian", "Assistant")

	var/uniform_path = uniform_map[role] || /obj/item/clothing/under/color/black
	H.equip_to_slot_or_del(new uniform_path(H), SLOT_W_UNIFORM)

	if(prob(90))
		var/shoes_path = pick(/obj/item/clothing/shoes/black, /obj/item/clothing/shoes/brown,
			/obj/item/clothing/shoes/laceup, /obj/item/clothing/shoes/sandal)
		H.equip_to_slot_or_del(new shoes_path(H), SLOT_SHOES)

	if(prob(40))
		var/head_path
		if(role == "Security Officer" && prob(40))
			head_path = /obj/item/clothing/head/helmet
		else
			head_path = pick(/obj/item/clothing/head/soft, /obj/item/clothing/head/ushanka, /obj/item/clothing/head/welding)
		H.equip_to_slot_or_del(new head_path(H), SLOT_HEAD)

	if(prob(30))
		var/mask_path = pick(/obj/item/clothing/mask/gas, /obj/item/clothing/mask/bandana,
			/obj/item/clothing/mask/breath, /obj/item/clothing/mask/cigarette)
		H.equip_to_slot_or_del(new mask_path(H), SLOT_WEAR_MASK)

	if(prob(50))
		var/suit_path = suit_map[role] || pick(/obj/item/clothing/suit/jacket, /obj/item/clothing/suit/poncho,
			/obj/item/clothing/suit/storage/hazardvest)
		H.equip_to_slot_or_del(new suit_path(H), SLOT_WEAR_SUIT)

	if(prob(80))
		var/back_path = backpack_map[role] || pick(/obj/item/weapon/storage/backpack, /obj/item/weapon/storage/backpack/alt,
			/obj/item/weapon/storage/backpack/satchel, /obj/item/weapon/storage/backpack/dufflebag)
		var/obj/item/weapon/storage/backpack/B = new back_path(H)
		H.equip_to_slot_or_del(B, SLOT_BACK)

		if(prob(50))
			var/static/list/backpack_loot = list(
				/obj/item/weapon/crowbar, /obj/item/weapon/wrench, /obj/item/weapon/wirecutters,
				/obj/item/weapon/screwdriver, /obj/item/device/flashlight, /obj/item/weapon/reagent_containers/food/snacks/chips,
				/obj/item/weapon/reagent_containers/food/drinks/coffee, /obj/item/trash/candy, /obj/item/weapon/paper, /obj/item/weapon/pen
			)
			var/loot_path = pick(backpack_loot)
			new loot_path(B)

	if(prob(40))
		var/belt_path = belt_map[role] || /obj/item/weapon/storage/belt
		H.equip_to_slot_or_del(new belt_path(H), SLOT_BELT)

	if(prob(70))
		var/headset_path = headset_map[role] || /obj/item/device/radio/headset
		H.equip_to_slot_or_del(new headset_path(H), SLOT_EARS)

	if(prob(50))
		var/glasses_path = glasses_map[role] || pick(/obj/item/clothing/glasses/regular, /obj/item/clothing/glasses/sunglasses)
		H.equip_to_slot_or_del(new glasses_path(H), SLOT_GLASSES)

	if(prob(50))
		var/glove_path = gloves_map[role] || pick(/obj/item/clothing/gloves/black, /obj/item/clothing/gloves/latex,
			/obj/item/clothing/gloves/fingerless, /obj/item/clothing/gloves/boxing, /obj/item/clothing/gloves/white)
		H.equip_to_slot_or_del(new glove_path(H), SLOT_GLOVES)

	if(prob(70))
		var/static/list/pocket_items = list(
			/obj/item/weapon/cigbutt, /obj/item/weapon/lighter, /obj/item/weapon/pen,
			/obj/item/weapon/paper, /obj/item/weapon/reagent_containers/food/snacks/candy, /obj/item/weapon/reagent_containers/food/drinks/coffee,
			/obj/item/weapon/storage/fancy/cigarettes, /obj/item/device/flashlight/pen, /obj/item/weapon/coin/gold,
			/obj/item/weapon/coin/silver, /obj/item/weapon/coin/iron
		)
		var/pocket_path = pick(pocket_items)
		H.equip_to_slot_or_del(new pocket_path(H), pick(SLOT_L_STORE, SLOT_R_STORE))

	if(prob(80))
		var/id_type
		if(role in civilian_roles)
			id_type = /obj/item/weapon/card/id/civ
		else
			id_type = id_map[role] || /obj/item/weapon/card/id

		var/obj/item/weapon/card/id/ID = new id_type(H)
		ID.registered_name = H.real_name
		ID.assignment = role
		ID.name = "[H.real_name]'s ID Card ([role])"
		H.equip_to_slot_or_del(ID, SLOT_WEAR_ID)

/datum/event/feature/area/maintenance_spawn/corpse/proc/create_suicide_note(mob/living/carbon/human/H, turf/T, role, cause, real_evidence, fake_evidence, antag_hint)
	if(!prob(70))
		return

	var/obj/item/weapon/paper/P = new(T)

	var/static/list/intro = list("Если вы это читаете, то меня уже нет.", "Не знаю, кто найдёт это...",
		"Записываю это на всякий случай.", "Это, наверное, моя последняя запись.", "Чёрт... если кто-то это читает...",
		"...они не должны были добраться сюда.")
	var/list/role_lines = list("Я был [role].", "Моя должность — [role].", "[role]... не самая безопасная работа, как оказалось.",
		"Я просто выполнял свою работу [role].")
	var/list/cause_lines_brute = list("Меня забили.", "Они били снова и снова.", "Слишком много ударов...", "Я не успел защититься.")
	var/list/cause_lines_burn = list("Всё было в огне.", "Я сгорел...", "Пламя было повсюду.", "Огонь не оставил шансов.")
	var/list/cause_lines_toxin = list("Что-то не так с воздухом.", "Меня отравили.", "Я не чувствую тела...", "Это было в еде... или нет?")
	var/list/cause_lines_bleeding = list("Я истекаю кровью.", "Слишком много крови...", "Не могу остановить это...", "Кажется, я уже не чувствую рук.")
	var/static/list/emotion = list("Мне страшно.", "Я слышу шаги.", "Они рядом.", "Это была ошибка.", "Никто не пришёл.", "Я не должен был сюда идти.")
	var/static/list/noise = list("...", "*шум*", "*кровь на бумаге*", "почерк становится неровным", "часть текста смазана", "здесь что-то было стёрто")
	var/static/list/final_lines = list("Не доверяйте никому.", "Бегите.", "Станция обречена.", "Они ещё здесь.", "Закройте шлюзы.", "Слишком поздно.")

	var/text = pick(intro)

	if(prob(60))
		text += " " + pick(role_lines)

	if(prob(80))
		switch(cause)
			if("brute")     text += " " + pick(cause_lines_brute)
			if("burn")      text += " " + pick(cause_lines_burn)
			if("toxin")     text += " " + pick(cause_lines_toxin)
			if("bleeding")  text += " " + pick(cause_lines_bleeding)
			else            text += " " + pick(cause_lines_brute)

	if(prob(50))
		text += " " + pick(emotion)

	if(real_evidence)
		if(antag_hint == "syndicate")
			text += " " + pick("Это был Синдикат.", "Я видел их снаряжение.", "Это точно не кто-то случайный.", "Они знали, что делают.")
		else if(antag_hint == "traitor")
			text += " " + pick("Это кто-то из экипажа.", "Я его знал...", "Он притворялся нормальным.", "Кто-то из наших.")
	else if(fake_evidence)
		text += " " + pick("Кажется, это был клоун...", "Я слышал смех.", "Видел красный нос... наверное.", "Может, это просто шутка...")

	if(prob(60))
		text += " " + pick(noise)
	if(prob(70))
		text += " " + pick(final_lines)

	if(prob(20))
		var/cut_pos = min(rand(20, length(text)), length(text))
		text = uppertext(copytext(text, 1, cut_pos)) + copytext(text, cut_pos)
	if(prob(15))
		text += " " + text
	if(prob(10))
		text = replacetext(text, " ", "... ")

	P.info = text
	P.name = pick("Предсмертная записка", "Окровавленная записка", "Смятая бумага", "Обрывок записи")
	P.update_icon()
