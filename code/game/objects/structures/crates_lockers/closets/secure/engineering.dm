/obj/structure/closet/secure_closet/engineering_chief
	name = "Chief Engineer's Locker"
	req_access = list(access_ce)
	icon_state = "securece"
	icon_closed = "securece"
	icon_opened = "securece_open"

/obj/structure/closet/secure_closet/engineering_chief/PopulateContents()
	if (prob(50))
		new /obj/item/weapon/storage/backpack/industrial(src)
	else
		new /obj/item/weapon/storage/backpack/satchel/eng(src)

	if (prob(70))
		new /obj/item/clothing/accessory/storage/brown_vest(src)
	else
		new /obj/item/clothing/accessory/storage/webbing(src)

	new /obj/item/blueprints(src)
	new /obj/item/device/remote_device/chief_engineer(src)
	new /obj/item/clothing/under/rank/chief_engineer(src)
	new /obj/item/clothing/head/hardhat/white(src)
	new /obj/item/clothing/head/welding(src)
	new /obj/item/clothing/gloves/insulated(src)
	new /obj/item/clothing/shoes/brown(src)
	new /obj/item/weapon/cartridge/ce(src)
	new /obj/item/device/radio/headset/heads/ce(src)
	new /obj/item/weapon/storage/toolbox/mechanical(src)
	new /obj/item/clothing/suit/storage/hazardvest(src)
	new /obj/item/clothing/mask/gas/coloured(src)
	new /obj/item/device/multitool(src)
	new /obj/item/device/flash(src)
	new /obj/item/taperoll/engineering(src)
	new /obj/item/weapon/storage/pouch/engineering_supply(src)
	new /obj/item/weapon/gun/energy/pyrometer/ce(src)
	new /obj/item/weapon/storage/pouch/medium_generic(src)
	new /obj/item/weapon/storage/pouch/engineering_tools(src)

/obj/structure/closet/secure_closet/engineering_electrical
	name = "Electrical Supplies"
	req_access = list(access_engine_equip)
	icon_state = "secureengelec"
	icon_closed = "secureengelec"
	icon_opened = "toolcloset_open"

/obj/structure/closet/secure_closet/engineering_electrical/PopulateContents()
	for (var/i in 1 to 2)
		new /obj/item/clothing/gloves/insulated(src)
	for (var/i in 1 to 3)
		new /obj/item/weapon/storage/toolbox/electrical(src)
	for (var/i in 1 to 3)
		new /obj/item/weapon/module/power_control(src)
	for (var/i in 1 to 3)
		new /obj/item/device/multitool(src)

	new /obj/item/weapon/storage/pouch/engineering_supply(src)

/obj/structure/closet/secure_closet/engineering_welding
	name = "Welding Supplies"
	req_access = list(access_construction)
	icon_state = "secureengweld"
	icon_closed = "secureengweld"
	icon_opened = "toolcloset_open"

/obj/structure/closet/secure_closet/engineering_welding/PopulateContents()
	for (var/i in 1 to 3)
		new /obj/item/clothing/head/welding(src)
	for (var/i in 1 to 3)
		new /obj/item/weapon/weldingtool/largetank(src)
	for (var/i in 1 to 3)
		new /obj/item/weapon/weldpack(src)

/obj/structure/closet/secure_closet/engineering_personal
	name = "Engineer's Locker"
	req_access = list(access_engine_equip)
	icon_state = "secureeng"
	icon_closed = "secureeng"
	icon_opened = "secureeng_open"

/obj/structure/closet/secure_closet/engineering_personal/PopulateContents()
	if (prob(50))
		new /obj/item/weapon/storage/backpack/industrial(src)
	else
		new /obj/item/weapon/storage/backpack/satchel/eng(src)

	if (prob(70))
		new /obj/item/clothing/accessory/storage/brown_vest(src)
	else
		new /obj/item/clothing/accessory/storage/webbing(src)

	new /obj/item/weapon/storage/toolbox/mechanical(src)
	new /obj/item/device/radio/headset/headset_eng(src)
	new /obj/item/clothing/suit/storage/hazardvest(src)
	new /obj/item/clothing/mask/gas/coloured(src)
	new /obj/item/clothing/glasses/meson(src)
	new /obj/item/weapon/cartridge/engineering(src)
	new /obj/item/taperoll/engineering(src)
	new /obj/item/weapon/gun/energy/pyrometer/engineering(src)
	if (prob(50))
		new /obj/item/weapon/storage/pouch/engineering_tools(src)

/obj/structure/closet/secure_closet/atmos_personal
	name = "Technician's Locker"
	req_access = list(access_atmospherics)
	icon_state = "secureatm"
	icon_closed = "secureatm"
	icon_opened = "secureatm_open"

/obj/structure/closet/secure_closet/atmos_personal/PopulateContents()
	if (prob(50))
		new /obj/item/weapon/storage/backpack/industrial(src)
	else
		new /obj/item/weapon/storage/backpack/satchel/eng(src)

	if (prob(70))
		new /obj/item/clothing/accessory/storage/brown_vest(src)
	else
		new /obj/item/clothing/accessory/storage/webbing(src)

	new /obj/item/clothing/suit/fire/firefighter(src)
	new /obj/item/device/flashlight(src)
	new /obj/item/weapon/reagent_containers/spray/extinguisher(src)
	new /obj/item/device/radio/headset/headset_eng(src)
	new /obj/item/clothing/suit/storage/hazardvest(src)
	new /obj/item/clothing/mask/gas/coloured(src)
	new /obj/item/weapon/cartridge/atmos(src)
	new /obj/item/taperoll/engineering(src)
	new /obj/item/weapon/gun/energy/pyrometer/atmospherics(src)
	if (prob(50))
		new /obj/item/weapon/storage/pouch/engineering_tools(src)
