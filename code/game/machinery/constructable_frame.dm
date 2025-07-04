/obj/machinery/constructable_frame //Made into a seperate type to make future revisions easier.
	name = "machine frame"
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "box_0"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	var/obj/item/weapon/circuitboard/circuit = null
	var/list/components = null
	var/list/req_components = null
	var/list/req_component_names = null // user-friendly names of components
	var/state = 1

// unfortunately, we have to instance the objects really quickly to get the names
// fortunately, this is only called once when the board is added and the items are immediately GC'd
// and none of the parts do much in their constructors
/obj/machinery/constructable_frame/proc/update_namelist()
	if(!req_components)
		return

	req_component_names = new()
	for(var/tname in req_components)
		var/path = tname
		var/obj/O = new path()
		req_component_names[tname] = O.name

/obj/machinery/constructable_frame/proc/get_req_components_amt()
	var/amt = 0
	for(var/path in req_components)
		amt += req_components[path]
	return amt

// update description of required components remaining
/obj/machinery/constructable_frame/proc/update_req_desc()
	if(!req_components || !req_component_names)
		return

	var/hasContent = 0
	desc = "Requires"
	for(var/i = 1 to req_components.len)
		var/tname = req_components[i]
		var/amt = req_components[tname]
		if(amt == 0)
			continue
		var/use_and = i == req_components.len
		desc += "[(hasContent ? (use_and ? ", and" : ",") : "")] [amt] [amt == 1 ? req_component_names[tname] : "[req_component_names[tname]]\s"]"
		hasContent = 1

	if(!hasContent)
		desc = "Does not require any more components."
	else
		desc += "."

/obj/machinery/constructable_frame/deconstruct(disassembled)
	if(flags & NODECONSTRUCT)
		return ..()
	new /obj/item/stack/sheet/metal(loc, 5)
	if(circuit)
		circuit.forceMove(loc)
		circuit = null
	if(state >= 2)
		new /obj/item/stack/cable_coil(loc , 5)
	for(var/obj/item/I in components)
		I.forceMove(loc)
	LAZYCLEARLIST(components)
	..()

