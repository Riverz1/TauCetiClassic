#define DESIRABLE_TWOHAND "For comfortable shooting, it is necessary that the inactive hand is free"
#define ONLY_TWOHAND "To fire this weapon, the inactive hand MUST be free"
//Please do not increase power in shake_camera(). It is really not needed for players.
#define OPTIMAL_POWER_RECOIL 1
#define DEFAULT_DURATION_RECOIL 1

/obj/item/weapon/gun
	name = "gun"
	desc = "It's a gun. It's pretty terrible, though."
	icon = 'icons/obj/gun.dmi'
	icon_state = "detective"
	item_state = "gun"
	flags =  CONDUCT
	slot_flags = SLOT_FLAGS_BELT
	m_amt = 2000
	w_class = SIZE_SMALL
	throwforce = 5
	throw_speed = 4
	hitsound = list('sound/weapons/genhit1.ogg')
	throw_range = 5
	force = 5.0
	origin_tech = "combat=1"
	attack_verb = list("struck", "hit", "bashed")
	item_action_types = list(/datum/action/item_action/hands_free/switch_gun)
	can_be_holstered = TRUE
	var/obj/item/ammo_casing/chambered = null
	var/fire_sound = 'sound/weapons/guns/Gunshot.ogg'
	var/silenced = 0
	var/recoil = 0
	var/clumsy_check = 1
	var/can_suicide_with = TRUE
	var/tmp/list/mob/living/target //List of who yer targeting.
	var/tmp/lock_time = -100
	var/automatic = 0 //Used to determine if you can target multiple people.
	var/tmp/mob/living/last_moved_mob //Used to fire faster at more than one person.
	var/tmp/told_cant_shoot = 0 //So that it doesn't spam them with the fact they cannot hit them.
	var/firerate = 0 	//0 for keep shooting until aim is lowered
						// 1 for one bullet after tarrget moves and aim is lowered
	var/fire_delay = 6
	var/last_fired = 0
	var/two_hand_weapon = FALSE
	var/burst = 1 //burst size
	var/burst_delay = 1 //cooldown between burst shots
	var/spread_increase = 0 // per shot
	var/spread_max = 0
	var/spread = 0

	lefthand_file = 'icons/mob/inhands/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/guns_righthand.dmi'

/datum/action/item_action/hands_free/switch_gun
	name = "Switch Gun"

/obj/item/weapon/gun/process()
	if(spread == 0)
		STOP_PROCESSING(SSfastprocess, src)
	else
		spread = clamp(spread - 0.1, 0, spread_max)

/obj/item/weapon/gun/examine(mob/user)
	..()
	if(two_hand_weapon)
		to_chat(user, "<span class='warning'>[two_hand_weapon].</span>")

/obj/item/weapon/gun/proc/ready_to_fire()
	if(world.time >= last_fired + fire_delay)
		last_fired = world.time
		return TRUE
	else
		return FALSE

/obj/item/weapon/gun/proc/process_chamber()
	return FALSE

/obj/item/weapon/gun/proc/special_check(mob/M, atom/target) //Placeholder for any special checks, like detective's revolver. or wizards
	if(iswizard(M))
		return FALSE
	if(two_hand_weapon == ONLY_TWOHAND)
		if(M.get_inactive_hand())
			to_chat(M, "<span class='notice'>Your other hand must be free before firing! This weapon requires both hands to use.</span>")
			return FALSE
	return TRUE

/obj/item/weapon/gun/proc/shoot_with_empty_chamber(mob/living/user)
	to_chat(user, "<span class='warning'>*click*</span>")
	playsound(user, 'sound/weapons/guns/empty.ogg', VOL_EFFECTS_MASTER)
	return

