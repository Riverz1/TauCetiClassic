/mob/living/silicon/robot/updatehealth()
	health = maxHealth - (getBruteLoss() + getFireLoss())
	diag_hud_set_status()
	diag_hud_set_health()

/mob/living/silicon/robot/getBruteLoss()
	var/amount = 0
	for(var/V in components)
		var/datum/robot_component/C = components[V]
		if(C.installed != 0) amount += C.brute_damage
	return amount

/mob/living/silicon/robot/getFireLoss()
	var/amount = 0
	for(var/V in components)
		var/datum/robot_component/C = components[V]
		if(C.installed != 0) amount += C.electronics_damage
	return amount

/mob/living/silicon/robot/adjustBruteLoss(amount)
	if(amount > 0)
		return take_overall_damage(amount, 0)
	else
		return heal_overall_damage(-amount, 0)

/mob/living/silicon/robot/adjustFireLoss(amount)
	if(amount > 0)
		return take_overall_damage(0, amount)
	else
		return heal_overall_damage(0, -amount)

/mob/living/silicon/robot/proc/get_damaged_components(brute, burn, destroyed = 0)
	var/list/datum/robot_component/parts = list()
	for(var/V in components)
		var/datum/robot_component/C = components[V]
		if(C.installed == 1 || (C.installed == -1 && destroyed))
			if((brute && C.brute_damage) || (burn && C.electronics_damage) || (!C.toggled) || (!C.powered && C.toggled))
				parts += C
	return parts

/mob/living/silicon/robot/proc/get_damageable_components()
	var/list/rval = new
	for(var/V in components)
		var/datum/robot_component/C = components[V]
		if(C.installed == 1) rval += C
	return rval

/mob/living/silicon/robot/proc/get_armour()

	if(!components.len) return 0
	var/datum/robot_component/C = components["armour"]
	if(C && C.installed == 1)
		return C
	return 0

/mob/living/silicon/robot/heal_bodypart_damage(brute, burn)
	var/list/datum/robot_component/parts = get_damaged_components(brute,burn)
	if(!parts.len)	return
	var/datum/robot_component/picked = pick(parts)
	picked.heal_damage(brute,burn)

/mob/living/silicon/robot/take_bodypart_damage(brute = 0, burn = 0, sharp = 0, edge = 0)
	var/list/components = get_damageable_components()
	if(!components.len)
		return

	 //Combat shielding absorbs a percentage of damage directly into the cell.
	if(module_active && istype(module_active,/obj/item/borg/combat/shield))
		var/obj/item/borg/combat/shield/shield = module_active
		//Shields absorb a certain percentage of damage based on their power setting.
		var/absorb_brute = brute*shield.shield_level
		var/absorb_burn = burn*shield.shield_level
		var/cost = (absorb_brute+absorb_burn)*100

		cell.charge -= cost
		if(cell.charge <= 0)
			cell.charge = 0
			to_chat(src, "<span class='warning'>Your shield has overloaded!</span>")
		else
			brute -= absorb_brute
			burn -= absorb_burn
			to_chat(src, "<span class='warning'>Your shield absorbs some of the impact!</span>")

	var/datum/robot_component/armour/A = get_armour()
	if(A)
		A.take_damage(brute,burn,sharp,edge)
		return

	var/datum/robot_component/C = pick(components)
	C.take_damage(brute,burn,sharp,edge)

	updatehealth()

/mob/living/silicon/robot/heal_overall_damage(brute, burn)
	var/list/datum/robot_component/parts = get_damaged_components(brute,burn)

	while(parts.len && (brute>0 || burn>0) )
		var/datum/robot_component/picked = pick(parts)

		var/brute_was = picked.brute_damage
		var/burn_was = picked.electronics_damage

		picked.heal_damage(brute,burn)

		brute -= (brute_was-picked.brute_damage)
		burn -= (burn_was-picked.electronics_damage)

		parts -= picked

/mob/living/silicon/robot/take_overall_damage(brute = 0, burn = 0, sharp = 0, used_weapon = null)

	// todo: should we move it to robot_component?
	if(brute > 0)
		brute *= mob_brute_mod.Get()
	if(burn > 0)
		burn *= mob_burn_mod.Get()

	if(!brute && !burn)
		return FALSE

	var/list/datum/robot_component/parts = get_damageable_components()

	 //Combat shielding absorbs a percentage of damage directly into the cell.
	if(module_active && istype(module_active,/obj/item/borg/combat/shield))
		var/obj/item/borg/combat/shield/shield = module_active
		//Shields absorb a certain percentage of damage based on their power setting.
		var/absorb_brute = brute*shield.shield_level
		var/absorb_burn = burn*shield.shield_level
		var/cost = (absorb_brute+absorb_burn)*100

		cell.charge -= cost
		if(cell.charge <= 0)
			cell.charge = 0
			to_chat(src, "<span class='warning'>Your shield has overloaded!</span>")
		else
			brute -= absorb_brute
			burn -= absorb_burn
			to_chat(src, "<span class='warning'>Your shield absorbs some of the impact!</span>")

	var/datum/robot_component/armour/A = get_armour()
	if(A)
		A.take_damage(brute,burn,sharp)
		return

	while(parts.len && (brute>0 || burn>0) )
		var/datum/robot_component/picked = pick(parts)

		var/brute_was = picked.brute_damage
		var/burn_was = picked.electronics_damage

		picked.take_damage(brute,burn)

		brute	-= (picked.brute_damage - brute_was)
		burn	-= (picked.electronics_damage - burn_was)

		parts -= picked

	updatehealth()