/obj/machinery/constructable_frame/machine_frame/attackby(obj/item/P, mob/user)
	if(P.crit_fail)
		to_chat(user, "<span class='danger'>This part is faulty, you cannot add this to the machine!</span>")
		return
	switch(state)
		if(1)
			if(istype(P, /obj/item/weapon/circuitboard))
				to_chat(user, "<span class='warning'>The frame needs wiring first!</span>")
				return

			else if(iscoil(P))
				var/obj/item/stack/cable_coil/C = P
				if(C.get_amount() < 5)
					to_chat(user, "<span class='warning'>You need five length of cable to wire the frame!</span>")
					return
				if(user.is_busy(src))
					return
				to_chat(user, "<span class='notice'>You start to add cables to the frame.</span>")
				if(P.use_tool(src, user, SKILL_TASK_EASY, target = src, volume = 50, required_skills_override = list(/datum/skill/construction = SKILL_LEVEL_PRO)))
					if(state == 1)
						if(!C.use(5))
							return

						to_chat(user, "<span class='notice'>You add cables to the frame.</span>")
						state = 2
						icon_state = "box_1"

			else if(isscrewing(P) && !anchored)
				if(user.is_busy(src))
					return
				user.visible_message("<span class='warning'>[user] disassembles the frame.</span>", \
									"<span class='notice'>You start to disassemble the frame...</span>", "You hear banging and clanking.")
				if(P.use_tool(src, user, SKILL_TASK_AVERAGE, volume = 50))
					if(state == 1)
						to_chat(user, "<span class='notice'>You disassemble the frame.</span>")
						deconstruct(TRUE)

			else if(iswrenching(P))
				if(user.is_busy())
					return
				to_chat(user, "<span class='notice'>You start [anchored ? "un" : ""]securing [name]...</span>")
				if(P.use_tool(src, user, SKILL_TASK_AVERAGE, volume = 75))
					if(state == 1)
						to_chat(user, "<span class='notice'>You [anchored ? "un" : ""]secure [name].</span>")
						anchored = !anchored
		if(2)
			if(iswrenching(P))
				if(user.is_busy())
					return
				to_chat(user, "<span class='notice'>You start [anchored ? "un" : ""]securing [name]...</span>")
				if(P.use_tool(src, user, SKILL_TASK_AVERAGE, volume = 75))
					to_chat(user, "<span class='notice'>You [anchored ? "un" : ""]secure [name].</span>")
					anchored = !anchored

			if(istype(P, /obj/item/weapon/circuitboard))
				if(!anchored)
					to_chat(user, "<span class='warning'>The frame needs to be secured first!</span>")
					return
				var/obj/item/weapon/circuitboard/B = P
				if(B.board_type == "machine")
					if(!user.drop_from_inventory(P, src))
						return
					playsound(src, 'sound/items/Deconstruct.ogg', VOL_EFFECTS_MASTER)
					to_chat(user, "<span class='notice'>You add the circuit board to the frame.</span>")
					circuit = P
					icon_state = "box_2"
					state = 3
					components = list()
					req_components = circuit.req_components.Copy()
					update_namelist()
					update_req_desc()
				else
					to_chat(user, "<span class='warning'>This frame does not accept circuit boards of this type!</span>")
			if(iscutter(P))
				playsound(src, 'sound/items/Wirecutter.ogg', VOL_EFFECTS_MASTER)
				to_chat(user, "<span class='notice'>You remove the cables.</span>")
				state = 1
				icon_state = "box_0"
				new /obj/item/stack/cable_coil/red(loc, 5)

		if(3)
			if(isprying(P))
				playsound(src, 'sound/items/Crowbar.ogg', VOL_EFFECTS_MASTER)
				state = 2
				circuit.loc = src.loc
				components.Remove(circuit)
				circuit = null
				if(components.len == 0)
					to_chat(user, "<span class='notice'>You remove the circuit board.</span>")
				else
					to_chat(user, "<span class='notice'>You remove the circuit board and other components.</span>")
					for(var/obj/item/weapon/W in components)
						W.loc = src.loc
				desc = initial(desc)
				req_components = null
				components = null
				icon_state = "box_1"

			if(isscrewing(P))
				var/component_check = 1
				for(var/R in req_components)
					if(req_components[R] > 0)
						component_check = 0
						break
				if(component_check)
					if(!handle_fumbling(user, src, SKILL_TASK_AVERAGE, list(/datum/skill/construction = SKILL_LEVEL_PRO), "<span class='notice'>You fumble around, figuring out how to construct machine.</span>"))
						return
					playsound(src, 'sound/items/Screwdriver.ogg', VOL_EFFECTS_MASTER)
					var/obj/machinery/new_machine = new circuit.build_path(src.loc)
					transfer_fingerprints_to(new_machine)
					new_machine.construction()
					for(var/obj/O in new_machine.component_parts)
						qdel(O)
					new_machine.component_parts = list()
					for(var/obj/O in src)
						O.loc = null
						new_machine.component_parts += O
					circuit.loc = null
					new_machine.RefreshParts()
					qdel(src)

			if(istype(P, /obj/item/weapon/storage/part_replacer) && P.contents.len && get_req_components_amt())
				var/obj/item/weapon/storage/part_replacer/replacer = P
				var/list/added_components = list()
				var/list/part_list = list()

				//Assemble a list of current parts, then sort them by their rating!
				for(var/obj/item/weapon/stock_parts/co in replacer)
					if(!co.crit_fail)
						part_list += co
				//Sort the parts. This ensures that higher tier items are applied first.
				part_list = sortTim(part_list, GLOBAL_PROC_REF(cmp_rped_sort))

				for(var/path in req_components)
					while(req_components[path] > 0 && (locate(path) in part_list))
						var/obj/item/part = (locate(path) in part_list)
						added_components[part] = path
						replacer.remove_from_storage(part, src)
						req_components[path]--
						part_list -= part

				for(var/obj/item/weapon/stock_parts/part in added_components)
					components += part
					to_chat(user, "<span class='notice'>[part.name] applied.</span>")
				replacer.play_rped_sound()

				update_req_desc()
				return

			if(isitem(P) && get_req_components_amt())
				for(var/I in req_components)
					if(istype(P, I) && (req_components[I] > 0))
						if(iscoil(P))
							var/obj/item/stack/cable_coil/CP = P
							if(CP.use(1))
								var/obj/item/stack/cable_coil/CC = new(src, 1, CP.color)
								components += CC
								req_components[I]--
								update_req_desc()
							else
								to_chat(user, "<span class='warning'>You need more cable!</span>")
							return
						if(!user.drop_from_inventory(P, src))
							break
						components += P
						req_components[I]--
						update_req_desc()
						return 1
				to_chat(user, "<span class='warning'>You cannot add that to the machine!</span>")
				return 0


