/datum/advclass/wretch/onimusha
	name = "Onimusha"
	tutorial = "You are a fiend of the Kazengunese mountains, a warrior who has cast aside their humenity and seeks to emulate the beasts of Graggar and Dendor."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/wretch/onimusha
	maximum_possible_slots = 1
	category_tags = list(CTAG_WRETCH)
	cmode_music = 'sound/music/combat_berserker.ogg'
	traits_applied = list(TRAIT_STRONGBITE, TRAIT_CRITICAL_RESISTANCE, TRAIT_NOPAINSTUN)
	subclass_stats = list(
		STATKEY_STR = 4, //9 weighted stats, compared to Berserker's 8, but their highest weapon skill is Journeyman.
		STATKEY_CON = 3,
		STATKEY_WIL = 2,
		STATKEY_INT = -2,
		STATKEY_FOR = -2
	)

	subclass_skills = list(
		/datum/skill/combat/maces = SKILL_LEVEL_JOURNEYMAN, //All weapon skills are Journeyman here for a reason. Don't touch them.
		/datum/skill/combat/axes = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/wrestling = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/unarmed = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/swimming = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/climbing = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/sneaking = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/tracking = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/medicine = SKILL_LEVEL_NOVICE,
		/datum/skill/craft/tanning = SKILL_LEVEL_APPRENTICE,
		/datum/skill/craft/cooking = SKILL_LEVEL_NOVICE,
		/datum/skill/labor/butchering = SKILL_LEVEL_NOVICE,
	)

/datum/outfit/job/roguetown/wretch/onimusha/pre_equip(mob/living/carbon/human/H)
	H.set_patron(/datum/patron/inhumen/graggar)
	head = /obj/item/clothing/head/roguetown/helmet/sallet/beastskull
	mask = /obj/item/clothing/mask/rogue/facemask/steel/kazengun/full
	cloak = /obj/item/clothing/cloak/darkcloak/minotaur
	wrists = /obj/item/clothing/wrists/roguetown/bracers
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather/reinforced
	gloves = /obj/item/clothing/gloves/roguetown/plate
	backr = /obj/item/storage/backpack/rogue/satchel
	belt = /obj/item/storage/belt/rogue/leather/battleskirt/faulds
	neck = /obj/item/clothing/neck/roguetown/leather
	armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat
	r_hand = /obj/item/rogueweapon/mace/goden/steel/tetsubo //Big boy.
	backpack_contents = list(
		/obj/item/rogueweapon/huntingknife = 1,
		/obj/item/flashlight/flare/torch/lantern/prelit = 1,
		/obj/item/storage/belt/rogue/pouch/coins/poor = 1,
		/obj/item/rope/chain = 1,
		/obj/item/rogueweapon/scabbard/sheath = 1,
	)
	wretch_select_bounty(H)

//studded hood and shit brought to you by vide noir
//it requires sewing to make the padded hood and blacksmithing to make studded hood, like studded armor.
//this is an upgrade to leather helmet cause it's more bothersome and (there is literally no reason to have leather helmets cause there is no weight class for them anyway.)
//but this atleast hides your identity and looks cool, have more crit resist types.
/obj/item/clothing/head/roguetown/roguehood/reinforced/newmoon/armorhood
	name = "padded leather hood"
	desc = "A padded leather hood with buckles."
	icon = 'modular_stonehedge/icons/clothing/armor/head.dmi'
	mob_overlay_icon = 'modular_stonehedge/icons/clothing/armor/onmob/head.dmi'
	icon_state = "studhood"
	item_state = "studhood"
	color = null
	flags_inv =	HIDEHAIR|HIDEEARS|HIDEFACE
	slot_flags = ITEM_SLOT_NECK|ITEM_SLOT_HEAD
	body_parts_covered = HEAD|EARS|HAIR|NOSE|EYES|NECK
	//Something between leather and metal helmet, worse than metal helmet by far.
	armor = list("blunt" = 70, "slash" = 65, "stab" = 60, "piercing" = 20, "fire" = 0, "acid" = 0)
	prevent_crits = list(BCLASS_CUT, BCLASS_BLUNT, BCLASS_TWIST)
	max_integrity = 240
	adjustable = CAN_CADJUST
	toggle_icon_state = TRUE