/obj/item/weapon/gun/proc/shoot_live_shot(mob/living/user)
	if(recoil > 0)
		var/skill_recoil_duration = max(DEFAULT_DURATION_RECOIL, apply_skill_bonus(user, recoil, list(/datum/skill/firearms = SKILL_LEVEL_TRAINED), multiplier = -0.5))
		if(two_hand_weapon != DESIRABLE_TWOHAND)
			shake_camera(user, skill_recoil_duration, OPTIMAL_POWER_RECOIL)
			if(spread_increase)
				spread = clamp(spread + spread_increase, 0, spread_max)
				START_PROCESSING(SSfastprocess, src)
		if(two_hand_weapon == DESIRABLE_TWOHAND)
			//No OPTIMAL_POWER_RECOIL only for increasing user's motivation to drop other hand
			if(user.get_inactive_hand())
				shake_camera(user, recoil + 2, recoil + 1)
				if(spread_increase)
					spread = clamp(spread + spread_increase + 1, 0, spread_max)
					START_PROCESSING(SSfastprocess, src)
			else
				shake_camera(user, skill_recoil_duration, OPTIMAL_POWER_RECOIL)
				if(spread_increase)
					spread = clamp(spread + spread_increase, 0, spread_max)
					START_PROCESSING(SSfastprocess, src)

	if(silenced)
		playsound(user, fire_sound, VOL_EFFECTS_MASTER, 30, FALSE, null, -4)
	else
		playsound(user, fire_sound, VOL_EFFECTS_MASTER)
		announce_shot(user)

/obj/item/weapon/gun/proc/announce_shot(mob/living/user)
	user.visible_message("<span class='danger'>[user] fires [src]!</span>", "<span class='danger'>You fire [src]!</span>", "You hear a gunshot!")

/obj/item/weapon/gun/emp_act(severity)
	for(var/obj/O in contents)
		O.emplode(severity)

/obj/item/weapon/gun/Destroy()
	qdel(chambered)
	chambered = null
	return ..()

/obj/item/weapon/gun/afterattack(atom/target, mob/user, proximity, params)
	if(proximity)	return //It's adjacent, is the user, or is on the user's person
	if(istype(target, /obj/machinery/recharger) && istype(src, /obj/item/weapon/gun/energy))	return//Shouldnt flag take care of this?
	if(user && user.client && user.client.gun_mode && !(target in src.target))
		PreFire(target,user,params) //They're using the new gun system, locate what they're aiming at.
	else
		Fire(target,user,params) //Otherwise, fire normally.

/mob/living/carbon/AltClickOn(atom/A)
	if(next_move > world.time) // CD for clicks is checked before clicks with modifiers(shift, alt)
		return
	var/obj/item/I = get_active_hand()
	if(istype(I, /obj/item/weapon/gun))
		var/obj/item/weapon/gun/G = I
		if(client.gun_mode)
			if(G.can_fire())
				G.Fire(A, src)
		else
			if(isliving(A))
				var/mob/living/M = A
				if(M in G.target)
					M.NotTargeted(G)
				else
					G.PreFire(M, src)
				return
	..()

/obj/item/weapon/gun/proc/Fire(atom/target, mob/living/user, params, reflex = 0, point_blank = FALSE)//TODO: go over this
	//Exclude lasertag guns from the CLUMSY check.
	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='red'>You don't have the dexterity to do this!</span>")
		return
	if(isliving(user))
		var/mob/living/M = user
		if (HULK in M.mutations)
			to_chat(M, "<span class='red'>Your meaty finger is much too large for the trigger guard!</span>")
			return
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.species.name == SHADOWLING || H.species.name == ABOMINATION)
				to_chat(H, "<span class='notice'>Your fingers don't fit in the trigger guard!</span>")
				return

			if(user.get_species() == GOLEM)
				to_chat(user, "<span class='red'>Your metal fingers don't fit in the trigger guard!</span>")
				return
			if(H.wear_suit && istype(H.wear_suit, /obj/item/clothing/suit))
				var/obj/item/clothing/suit/V = H.wear_suit
				V.attack_reaction(H, REACTION_GUN_FIRE)

			if(clumsy_check) //it should be AFTER hulk or monkey check.
				var/going_to_explode = 0
				if(H.ClumsyProbabilityCheck(50))
					going_to_explode = 1
				if(chambered && chambered.crit_fail && !user.mood_prob(90))
					going_to_explode = 1
				if(going_to_explode)
					explosion(user.loc, 0, 0, 1, 1)
					to_chat(H, "<span class='danger'>[src] blows up in your face.</span>")
					H.take_bodypart_damage(0, 20)
					qdel(src)
					return

	add_fingerprint(user)

	if(!special_check(user, target))
		return

	if (!ready_to_fire())
		return

	user.next_click = world.time + (burst - 1) * burst_delay
	for(var/i in 1 to burst)
		if(chambered)
			if(point_blank)
				if(!chambered.BB.fake)
					user.visible_message("<span class='red'><b> \The [user] fires \the [src] point blank at [target]!</b></span>")
				chambered.BB.damage *= 1.3
			if(!chambered.fire(src, target, user, params, , silenced))
				shoot_with_empty_chamber(user)
				break
			else
				shoot_live_shot(user)
				user.newtonian_move(get_dir(target, user))
		else
			shoot_with_empty_chamber(user)
			break
		sleep(burst_delay)
		process_chamber()
		update_icon()
		update_inv_mob()