//Machine Frame Circuit Boards
/*Common Parts: Parts List: Ignitor, Timer, Infra-red laser, Infra-red sensor, t_scanner, Capacitor, Valve, sensor unit,
micro-manipulator, console screen, beaker, Microlaser, matter bin, power cells.
Note: Once everything is added to the public areas, will add m_amt and g_amt to circuit boards since autolathe won't be able
to destroy them and players will be able to make replacements.
*/

/obj/item/weapon/circuitboard/vendor
	name = "circuit board (Booze-O-Mat Vendor)"
	build_path = /obj/machinery/vending/boozeomat
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/vending_refill/boozeomat = 3)

/obj/item/weapon/circuitboard/vendor/attackby(obj/item/I, mob/user, params)
	if(isscrewing(I))
		var/static/list/names_of_vendings = list()
		var/static/list/radial_icons = list()

		if(names_of_vendings.len == 0)
			for(var/obj/machinery/vending/type as anything in typesof(/obj/machinery/vending))
				if(!initial(type.refill_canister))
					continue
				var/full_name
				if(initial(type.subname))
					full_name = "[initial(type.name)] ([initial(type.subname)])"
				else
					full_name = initial(type.name)

				ASSERT(!names_of_vendings[full_name])

				names_of_vendings[full_name] = type
				radial_icons[full_name] = icon(initial(type.icon), initial(type.icon_state))

		var/vending_name = show_radial_menu(user, src, radial_icons, require_near = TRUE, tooltips = TRUE)
		if(isnull(vending_name))
			return

		var/obj/machinery/vending/vending_type = names_of_vendings[vending_name]

		to_chat(user, "<span class='notice'>You set the board to [vending_name].</span>")

		name = "circuit board ([vending_name] Vendor)"
		build_path = vending_type
		req_components = list(initial(vending_type.refill_canister) = 3)
		return
	return ..()