/obj/item/clothing/head/roguetown/roguehood/reinforced/newmoon/armorhood/ComponentInitialize()
	AddComponent(/datum/component/adjustable_clothing, NECK, null, null, null, null, (UPD_HEAD|UPD_MASK|UPD_NECK))

/obj/item/clothing/head/roguetown/roguehood/reinforced/newmoon/armorhood/advanced
	name = "studded leather hood"
	desc = "A thick studded leather hood with buckles."
	icon_state = "studhood" //make into new sprite
	item_state = "studhood"
	max_integrity = 280
	//closer to metal helmet but still quite behind, same blunt resist of hardened leather helmet though.
	armor = list("blunt" = 90, "slash" = 80, "stab" = 70, "piercing" = 20, "fire" = 0, "acid" = 0)
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_BLUNT, BCLASS_TWIST, BCLASS_CHOP, BCLASS_SMASH) //studded armor values with stab prot too

/datum/advclass/wretch/swordhunter
	name = "Sword Hunter"
	tutorial = "Hailing from Lingyue, yours is an unique art: You seek the swords of worthy foes and add them to your collection, all in worship of Matiosu."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS //TD?
	outfit = /datum/outfit/job/roguetown/wretch/swordhunter
	category_tags = list(CTAG_WRETCH)
	maximum_possible_slots = 1 //Very strong and also supposed to be unique, so one slot.
	cmode_music = 'sound/music/combat_swordhunter.ogg'

	subclass_languages = list(/datum/language/kazengunese)
	traits_applied = list(TRAIT_DODGEEXPERT)
	//Bad stats for a wretch, instead they get some really good traits and skills.
	subclass_stats = list(
		STATKEY_SPD = 2,
		STATKEY_INT = 1,
		STATKEY_STR = 1
	)

	subclass_skills = list(
		/datum/skill/combat/swords = SKILL_LEVEL_MASTER,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/knives = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/swimming = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/wrestling = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/reading = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/climbing = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/shields = SKILL_LEVEL_JOURNEYMAN //For if they want to use the scabbard to block, though I am not sure why you would do this.
	)

/datum/outfit/job/roguetown/wretch/swordhunter/pre_equip(mob/living/carbon/human/H)
	..()
	to_chat(H, span_warning("Hailing from Lingyue, yours is an unique art: You seek the swords of worthy foes and add them to your collection in worship of Matiosu."))
	H.set_patron(/datum/patron/inhumen/matthios)
	head = /obj/item/clothing/head/roguetown/roguehood/shalal/hijab/kazengunese
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants/eastpants2
	armor = /obj/item/clothing/suit/roguetown/armor/basiceast/crafteast/outlaw
	shirt = /obj/item/clothing/suit/roguetown/shirt/undershirt/eastshirt1
	backl = /obj/item/storage/backpack/rogue/satchel/short
	belt = /obj/item/storage/belt/rogue/leather/plaquesilver/outlaw
	gloves = /obj/item/clothing/gloves/roguetown/eastgloves1
	shoes = /obj/item/clothing/shoes/roguetown/armor/rumaclan
	neck = /obj/item/clothing/head/roguetown/roguehood/reinforced/newmoon/armorhood/advanced
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather/heavy
	mask = /obj/item/clothing/mask/rogue/facemask/steel/kazengun
	beltr = /obj/item/rogueweapon/huntingknife/idagger/steel/kazengun
	backpack_contents = list(
		/obj/item/storage/belt/rogue/pouch/coins/poor = 1,
		/obj/item/flashlight/flare/torch/lantern/prelit = 1,
		/obj/item/rope/chain = 1,
		/obj/item/reagent_containers/glass/bottle/alchemical/healthpot = 1,	//Small health vial
		)

	var/weapons = list("Rapier","Shashka", "Liuyedao", "Miaodao", "Shamshir", "Fechtfeders", "Kriegsmesser", "Zweihander", "Dual Gladius")
	var/weapon_choice = input("Pick your stolen steel.", "TAKE UP ARMS") as anything in weapons
	H.set_blindness(0)
	switch(weapon_choice) //A large selection of exotic starter options, as per the class gimmick.
		if("Rapier")
			beltl = /obj/item/rogueweapon/scabbard/sword
			l_hand = /obj/item/rogueweapon/sword/rapier
		if("Shashka")
			beltl = /obj/item/rogueweapon/scabbard/sword
			l_hand = /obj/item/rogueweapon/sword/sabre/steppesman 
		if ("Liuyedao")
			beltl = /obj/item/rogueweapon/scabbard/sword/kazengun
			l_hand = /obj/item/rogueweapon/sword/sabre/mulyeog
		if ("Miaodao")
			l_hand = /obj/item/rogueweapon/greatsword/miaodao
		if ("Shamshir")
			beltl = /obj/item/rogueweapon/scabbard/sword
			l_hand = /obj/item/rogueweapon/sword/sabre/shamshir
		if ("Fechtfeders")
			beltl = /obj/item/rogueweapon/scabbard/sword
			l_hand = /obj/item/rogueweapon/sword/long/frei
		if ("Kriegsmesser")
			beltl = /obj/item/rogueweapon/scabbard/sword
			l_hand = /obj/item/rogueweapon/sword/long/kriegmesser
		if ("Zweihander")
			l_hand = /obj/item/rogueweapon/greatsword/zwei
		if ("Dual Gladius")
			ADD_TRAIT(H, TRAIT_DUALWIELDER, TRAIT_GENERIC)
			beltl = /obj/item/rogueweapon/sword/short/gladius
			l_hand = /obj/item/rogueweapon/sword/short/gladius
	wretch_select_bounty(H)

