/*
 * Cryogenic refrigeration unit. Basically a despawner.
 * Stealing a lot of concepts/code from sleepers due to massive laziness.
 * The despawn tick will only fire if it's been more than time_till_despawned ticks
 * since time_entered, which is world.time when the occupant moves in.
 * ~ Zuhayr
 */

//Used for logging people entering cryosleep and important items they are carrying.
var/global/list/frozen_crew = list()
var/global/list/frozen_items = list()

//Main cryopod console.

/obj/machinery/computer/cryopod
	name = "Cryogenic Oversight Console"
	desc = "An interface between crew and the cryogenic storage oversight systems."
	icon = 'icons/obj/Cryogenic3.dmi'
	icon_state = "cellconsole"
	circuit = /obj/item/weapon/circuitboard/cryopodcontrol
	var/mode = null

/obj/machinery/computer/cryopod/ui_interact(mob/user)
	if(!SSticker)
		return

	var/dat

	dat += "<div class='Section__title'>Cryogenic Oversight Control</div>"
	dat += "<div class='Section'>"
	dat += "<i>Welcome, [user.real_name].</i><br/><br/>"
	dat += "<a href='byond://?src=\ref[src];log=1'>View storage log</a><br>"
	dat += "<a href='byond://?src=\ref[src];item=1'>Recover object</a><br>"
	dat += "<a href='byond://?src=\ref[src];allitems=1'>Recover all objects</a><br>"
	dat += "<a href='byond://?src=\ref[src];crew=1'>Revive crew</a><br/>"
	dat += "</div>"

	var/datum/browser/popup = new(user, "window=cryopod_console", src.name)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/cryopod/Topic(href, href_list)
	. = ..()
	if(!.)
		return

	var/mob/user = usr

	if(href_list["log"])

		var/dat = "<b>Recently stored crewmembers</b><br/><hr/><br/>"
		for(var/person in frozen_crew)
			dat += "[person]<br/>"
		dat += "<hr/>"

		var/datum/browser/popup = new(user, "window=cryolog", src.name + ": Log")
		popup.set_content(dat)
		popup.open()

	else if(href_list["item"])

		if(frozen_items.len == 0)
			to_chat(user, "<span class='notice'>There is nothing to recover from storage.</span>")
			return

		var/obj/item/I = input(usr, "Please choose which object to retrieve.","Object recovery",null) as obj in frozen_items
		if(!can_still_interact_with(usr))
			return

		if(!I || frozen_items.len == 0)
			to_chat(user, "<span class='notice'>There is nothing to recover from storage.</span>")
			return

		visible_message("<span class='notice'>The console beeps happily as it disgorges \the [I].</span>", 3)

		I.loc = get_turf(src)
		frozen_items -= I

	else if(href_list["allitems"])

		if(frozen_items.len == 0)
			to_chat(user, "<span class='notice'>There is nothing to recover from storage.</span>")
			return

		visible_message("<span class='notice'>The console beeps happily as it disgorges the desired objects.</span>", 3)

		for(var/obj/item/I in frozen_items)
			I.loc = get_turf(src)
			frozen_items -= I

	else if(href_list["crew"])
		to_chat(user, "<span class='red'>Functionality unavailable at this time.</span>")

	updateUsrDialog()

/obj/item/weapon/circuitboard/cryopodcontrol
	details = "circuit board (Cryogenic Oversight Console)"
	build_path = /obj/machinery/computer/cryopod
	origin_tech = "programming=3"

//Decorative structures to go alongside cryopods.
/obj/structure/cryofeed

	name = "cryogenic feed"
	desc = "A bewildering tangle of machinery and pipes."
	icon = 'icons/obj/Cryogenic3.dmi'
	icon_state = "cryo_rear"
	anchored = TRUE
	density = TRUE

	var/orient_right = null //Flips the sprite.

/obj/structure/cryofeed/right
	orient_right = 1
	icon_state = "cryo_rear-r"

/obj/structure/cryofeed/atom_init()

	if(orient_right)
		icon_state = "cryo_rear-r"
	else
		icon_state = "cryo_rear"
	. = ..()

//Cryopods themselves.
/obj/machinery/cryopod
	name = "cryogenic freezer"
	desc = "A man-sized pod for entering suspended animation."
	icon = 'icons/obj/Cryogenic3.dmi'
	icon_state = "cryosleeper_left"
	density = TRUE
	anchored = TRUE
	req_one_access = list(access_heads, access_security)
	var/storage = 1	//tc, criopods on centcomm

	var/orient_right = null      // Flips the sprite.
	var/time_till_despawn = 9000 // 15 minutes-ish safe period before being despawned.
	var/time_entered = 0         // Used to keep track of the safe period.
	var/obj/item/device/radio/intercom/announce //

	// These items are preserved when the process() despawn proc occurs.
	var/list/preserve_items = list(
		/obj/item/weapon/hand_tele,
		/obj/item/weapon/card/id/captains_spare,
		/obj/item/device/aicard,
		/obj/item/device/mmi,
		/obj/item/device/paicard,
		/obj/item/weapon/gun,
		/obj/item/weapon/pinpointer,
		/obj/item/clothing/suit,
		/obj/item/clothing/shoes/magboots,
		/obj/item/blueprints,
		/obj/item/clothing/head/helmet/space
	)