/obj/item/weapon/circuitboard/smes
	details = "circuit board (SMES)"
	build_path = /obj/machinery/power/smes
	board_type = "machine"
	origin_tech = "programming=4;powerstorage=5;engineering=5"
	req_components = list(
							/obj/item/stack/cable_coil = 5,
							/obj/item/weapon/stock_parts/cell = 5,
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/emitter
	details = "circuit board (Emitter)"
	build_path = /obj/machinery/power/emitter
	board_type = "machine"
	origin_tech = "programming=4;powerstorage=5;engineering=5"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/power_compressor
	details = "circuit board (Power Compressor)"
	build_path = /obj/machinery/compressor
	board_type = "machine"
	origin_tech = "programming=4;powerstorage=5;engineering=4"
	req_components = list(
							/obj/item/stack/cable_coil = 5,
							/obj/item/weapon/stock_parts/manipulator = 6)

/obj/item/weapon/circuitboard/power_turbine
	details = "circuit board (Power Turbine)"
	build_path = /obj/machinery/power/turbine
	board_type = "machine"
	origin_tech = "programming=4;powerstorage=4;engineering=5"
	req_components = list(
							/obj/item/stack/cable_coil = 5,
							/obj/item/weapon/stock_parts/capacitor = 6)

/obj/item/weapon/circuitboard/mech_recharger
	details = "circuit board (Mechbay Recharger)"
	build_path = /obj/machinery/mech_bay_recharge_port
	board_type = "machine"
	origin_tech = "programming=3;powerstorage=4;engineering=4"
	req_components = list(
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/capacitor = 5)

/obj/item/weapon/circuitboard/teleporter_hub
	details = "circuit board (Teleporter Hub)"
	build_path = /obj/machinery/teleport/hub
	board_type = "machine"
	origin_tech = "programming=3;engineering=5;bluespace=5;materials=4"
	req_components = list(
							/obj/item/bluespace_crystal = 3,
							/obj/item/weapon/stock_parts/matter_bin = 1)

/obj/item/weapon/circuitboard/teleporter_station
	details = "circuit board (Teleporter Station)"
	build_path = /obj/machinery/teleport/station
	board_type = "machine"
	origin_tech = "programming=4;engineering=4;bluespace=4"
	req_components = list(
							/obj/item/bluespace_crystal = 2,
							/obj/item/weapon/stock_parts/capacitor = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/telesci_pad
	details = "circuit board (Telepad)"
	build_path = /obj/machinery/telepad
	board_type = "machine"
	origin_tech = "programming=4;engineering=3;materials=3;bluespace=4"
	req_components = list(
							/obj/item/bluespace_crystal = 2,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/sleeper
	details = "circuit board (Sleeper)"
	build_path = /obj/machinery/sleeper
	board_type = "machine"
	origin_tech = "programming=3;biotech=2;engineering=3;materials=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 2)
/obj/item/weapon/circuitboard/cryo_tube
	details = "circuit board (Cryotube)"
	build_path = /obj/machinery/atmospherics/components/unary/cryo_cell
	board_type = "machine"
	origin_tech = "programming=4;biotech=3;engineering=4"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 4)

/obj/item/weapon/circuitboard/heater
	details = "circuit board (Heater)"
	build_path = /obj/machinery/atmospherics/components/unary/thermomachine/heater
	board_type = "machine"
	origin_tech = "powerstorage=2;engineering=1)"
	req_components = list(
							/obj/item/stack/cable_coil = 5,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/capacitor = 2)


/obj/item/weapon/circuitboard/reagentgrinder
	details = "circuit board (All-In-One Grinder)"
	board_type = "machine"
	build_path = /obj/machinery/reagentgrinder
	origin_tech = "biotech=2;engineering=1;materials=2"
	req_components = list(
		/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/cooler
	details = "circuit board (Cooler)"
	build_path = /obj/machinery/atmospherics/components/unary/thermomachine/freezer
	board_type = "machine"
	origin_tech = "magnets=2;engineering=2"
	req_components = list(
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/capacitor = 2,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/space_heater
	details = "circuit board (Space Heater)"
	build_path = /obj/machinery/space_heater
	board_type = "machine"
	origin_tech = "programming=2;engineering=2"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/stack/cable_coil = 3)

/obj/item/weapon/circuitboard/color_mixer
	details = "circuit board (Color Mixer)"
	build_path = /obj/machinery/color_mixer
	origin_tech = "programming=2;materials=2"
	board_type = "machine"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/stack/cable_coil = 1)


/obj/item/weapon/circuitboard/biogenerator
	details = "circuit board (Biogenerator)"
	build_path = /obj/machinery/biogenerator
	board_type = "machine"
	origin_tech = "programming=3;biotech=2;materials=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/hydroponics
	details = "circuit board (Hydroponics Tray)"
	build_path = /obj/machinery/hydroponics/constructable
	board_type = "machine"
	origin_tech = "programming=1;biotech=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/deepfryer
	details = "circuit board (Deep Fryer)"
	build_path = /obj/machinery/deepfryer
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/microwave
	details = "circuit board (Microwave)"
	build_path = /obj/machinery/kitchen_machine/microwave
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/oven
	details = "circuit board (Oven)"
	build_path = /obj/machinery/kitchen_machine/oven
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/grill
	details = "circuit board (Grill)"
	build_path = /obj/machinery/kitchen_machine/grill
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/candymaker
	details = "circuit board (Candy)"
	build_path = /obj/machinery/kitchen_machine/candymaker
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/gibber
	details = "circuit board (Gibber)"
	build_path = /obj/machinery/gibber
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/processor
	details = "circuit board (Food processor)"
	build_path = /obj/machinery/processor
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

//obj/item/weapon/circuitboard/recycler
//	details = "circuit board (Recycler)"
//	build_path = /obj/machinery/recycler
//	board_type = "machine"
//	origin_tech = "programming=1"
//	req_components = list(
//							/obj/item/weapon/stock_parts/matter_bin = 1,
//							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/seed_extractor
	details = "circuit board (Seed Extractor)"
	build_path = /obj/machinery/seed_extractor
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/smartfridge
	details = "circuit board (Smartfridge)"
	build_path = /obj/machinery/smartfridge
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1)

/obj/item/weapon/circuitboard/smartfridge/attackby(obj/item/I, mob/user, params)
	if(isscrewing(I))
		var/static/list/names_of_smartfridges
		var/static/list/radial_icons

		if (!names_of_smartfridges || !radial_icons)
			names_of_smartfridges = list()
			radial_icons = list()

			var/available_designs = list(
				/obj/machinery/smartfridge/seeds,
				/obj/machinery/smartfridge/chemistry,
				/obj/machinery/smartfridge/secure/extract,
				/obj/machinery/smartfridge/secure/virology,
				/obj/machinery/smartfridge/drinks,
				/obj/machinery/smartfridge) // Food

			for(var/obj/machinery/smartfridge/type as anything in available_designs)
				var/full_name = initial(type.name)
				names_of_smartfridges[full_name] = type
				// Icon stuff
				var/atom/fridge_icon = image(initial(type.icon), initial(type.icon_state))
				fridge_icon.add_overlay(icon(initial(type.icon), initial(type.content_overlay)))
				fridge_icon.add_overlay(icon(initial(type.icon), "smartfridge-glass"))
				radial_icons[full_name] = fridge_icon

		var/smartfridge_name = show_radial_menu(user, src, radial_icons, require_near = TRUE, tooltips = TRUE)
		if(isnull(smartfridge_name))
			return

		var/obj/machinery/smartfridge_type = names_of_smartfridges[smartfridge_name]
		to_chat(user, "<span class='notice'>You set the board to [smartfridge_name].</span>")
		details = "circuit board ([smartfridge_name])"
		build_path = smartfridge_type

		return
	return ..()

/obj/item/weapon/circuitboard/smartfridge/secure/bluespace
	details = "circuit board (Bluespace Storage)"
	build_path = /obj/machinery/smartfridge/secure/bluespace
	board_type = "machine"
	origin_tech = "programming=4;engineering=4;bluespace=4"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin/adv/super/bluespace = 3,
							/obj/item/weapon/stock_parts/capacitor/adv/super/quadratic = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/monkey_recycler
	details = "circuit board (Monkey Recycler)"
	build_path = /obj/machinery/monkey_recycler
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/holopad
	details = "circuit board (AI Holopad)"
	build_path = /obj/machinery/hologram/holopad
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/chem_dispenser
	details = "circuit board (Portable Chem Dispenser)"
	build_path = /obj/machinery/chem_dispenser/constructable
	board_type = "machine"
	origin_tech = "materials=4;engineering=4;programming=4;phorontech=3;biotech=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/cell = 1)

/obj/item/weapon/circuitboard/chem_master
	details = "circuit board (Chem Master 2999)"
	build_path = /obj/machinery/chem_master/constructable
	board_type = "machine"
	origin_tech = "materials=2;programming=2;biotech=1"
	req_components = list(
							/obj/item/weapon/reagent_containers/glass/beaker = 2,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/destructive_analyzer
	details = "circuit board (Destructive Analyzer)"
	build_path = /obj/machinery/r_n_d/destructive_analyzer
	board_type = "machine"
	origin_tech = "magnets=2;engineering=2;programming=2"
	req_components = list(
							/obj/item/weapon/stock_parts/scanning_module = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/micro_laser = 1)

/obj/item/weapon/circuitboard/autolathe
	details = "circuit board (Autolathe)"
	build_path = /obj/machinery/autolathe
	board_type = "machine"
	origin_tech = "engineering=2;programming=2"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 3,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/protolathe
	details = "circuit board (Protolathe)"
	build_path = /obj/machinery/r_n_d/protolathe
	board_type = "machine"
	origin_tech = "engineering=2;programming=2"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/weapon/reagent_containers/glass/beaker = 2)


/obj/item/weapon/circuitboard/circuit_imprinter
	details = "circuit board (Circuit Imprinter)"
	build_path = /obj/machinery/r_n_d/circuit_imprinter
	board_type = "machine"
	origin_tech = "engineering=2;programming=2"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/reagent_containers/glass/beaker = 2)