/datum/advclass/wretch/sohei
	name = "Disgraced Custodian"
	tutorial = "Once, you proudly defended a quiet place of worship. Now, you've turned your back on faith and duty, living the lyfe of a would-be Kazengite warlord."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/wretch/sohei
	category_tags = list(CTAG_WRETCH)
	maximum_possible_slots = 1
	cmode_music = 'sound/music/combat_sohei.ogg'

	subclass_languages = list(/datum/language/kazengunese)
	traits_applied = list(TRAIT_NOPAINSTUN) //Inherits this from the Custodian adv, still light armor only.
	subclass_stats = list(
		STATKEY_WIL = 2,
		STATKEY_PER = 1,
		STATKEY_SPD = 2, 
		STATKEY_STR = 1,
	)

	subclass_skills = list(
		/datum/skill/combat/polearms = SKILL_LEVEL_MASTER, //Main draw of the class, Freelancer skill spread.
		/datum/skill/combat/unarmed = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/athletics = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/wrestling = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/swimming = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/reading = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/climbing = SKILL_LEVEL_JOURNEYMAN,
	)

/datum/outfit/job/roguetown/wretch/sohei/pre_equip(mob/living/carbon/human/H)
	..()
	to_chat(H, span_warning("Once, you proudly defended a quiet place of worship. Now, you've turned your back on faith and duty, living the lyfe of a would-be Kazengite warlord."))
	head = /obj/item/clothing/head/roguetown/mentorhat
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants/eastpants2
	shirt = /obj/item/clothing/suit/roguetown/armor/basiceast/crafteast/shrinekeeper
	backl = /obj/item/storage/backpack/rogue/satchel/short
	belt = /obj/item/storage/belt/rogue/leather/sash
	gloves = /obj/item/clothing/gloves/roguetown/eastgloves1
	shoes = /obj/item/clothing/shoes/roguetown/armor/rumaclan
	neck = /obj/item/clothing/neck/roguetown/chaincoif/full
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather/heavy
	mask = /obj/item/clothing/mask/rogue/facemask/steel/kazengun
	beltr = /obj/item/rogueweapon/huntingknife/idagger/steel/kazengun
	backpack_contents = list(	
		/obj/item/storage/belt/rogue/pouch/coins/poor = 1,
		/obj/item/flashlight/flare/torch/lantern/prelit = 1,
		/obj/item/rope/chain = 1,
		/obj/item/reagent_containers/glass/bottle/alchemical/healthpot = 1,
		)

	var/weapons = list("Naginata", "Quarterstaff", "Jumonji yari")
	var/weapon_choice = input("Choose your weapon.", "TAKE UP ARMS") as anything in weapons
	H.set_blindness(0)
	switch(weapon_choice)
		if("Naginata")
			l_hand = /obj/item/rogueweapon/spear/naginata
		if("Quarterstaff")
			l_hand = /obj/item/rogueweapon/woodstaff/quarterstaff/steel
		if("Jumonji yari")
			l_hand = /obj/item/rogueweapon/spear/boar/kazengun
	wretch_select_bounty(H)