/obj/machinery/cryopod/right
	orient_right = 1
	icon_state = "cryosleeper_right"

/obj/machinery/cryopod/atom_init()

	announce = new /obj/item/device/radio/intercom(null)
	. = ..()

/obj/machinery/cryopod/Destroy()
	. = ..()
	QDEL_NULL(announce)

/obj/machinery/cryopod/ex_act(severity)
	switch(severity)
		if(EXPLODE_HEAVY)
			if(prob(50))
				return
		if(EXPLODE_LIGHT)
			if(prob(75))
				return
	for(var/atom/movable/A as anything in contents)
		A.forceMove(get_turf(src))
		A.ex_act(severity)
	qdel(src)

/obj/machinery/cryopod/proc/delete_objective(datum/objective/target/O)
	if(!O)
		return

	//We don't want revs to get objectives that aren't for heads of staff. Letting them win or lose based on cryo is silly so we remove the objective.
	if(!istype(O, /datum/objective/target/rp_rev))
		O.find_target()

	if(!O.target)
		target_objectives -= O
		var/datum/faction/F = O.faction
		if(F)
			F.handleRemovedObjective(O)
			return

		if(O.owner)
			for(var/role in O.owner.antag_roles)
				var/datum/role/R = O.owner.antag_roles[role]
				R.handleRemovedObjective(O)
			return

		qdel(O)

/obj/machinery/cryopod/proc/remove_objective(datum/objective/target/O)
	if(O.target != occupant.mind)
		return

	if(O?.owner?.current)
		to_chat(O.owner.current, "<span class='red'>You get the feeling your target is no longer within your reach. Time for Plan [pick(list("A","B","C","D","X","Y","Z"))]...</span>")

	O.target = null

	addtimer(CALLBACK(src, PROC_REF(delete_objective), O), 1) //This should ideally fire after the occupant is deleted.

//Lifted from Unity stasis.dm and refactored. ~Zuhayr
/obj/machinery/cryopod/process()
	if(occupant)

		//Allow a ten minute gap between entering the pod and actually despawning.
		if(world.time - time_entered < time_till_despawn)
			return

		if(!occupant.client && occupant.stat != DEAD) //Occupant is living and has no client.
			if(occupant.key != null && occupant.key[1] == "@") //for aghosted mobs and those who are using remote control
				return
			//Drop all items into the pod.
			for(var/obj/item/W in occupant)
				occupant.drop_from_inventory(W)
				preserve_item(W)

			//Update any existing objectives involving this mob.
			for(var/datum/objective/target/O in target_objectives)
				remove_objective(O)

			//Handle job slot/tater cleanup.
			if(occupant && occupant.mind)
				var/job = occupant.mind.assigned_role
				SSjob.FreeRole(job)
				if(occupant.ckey)
					SSStatistics.add_leave_stat(occupant.mind, "Cryopod")

			// Delete them from datacore.

			PDA_Manifest.Cut()
			for(var/datum/data/record/R in data_core.medical)
				if ((R.fields["name"] == occupant.real_name))
					qdel(R)
			for(var/datum/data/record/T in data_core.security)
				if ((T.fields["name"] == occupant.real_name))
					qdel(T)
			for(var/datum/data/record/G in data_core.general)
				if ((G.fields["name"] == occupant.real_name))
					qdel(G)

			//This should guarantee that ghosts don't spawn.
			occupant.ckey = null

			//Make an announcement and log the person entering storage.
			if(storage)
				frozen_crew += "[occupant.real_name]"

				announce.autosay("[occupant.real_name] has entered long-term storage.", "Cryogenic Oversight")
			visible_message("<span class='notice'>The crypod hums and hisses as it moves [occupant.real_name] into storage.</span>", 3)

			// Delete the mob.
			qdel(occupant)
			occupant = null

			open_machine()