/obj/item/weapon/gun/proc/can_fire()
	return

/obj/item/weapon/gun/proc/can_hit(mob/living/target, mob/living/user)
	return chambered.BB.check_fire(target,user)

/obj/item/weapon/gun/proc/click_empty(mob/user = null)
	if (user)
		user.visible_message("*click click*", "<span class='red'><b>*click*</b></span>")
		playsound(user, 'sound/weapons/guns/empty.ogg', VOL_EFFECTS_MASTER)
	else
		visible_message("*click click*")
		playsound(src, 'sound/weapons/guns/empty.ogg', VOL_EFFECTS_MASTER)

/obj/item/weapon/gun/attack(mob/living/M, mob/living/user, def_zone)
	//Suicide handling.
	if (M == user && def_zone == O_MOUTH)
		if(user.is_busy())
			return
		if(!can_suicide_with)
			to_chat(user, "<span class='notice'>You have tried to commit suicide, but couldn't do it with [src].</span>")
			return
		if(isrobot(user))
			to_chat(user, "<span class='notice'>You have tried to commit suicide, but couldn't do it.</span>")
			return
		M.visible_message("<span class='warning'>[user] sticks their gun in their mouth, ready to pull the trigger...</span>")
		if(!use_tool(user, user, 40))
			M.visible_message("<span class='notice'>[user] decided life was worth living.</span>")
			return
		if (can_fire())
			user.visible_message("<span class = 'warning'>[user] pulls the trigger.</span>")
			if(silenced)
				playsound(user, fire_sound, VOL_EFFECTS_MASTER, 10)
			else
				playsound(user, fire_sound, VOL_EFFECTS_MASTER)
			if(istype(chambered.BB, /obj/item/projectile/beam/lasertag) || istype(chambered.BB, /obj/item/projectile/beam/practice))
				user.visible_message("<span class = 'notice'>Nothing happens.</span>",\
									"<span class = 'notice'>You feel rather silly, trying to commit suicide with a toy.</span>")
				return
			if(istype(chambered.BB, /obj/item/projectile/bullet/chameleon))
				user.visible_message("<span class = 'notice'>Nothing happens.</span>",\
									"<span class = 'notice'>You feel weakness and the taste of gunpowder, but no more.</span>")
				user.Stun(5)
				user.apply_effect(5,WEAKEN,0)
				return

			chambered.BB.on_hit(M, O_MOUTH, 0)
			if(chambered.BB.damage_type == HALLOSS)
				to_chat(user, "<span class = 'notice'>Ow...</span>")
				user.apply_effect(110,AGONY,0)
			else if(!chambered.BB.nodamage)
				if(ishuman(user))
					SEND_SIGNAL(user, COMSIG_HUMAN_ON_SUICIDE, src)
				user.apply_damage(chambered.BB.damage * 2.5, chambered.BB.damage_type, BP_HEAD, null, chambered.BB.damage_flags(), "Point blank shot in the mouth with \a [chambered.BB]")
				user.death()
			chambered.BB = null
			chambered.update_icon()
			update_icon()
			process_chamber()
			return
		else
			click_empty(user)
			return

	if (can_fire())
		//Point blank shooting if on harm intent or target we were targeting.
		if(user.a_intent == INTENT_HARM)
			Fire(M, user, null, null, TRUE)
			return
		else if(target && (M in target))
			Fire(M,user) ///Otherwise, shoot!
			return
	else
		return ..()

#undef OPTIMAL_POWER_RECOIL
#undef DEFAULT_DURATION_RECOIL
