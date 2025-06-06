#define FEEDER_DISTANT 7
//goat
/mob/living/simple_animal/hostile/retaliate/goat
	name = "goat"
	desc = "Не славятся своим дружелюбием."
	icon_state = "goat"
	icon_living = "goat"
	icon_dead = "goat_dead"
	speak = list("БЕЕЕЕЕЕЕ","Бее?")
	speak_emote = list("блеет")
	emote_hear = list("блеет")
	emote_see = list("осматривается", "топает копытцем")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat = 4)
	response_help  = "pets the"
	response_disarm = "gently pushes aside the"
	response_harm   = "kick"
	faction = "goat"
	attacktext = "kicks"
	health = 40
	melee_damage = 3
	var/datum/reagents/udder = null
	footstep_type = FOOTSTEP_MOB_SHOE

	has_head = TRUE
	has_leg = TRUE

/mob/living/simple_animal/hostile/retaliate/goat/atom_init()
	udder = new(50)
	udder.my_atom = src
	. = ..()

/mob/living/simple_animal/hostile/retaliate/goat/Destroy()
	QDEL_NULL(udder)
	return ..()

/mob/living/simple_animal/hostile/retaliate/goat/Life()
	. = ..()
	if(.)
		//chance to go crazy and start wacking stuff
		if(!enemies.len && prob(1))
			Retaliate()

		if(enemies.len && prob(10))
			enemies = list()
			LoseTarget()
			visible_message("<span class='notice'>[src] calms down.</span>")

		if(stat == CONSCIOUS)
			if(udder && prob(5))
				udder.add_reagent("milk", rand(5, 10))

		if(locate(/obj/structure/spacevine) in loc)
			var/obj/structure/spacevine/SV = locate(/obj/structure/spacevine) in loc
			qdel(SV)
			if(prob(10))
				say("Ном")

		if(!pulledby)
			for(var/direction in shuffle(list(1,2,4,8,5,6,9,10)))
				var/step = get_step(src, direction)
				if(step)
					if(locate(/obj/structure/spacevine) in step)
						Move(step)

/mob/living/simple_animal/hostile/retaliate/goat/Retaliate()
	..()
	visible_message("<span class='warning'>[src] gets an evil-looking gleam in their eye.</span>")

/mob/living/simple_animal/hostile/retaliate/goat/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0)
	. = ..()
	if(stat == CONSCIOUS && !ISDIAGONALDIR(Dir))
		if(locate(/obj/structure/spacevine) in loc)
			var/obj/structure/spacevine/SV = locate(/obj/structure/spacevine) in loc
			qdel(SV)
			if(prob(10))
				say("Nom")

/mob/living/simple_animal/hostile/retaliate/goat/attackby(obj/item/O, mob/user)
	if(stat == CONSCIOUS && istype(O, /obj/item/weapon/reagent_containers/glass))
		user.SetNextMove(CLICK_CD_INTERACT)
		user.visible_message("<span class='notice'>[user] milks [src] using \the [O].</span>")
		var/obj/item/weapon/reagent_containers/glass/G = O
		var/transfered = udder.trans_id_to(G, "milk", rand(5,10))
		if(G.reagents.total_volume >= G.volume)
			to_chat(user, "<span class='warning'>The [O] is full.</span>")
		if(!transfered)
			to_chat(user, "<span class='warning'>Вымя пустое. Нужно немного подождать...</span>")
	else
		..()

//cow
/mob/living/simple_animal/cow
	name = "cow"
	desc = "Известны своим молоком. Только не валите их на спину."
	icon_state = "cow"
	icon_living = "cow"
	icon_dead = "cow_dead"
	icon_gib = "cow_gib"
	speak = list("Муу?","Муу","МУУУУУУУ")
	speak_emote = list("мычит")
	emote_hear = list("мычит")
	emote_see = list("качает головой", "что-то жуёт", "осматривается")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	w_class = SIZE_MASSIVE
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat/slab = 6)
	health = 50

	has_head = TRUE
	has_leg = TRUE

	var/datum/reagents/udder = null

/mob/living/simple_animal/cow/atom_init()
	udder = new(50)
	udder.my_atom = src
	. = ..()

/mob/living/simple_animal/cow/Destroy()
	QDEL_NULL(udder)
	return ..()