/obj/item/weapon/circuitboard/pacman
	details = "circuit board (PACMAN-type Generator)"
	build_path = /obj/machinery/power/port_gen/pacman
	board_type = "machine"
	origin_tech = "programming=3:powerstorage=3;phorontech=3;engineering=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/pacman/super
	details = "circuit board (SUPERPACMAN-type Generator)"
	build_path = /obj/machinery/power/port_gen/pacman/super
	origin_tech = "programming=3;powerstorage=4;engineering=4"

/obj/item/weapon/circuitboard/pacman/mrs
	details = "circuit board (MRSPACMAN-type Generator)"
	build_path = /obj/machinery/power/port_gen/pacman/mrs
	origin_tech = "programming=3;powerstorage=5;engineering=5"

/obj/item/weapon/circuitboard/pacman/money
	details = "circuit board (ANCAPMAN-type Generator)"
	build_path = /obj/machinery/power/port_gen/pacman/money
	origin_tech = "programming=3;powerstorage=5;engineering=5"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/weapon/storage/wallet = 1)

/obj/item/weapon/circuitboard/rdserver
	details = "circuit board (R&D Server)"
	build_path = /obj/machinery/r_n_d/server
	board_type = "machine"
	origin_tech = "programming=3"
	req_components = list(
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/scanning_module = 1)

