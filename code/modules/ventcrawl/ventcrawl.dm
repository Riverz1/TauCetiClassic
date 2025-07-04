var/global/list/ventcrawl_machinery = list(
	/obj/machinery/atmospherics/components/unary/vent_scrubber,
	/obj/machinery/atmospherics/components/unary/vent_pump
	)

// Vent crawling whitelisted items, whoo
/mob/living
	var/list/can_enter_vent_with = list(
		/obj/item/weapon/implant,
		/obj/item/device/radio/borg,
		/obj/item/weapon/holder,
		/obj/machinery/camera,
		/mob/living/simple_animal/borer,
		/mob/living/parasite
		)

	var/list/icon/pipes_shown = list()
	var/is_ventcrawling = 0
	var/ventcrawler = 0 //0 No vent crawling, 1 vent crawling in the nude, 2 vent crawling always
	var/next_play_vent = 0

/mob/living/proc/can_ventcrawl()
	if(!client)
		return FALSE
	if(!ventcrawler)
		to_chat(src, "<span class='warning'>You don't possess the ability to ventcrawl!</span>")
		return FALSE
	if(incapacitated())
		to_chat(src, "<span class='warning'>You cannot ventcrawl in your current state!</span>")
		return FALSE
	return ventcrawl_carry()

/mob/living/LateLogin()
	. = ..()
	//login during ventcrawl
	if(is_ventcrawling && istype(loc, /obj/machinery/atmospherics)) //attach us back into the pipes
		remove_ventcrawl()
		add_ventcrawl(loc)

/mob/living/carbon/slime/can_ventcrawl()
	if(Victim)
		to_chat(src, "<span class='warning'>You cannot ventcrawl while feeding.</span>")
		return FALSE
	. = ..()

/mob/living/proc/is_allowed_vent_crawl_item(obj/item/carried_item)
	if(is_type_in_list(carried_item, can_enter_vent_with))
		return TRUE//!get_inventory_slot(carried_item)

/mob/living/carbon/human/is_allowed_vent_crawl_item(obj/item/carried_item)
	if(carried_item in organs)
		return TRUE
	return ..()

/mob/living/simple_animal/spiderbot/is_allowed_vent_crawl_item(obj/item/carried_item)
	if(carried_item in list(held_item, radio, connected_ai, cell, camera, mmi))
		return TRUE
	return ..()

/mob/living/proc/ventcrawl_carry()
	if(ventcrawler < 2)
		for(var/atom/A in contents)
			if(!is_allowed_vent_crawl_item(A))
				to_chat(src, "<span class='warning'>You can't carry \the [A] while ventcrawling!</span>")
				return FALSE
	return TRUE

/mob/living/carbon/xenomorph/ventcrawl_carry()
	return TRUE

/obj/machinery/atmospherics/AltClick(mob/living/L)
	if(!istype(L))
		return

	if(!L.can_ventcrawl())
		return

	if(!suitable_for_ventcrawl())
		to_chat(L, "You can't enter to [src].")
		return

	if(!L.Adjacent(src))
		to_chat(L, "You must be standing on or beside an air vent to enter it.")
		return

	L.handle_ventcrawl(src, returnPipenet())

/mob/living/proc/ventcrawl_enter_delay()
	var/time = 40
	if(w_class)
		time = w_class ** 2
	return time

/mob/living/proc/handle_ventcrawl(obj/machinery/atmospherics/vent_found, datum/pipeline/vent_found_parent)
	if(is_busy())
		return
	to_chat(src, "You begin climbing into the ventilation system...")
	if(!do_after(src, ventcrawl_enter_delay(), null, vent_found))
		return

	if(!can_ventcrawl())
		return

	if(vent_found_parent)
		var/datum/gas_mixture/air_contents = vent_found_parent.air

		if(air_contents && !issilicon(src))

			switch(air_contents.temperature)
				if(0 to BODYTEMP_COLD_DAMAGE_LIMIT)
					to_chat(src, "<span class='danger'>You feel a painful freeze coming from the vent!</span>")
				if(BODYTEMP_COLD_DAMAGE_LIMIT to T0C)
					to_chat(src, "<span class='warning'>You feel an icy chill coming from the vent.</span>")
				if(T0C + 40 to BODYTEMP_HEAT_DAMAGE_LIMIT)
					to_chat(src, "<span class='warning'>You feel a hot wash coming from the vent.</span>")
				if(BODYTEMP_HEAT_DAMAGE_LIMIT to INFINITY)
					to_chat(src, "<span class='danger'>You feel a searing heat coming from the vent!</span>")

			switch(air_contents.return_pressure())
				if(0 to HAZARD_LOW_PRESSURE)
					to_chat(src, "<span class='danger'>You feel a rushing draw pulling you into the vent!</span>")
				if(HAZARD_LOW_PRESSURE to WARNING_LOW_PRESSURE)
					to_chat(src, "<span class='warning'>You feel a strong drag pulling you into the vent.</span>")
				if(WARNING_HIGH_PRESSURE to HAZARD_HIGH_PRESSURE)
					to_chat(src, "<span class='warning'>You feel a strong current pushing you away from the vent.</span>")
				if(HAZARD_HIGH_PRESSURE to INFINITY)
					to_chat(src, "<span class='danger'>You feel a roaring wind pushing you away from the vent!</span>")

	visible_message("<B>[src] scrambles into the ventilation ducts!</B>", "You climb into the ventilation system.")

	forceMove(vent_found)
	add_ventcrawl(vent_found)

/mob/living/proc/add_ventcrawl(obj/machinery/atmospherics/starting_machine)

	var/list/totalMembers = list()

	for(var/datum/pipeline/P in starting_machine.returnPipenets())
		if(P.members)
			totalMembers += P.members
		if(P.other_atmosmch)
			totalMembers += P.other_atmosmch

	if(!totalMembers.len)
		return

	is_ventcrawling = 1
	//candrop = 0

	for(var/X in totalMembers)
		if(!X)
			continue
		var/obj/machinery/atmospherics/A = X //all elements in totalMembers are necessarily of this type.
		if(!A.pipe_image)
			A.pipe_image = image(A, A.loc, dir = A.dir)
		A.pipe_image.plane = HUD_PLANE
		pipes_shown += A.pipe_image
		client.images += A.pipe_image

/mob/living/proc/remove_ventcrawl()
	is_ventcrawling = 0
	//candrop = 1
	if(client)
		for(var/image/current_image in pipes_shown)
			client.images -= current_image
		client.eye = src

	pipes_shown.len = 0