/mob/living/simple_animal/cow/attackby(obj/item/O, mob/user)
	if(stat == CONSCIOUS && istype(O, /obj/item/weapon/reagent_containers/glass))
		user.SetNextMove(CLICK_CD_INTERACT)
		user.visible_message("<span class='notice'>[user] milks [src] using \the [O].</span>")
		var/obj/item/weapon/reagent_containers/glass/G = O
		var/transfered = udder.trans_id_to(G, "milk", rand(5,10))
		if(G.reagents.total_volume >= G.volume)
			to_chat(user, "<span class='warning'>The [O] is full.</span>")
		if(!transfered)
			to_chat(user, "<span class='warning'>Вымя пустое. Нужно немного подождать...</span>")
	else
		..()

/mob/living/simple_animal/cow/Life()
	. = ..()
	if(stat == CONSCIOUS)
		if(udder && prob(5))
			udder.add_reagent("milk", rand(5, 10))
		else if(prob(15))
			playsound(src, 'sound/voice/cow_moo.ogg', VOL_EFFECTS_MASTER, null, TRUE, null, -3)

/mob/living/simple_animal/cow/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0)
	. = ..()
	if(. && prob(55) && !ISDIAGONALDIR(Dir))
		playsound(src, 'sound/misc/cowbell.ogg', VOL_EFFECTS_MASTER, null, FALSE, null, -3)

/mob/living/simple_animal/chick
	name = "chick"
	desc = "Очаровательное создание! Хотя оно поднимает такой шум..."
	icon_state = "chick"
	icon_living = "chick"
	icon_dead = "chick_dead"
	icon_gib = "chick_gib"
	speak = list("Пии.","Пии?","Пи-пии.","Пиии!")
	speak_emote = list("пищит")
	emote_hear = list("пищит")
	emote_see = list("клюёт пол","машет маленькими крылышками")
	speak_chance = 2
	turns_per_move = 2
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat = 1)
	health = 1
	var/amount_grown = 0
	pass_flags = PASSTABLE | PASSGRILLE
	w_class = SIZE_TINY

	has_head = TRUE
	has_leg = TRUE

/mob/living/simple_animal/chick/atom_init()
	. = ..()
	pixel_x = rand(-6, 6)
	pixel_y = rand(0, 10)

/mob/living/simple_animal/chick/Life()
	. = ..()
	if(!.)
		return
	if(stat == CONSCIOUS)
		amount_grown += rand(1,2)
		if(amount_grown >= 100)
			new /mob/living/simple_animal/chicken(src.loc)
			qdel(src)

var/global/const/MAX_CHICKENS = 50
var/global/chicken_count = 0

/mob/living/simple_animal/chicken
	name = "chicken"
	desc = "Надеюсь, в этом сезоне яйца будут вкусными..."
	icon_state = "chicken"
	icon_living = "chicken"
	icon_dead = "chicken_dead"
	icon_move = "chicken_move"
	speak = list("Ко-ко!","КО! КО! КО!","Куд-кудах!")
	speak_emote = list("кудахчет")
	emote_hear = list("кудахчет")
	emote_see = list("клюёт пол","машет крыльями")
	speak_chance = 2
	turns_per_move = 3
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat = 2)
	health = 10
	maxHealth = 10
	var/eggsleft = 0
	var/body_color
	pass_flags = PASSTABLE
	w_class = SIZE_MINUSCULE

	has_head = TRUE
	has_leg = TRUE

/mob/living/simple_animal/chicken/atom_init()
	. = ..()
	if(!body_color)
		body_color = pick(list("brown", "black", "white"))
	icon_state = "chicken_[body_color]"
	icon_living = "chicken_[body_color]"
	icon_dead = "chicken_[body_color]_dead"
	icon_move = "chicken_[body_color]_move"
	pixel_x = rand(-6, 6)
	pixel_y = rand(0, 10)
	chicken_count += 1

/mob/living/simple_animal/chicken/death()
	..()
	chicken_count -= 1

/mob/living/simple_animal/chicken/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/weapon/reagent_containers/food/snacks/grown/wheat)) //feedin' dem chickens
		user.SetNextMove(CLICK_CD_INTERACT)
		if(stat == CONSCIOUS && eggsleft < 8)
			user.visible_message("<span class='notice'>[user] feeds [O] to [name]! It clucks happily.</span>","<span class='notice'>You feed [O] to [name]! It clucks happily.</span>")
			qdel(O)
			eggsleft += rand(1, 4)
			//world << eggsleft
		else
			to_chat(user, "<span class='notice'>[name] doesn't seem hungry!</span>")
	else
		..()