/obj/item/weapon/circuitboard/mechfab
	details = "circuit board (Exosuit Fabricator)"
	build_path = /obj/machinery/mecha_part_fabricator
	board_type = "machine"
	origin_tech = "programming=3;engineering=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/minefab
	details = "circuit board (Mining Fabricator)"
	build_path = /obj/machinery/mecha_part_fabricator/mining_fabricator
	board_type = "machine"
	origin_tech = "powerstorage=3;programming=3;engineering=4;magnets=4;materials=4"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)


/obj/item/weapon/circuitboard/clonepod
	details = "circuit board (Clone Pod)"
	build_path = /obj/machinery/clonepod
	board_type = "machine"
	origin_tech = "programming=3;biotech=3"
	req_components = list(
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/scanning_module = 2,
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/clonescanner
	details = "circuit board (Cloning Scanner)"
	build_path = /obj/machinery/dna_scannernew
	board_type = "machine"
	origin_tech = "programming=2;biotech=2"
	req_components = list(
							/obj/item/weapon/stock_parts/scanning_module = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/stack/cable_coil = 2)

/obj/item/weapon/circuitboard/cyborgrecharger
	details = "circuit board (Cyborg Recharger)"
	build_path = /obj/machinery/recharge_station
	board_type = "machine"
	origin_tech = "powerstorage=3;engineering=3"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 2,
							/obj/item/weapon/stock_parts/cell = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/recharger
	details = "circuit board (Weapon Recharger)"
	build_path = /obj/machinery/recharger
	board_type = "machine"
	origin_tech = "powerstorage=3;engineering=3;materials=4"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 1,)
/obj/item/weapon/circuitboard/cell_recharger
	details = "circuit board (Cell Recharger)"
	build_path = /obj/machinery/cell_charger
	board_type = "machine"
	origin_tech = "powerstorage=1;engineering=2;materials=1"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 1,)

// Telecomms circuit boards:
/obj/item/weapon/circuitboard/telecomms/receiver
	details = "circuit board (Subspace Receiver)"
	build_path = /obj/machinery/telecomms/receiver
	board_type = "machine"
	origin_tech = "programming=4;engineering=3;bluespace=2"
	req_components = list(
							/obj/item/weapon/stock_parts/subspace/ansible = 1,
							/obj/item/weapon/stock_parts/subspace/filter = 1,
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/weapon/stock_parts/micro_laser = 1)