/obj/machinery/cryopod/attackby(obj/item/weapon/G, mob/user)

	if(istype(G, /obj/item/weapon/grab))
		var/obj/item/weapon/grab/grab = G
		if(!user.IsAdvancedToolUser())
			to_chat(user, "<span class='notice'>You have no idea how to do that.</span>")
			return

		if(occupant)
			to_chat(user, "<span class='notice'>The cryo pod is in use.</span>")
			return

		if(!ishuman(grab.affecting))
			return

		var/willing = null //We don't want to allow people to be forced into despawning.
		var/mob/M = grab.affecting
		user.SetNextMove(CLICK_CD_MELEE)

		if(M.client)
			if(tgui_alert(M,"Would you like to enter cryosleep?",, list("Yes","No")) == "Yes")
				if(!M || !grab || !grab.affecting)
					return
				willing = TRUE
		else
			willing = TRUE

		if(willing)
			if(user.is_busy()) return
			visible_message("[user] starts putting [M.name] into the cryo pod.", 3)

			if(do_after(user, 20, target = src))
				if(!M || !grab || !grab.affecting)
					return
				insert(M)
				// Book keeping!
				log_admin("[key_name(M)] has entered a stasis pod.")
				message_admins("<span class='notice'>[key_name_admin(M)] has entered a stasis pod.</span>")

				//Despawning occurs when process() is called with an occupant without a client.
				add_fingerprint(M)

/obj/machinery/cryopod/proc/preserve_item(obj/item/O)
	O.loc = src

	var/preserve = FALSE
	for(var/T in preserve_items)
		if(istype(O, T))
			preserve = TRUE
			break

	if (preserve && storage)
		frozen_items += O
	else
		if (O.contents.len)
			for (var/obj/item/object in O.contents)
				preserve_item(object)
		qdel(O)

/obj/machinery/cryopod/update_icon()
	if(occupant)
		icon_state = "cryosleeper_[orient_right ? "right" : "left"]_cl"
	else
		icon_state = "cryosleeper_[orient_right ? "right" : "left"]"

/obj/machinery/cryopod/open_machine()
	occupant = null
	dropContents()
	update_icon()

/obj/machinery/cryopod/proc/insert(mob/M)
	M.forceMove(src, keep_grabs = FALSE)
	to_chat(M, "<span class='notice'>You feel cool air surround you. You go numb as your senses turn inward.</span>")
	to_chat(M, "<span class='notice'><b>If you ghost, log out or close your client now, your character will shortly be permanently removed from the round.</b></span>")
	occupant = M
	time_entered = world.time
	set_med_status("*SSD*")
	update_icon()

/obj/machinery/cryopod/proc/set_med_status(mes)
	for(var/datum/data/record/R in data_core.general)
		if(R.fields["name"] == occupant.real_name)
			R.fields["p_stat"] = mes
			PDA_Manifest.Cut()
			break

/obj/machinery/cryopod/AltClick(mob/user)
	. = ..()
	if(occupant)
		eject()
	else
		enter_pod(user)

/obj/machinery/cryopod/relaymove(mob/user)
	..()
	go_out()

/obj/machinery/cryopod/MouseDrop_T(mob/target, mob/user)
	. = ..()
	if(user == target)
		enter_pod(user)

/obj/machinery/cryopod/verb/eject()
	set name = "Eject Pod"
	set category = "Object"
	set src in oview(1)
	if(usr.incapacitated() || !occupant)
		return

	if(usr != occupant && \
		  !occupant.client && \
		  occupant.stat != DEAD && \
		  occupant.health > config.health_threshold_softcrit && \
		  !allowed(usr))
		to_chat(usr, "<span class='red'>You can't eject person from [src], since the preservation procedure has already begun</span>")
		return
	go_out()
	add_fingerprint(usr)


/obj/machinery/cryopod/verb/move_inside()
	set name = "Enter Pod"
	set category = "Object"
	set src in oview(1)
	enter_pod(usr)

/obj/machinery/cryopod/proc/enter_pod(mob/user)
	if(user.incapacitated() || !(ishuman(user)))
		return

	if(!Adjacent(user))
		return

	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='notice'>You have no idea how to do that.</span>")
		return

	if(occupant)
		to_chat(user, "<span class='notice'><B>The cryo pod is in use.</B></span>")
		return

	for(var/mob/living/carbon/slime/M in range(1, user))
		if(M.Victim == user)
			to_chat(user, "You're too busy getting your life sucked out of you.")
			return
	if(user.is_busy())
		return
	visible_message("[user] starts climbing into the cryo pod.", 3)
	if(do_after(usr, 20, target = src))
		if(occupant)
			to_chat(user, "<span class='notice'><B>The cryo pod is in use.</B></span>")
			return
		insert(user)
		add_fingerprint(user)

/obj/machinery/cryopod/proc/go_out()
	set_med_status("Active")
	open_machine()

//Attacks/effects.
/obj/machinery/cryopod/blob_act()
	return //Sorta gamey, but we don't really want these to be destroyed.