/mob/living/simple_animal/chicken/Life()
	. =..()
	if(!.)
		return
	if(stat == CONSCIOUS && prob(3) && eggsleft > 0)
		visible_message("[src] [pick("откладывает яйца.","поднимает шумиху.","начинает хрипло кудахтать.")]")
		playsound(src, 'sound/voice/chiken_egg.ogg', VOL_EFFECTS_MASTER)
		eggsleft--
		var/obj/item/weapon/reagent_containers/food/snacks/egg/E = new(get_turf(src))
		E.pixel_x = rand(-6,6)
		E.pixel_y = rand(-6,6)
		if(chicken_count < MAX_CHICKENS && prob(10))
			START_PROCESSING(SSobj, E)
	if(stat != DEAD || stat != CONSCIOUS && !buckled)
		if(eggsleft < 2) //hungry
			for(var/obj/structure/chicken_feeder/C as anything in chicken_feeder_list)
				if(get_dist(src, C) < FEEDER_DISTANT && C.z == z)
					if(C.food > 0)
						stop_automated_movement = TRUE
						step_to(src, C)
						if(loc == C.loc)
							C.feed(src)
							stop_automated_movement = FALSE
	if(prob(15))
		playsound(src, 'sound/voice/chiken_cluck.ogg', VOL_EFFECTS_MASTER, vary = TRUE, extrarange = -3)

/obj/item/weapon/reagent_containers/food/snacks/egg/var/amount_grown = 0
/obj/item/weapon/reagent_containers/food/snacks/egg/process()
	if(isturf(loc))
		amount_grown += rand(1,2)
		if(amount_grown >= 100)
			visible_message("[src] hatches with a quiet cracking sound.")
			new /mob/living/simple_animal/chick(get_turf(src))
			STOP_PROCESSING(SSobj, src)
			qdel(src)
	else
		STOP_PROCESSING(SSobj, src)

/mob/living/simple_animal/pig
	name = "pig"
	desc = "Хрю-хрю."
	icon_state = "pig"
	icon_living = "pig"
	icon_dead = "pig_dead"
	speak = list("Хрю?","Хрю","ХРЮ!", "Хрю-хрю")
	speak_emote = list("хрюкает")
	emote_see = list("катается по полу", "что-то жуёт")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	w_class = SIZE_BIG
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat/ham = 6)
	health = 50

	has_head = TRUE
	has_leg = TRUE

/mob/living/simple_animal/pig/shadowpig
	name = "Shadowpig"
	desc = "Хрю-хрю..?"
	icon_state = "shadowpig"
	icon_living = "shadowpig"
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE

/mob/living/simple_animal/pig/shadowpig/atom_init()
	. = ..()
	AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/veil)
	AddSpell(new /obj/effect/proc_holder/spell/targeted/blindness_smoke)

/mob/living/simple_animal/turkey
	name = "turkey"
	desc = "Как курица, только индейская. "
	icon_state = "turkey"
	icon_living = "turkey"
	icon_dead = "turkey_dead"
	speak = list("Курлык?","Курлык","КУРЛЫК")
	speak_emote = list("курлычет")
	emote_see = list("осматривается")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat = 4)
	health = 50

	has_head = TRUE
	has_leg = TRUE

/mob/living/simple_animal/goose
	name = "goose"
	desc = "Я гусь, никого не боюсь."
	icon_state = "goose"
	icon_living = "goose"
	icon_dead = "goose_dead"
	speak = list("Га?","Га","ГА!")
	speak_emote = list("гогочет")
	emote_see = list("машет крыльями")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat = 6)
	health = 50

	has_head = TRUE
	has_leg = TRUE

/mob/living/simple_animal/seal
	name = "seal"
	desc = "Красивый белый тюлень."
	icon_state = "seal"
	icon_living = "seal"
	icon_dead = "seal_dead"
	speak = list("Урь?","Урь","УРЬ")
	speak_emote = list("урчит")
	emote_see = list("шлёпает по животу")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat = 6)
	health = 50

	has_head = TRUE
	has_arm = TRUE

/mob/living/simple_animal/walrus
	name = "walrus"
	desc = "Большой коричневый морж."
	icon_state = "walrus"
	icon_living = "walrus"
	icon_dead = "walrus_dead"
	speak = list("Урь?","Урь","УРЬ")
	speak_emote = list("урчит")
	emote_see = list("шлёпает по животу")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat = 6)
	health = 50

	has_head = TRUE
	has_arm = TRUE

/mob/living/simple_animal/walrus/syndicate
	name = "Surlaw"
	icon_state = "walrus-syndi"
	icon_living = "walrus-syndi"
	icon_dead = "walrus-syndi_dead"
	speak = list("Урь?","Урь","УРЬ","Урьыть НТ")
	health = 80

#undef FEEDER_DISTANT