/obj/item/weapon/circuitboard/telecomms/hub
	details = "circuit board (Hub Mainframe)"
	build_path = /obj/machinery/telecomms/hub
	board_type = "machine"
	origin_tech = "programming=4;engineering=4"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/subspace/filter = 2)

/obj/item/weapon/circuitboard/telecomms/relay
	details = "circuit board (Relay Mainframe)"
	build_path = /obj/machinery/telecomms/relay
	board_type = "machine"
	origin_tech = "programming=3;engineering=4;bluespace=3"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/subspace/filter = 2)

/obj/item/weapon/circuitboard/telecomms/bus
	details = "circuit board (Bus Mainframe)"
	build_path = /obj/machinery/telecomms/bus
	board_type = "machine"
	origin_tech = "programming=4;engineering=4"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/subspace/filter = 1)

/obj/item/weapon/circuitboard/tesla_coil
	details = "circuit board (Tesla Coil)"
	build_path = /obj/machinery/power/tesla_coil
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/grounding_rod
	details = "circuit board (Grounding Rod)"
	build_path = /obj/machinery/power/grounding_rod
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/telecomms/processor
	details = "circuit board (Processor Unit)"
	build_path = /obj/machinery/telecomms/processor
	board_type = "machine"
	origin_tech = "programming=4;engineering=4"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 3,
							/obj/item/weapon/stock_parts/subspace/filter = 1,
							/obj/item/weapon/stock_parts/subspace/treatment = 2,
							/obj/item/weapon/stock_parts/subspace/analyzer = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/subspace/amplifier = 1)

/obj/item/weapon/circuitboard/telecomms/server
	details = "circuit board (Telecommunication Server)"
	build_path = /obj/machinery/telecomms/server
	board_type = "machine"
	origin_tech = "programming=4;engineering=4"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/subspace/filter = 1)

/obj/item/weapon/circuitboard/telecomms/broadcaster
	details = "circuit board (Subspace Broadcaster)"
	build_path = /obj/machinery/telecomms/broadcaster
	board_type = "machine"
	origin_tech = "programming=4;engineering=4;bluespace=2"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/subspace/filter = 1,
							/obj/item/weapon/stock_parts/subspace/crystal = 1,
							/obj/item/weapon/stock_parts/micro_laser/high = 2)

/obj/item/weapon/circuitboard/ore_redemption
	details = "circuit board (Ore Redemption)"
	build_path = /obj/machinery/mineral/ore_redemption
	board_type = "machine"
	origin_tech = "programming=1;engineering=2"
	req_components = list(
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/device/assembly/igniter = 1)

/obj/item/weapon/circuitboard/mining_equipment_vendor
	details = "circuit board (Mining Equipment Vendor)"
	build_path = /obj/machinery/mineral/equipment_vendor
	board_type = "machine"
	origin_tech = "programming=1;engineering=2"
	req_components = list(
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/matter_bin = 3)

/obj/item/weapon/circuitboard/circulator
	details = "circuit board (TEG circulator)"
	build_path = /obj/machinery/atmospherics/components/binary/circulator
	board_type = "machine"
	origin_tech = "engineering=3"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 3,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 5)

/obj/item/weapon/circuitboard/teg
	details = "circuit board (TEG generator)"
	build_path = /obj/machinery/power/generator
	board_type = "machine"
	origin_tech = "engineering=3"
	req_components = list(
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/capacitor = 3,
							/obj/item/stack/cable_coil = 5)

/obj/item/weapon/circuitboard/operating_table
	details = "circuit board (Operating Table)"
	build_path = /obj/machinery/optable
	board_type = "machine"
	origin_tech = "engineering=3"
	req_components = list(
							/obj/item/weapon/stock_parts/scanning_module = 2,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/stack/cable_coil = 2)

/obj/item/weapon/circuitboard/operating_table/abductor
	details = "circuit board (Abductor Operating Table)"
	build_path = /obj/machinery/optable/abductor
	board_type = "machine"
	origin_tech = "engineering=3"
	req_components = list(
							/obj/item/weapon/stock_parts/scanning_module/adv/phasic/triphasic = 2,
							/obj/item/weapon/stock_parts/capacitor/adv/super/quadratic = 1,
							/obj/item/stack/cable_coil = 2)
