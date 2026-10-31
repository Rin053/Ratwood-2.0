// Sumiari vision.
// Pitch black is full color. Bright light is a colorless ink wash. Very bright light adds a sun-glare haze.
// Reusable as /obj/item/organ/eyes/sumiari. Humen wear these by default until the Sumiari race exists.
// Revert the human default in code/modules/mob/living/carbon/human/species_types/roguetown/human/humen.dm.

// How long a move toward darkness (gaining color) takes.
#define SUMIARI_FADE_TO_COLOR (1 SECONDS)
// How long a move toward brightness (losing color) takes.
#define SUMIARI_FADE_TO_GRAY (0.5 SECONDS)
// How often a client re-reads the turf light and advances the fade. animate() fills the gaps.
#define SUMIARI_SAMPLE_INTERVAL (0.1 SECONDS)
// Ignore light changes smaller than this so torch quantization does not restart the fade.
#define SUMIARI_LIGHT_EPSILON 0.02

// Intensity where the last color is gone. 0 = pitch black (full color), this value = full ink wash.
#define SUMIARI_MONO_FULL 0.68
// Glare starts only after the wash is already colorless, and finishes at full brightness.
// Walking into shade clears the haze before any color comes back.
#define SUMIARI_GLARE_START 0.82
#define SUMIARI_GLARE_FULL 1.0
// Full-glare multiply on the ink image. Below 1 flattens contrast.
#define SUMIARI_GLARE_SLOPE 0.72
// Full-glare add. Lifts ink-black toward dark gray. Combined with the slope, paper-white blooms past 1.
#define SUMIARI_GLARE_BIAS 0.26

// Ink-wash contrast. 1 is flat grayscale. Higher crushes shadows and lifts highlights.
#define SUMIARI_INK_CONTRAST 1.55
// Luma value that stays put. Below the midpoint so shadows fall into ink and highlights reach paper.
#define SUMIARI_INK_PIVOT 0.36

// Same night-vision cutoff the eye toggle calls "invisible": the lighting plane is fully clear.
#define SUMIARI_LIGHTING_ALPHA LIGHTING_PLANE_ALPHA_INVISIBLE
// Covers the default 15x15 view (7 tiles from center). Does not see farther than a normal human's see_in_dark.
#define SUMIARI_SEE_IN_DARK 8
// Darkness-sneak raises invisibility to SEE_INVISIBLE_LIVING + skill*0.55 + 1 (about 29 at legendary).
// 35 sees that concealment and stays under SEE_INVISIBLE_OBSERVER (60), so ghosts stay hidden.
#define SUMIARI_SEE_INVISIBLE (SEE_INVISIBLE_LIVING + 10)

// Planes the player sees as the world. Masks, the lighting plane, and HUD/UI planes are absent on purpose.
GLOBAL_LIST_INIT(sumiari_vision_planes, list(
	"[FLOOR_PLANE]" = TRUE,
	"[WALL_PLANE]" = TRUE,
	"[GAME_PLANE_LOWER]" = TRUE,
	"[GAME_PLANE]" = TRUE,
	"[GAME_PLANE_FOV_HIDDEN]" = TRUE,
	"[GAME_PLANE_UPPER]" = TRUE,
	"[GAME_PLANE_HIGHEST]" = TRUE,
	"[OPENSPACE_PLANE]" = TRUE,
	"[OPENSPACE_BACKDROP_PLANE]" = TRUE,
	"[WEATHER_EFFECT_PLANE]" = TRUE,
	"[WEATHER_PLANE]" = TRUE,
	"[ABOVE_LIGHTING_PLANE]" = TRUE,
))

/obj/item/organ/eyes/sumiari
	name = "sumiari eyes"
	desc = "They drink the color out of lamplight and pour it back into the dark."
	see_in_dark = SUMIARI_SEE_IN_DARK
	see_invisible = SUMIARI_SEE_INVISIBLE
	lighting_alpha = SUMIARI_LIGHTING_ALPHA
	var/displayed_intensity
	var/target_intensity = 0
	var/fade_from = 0
	var/fade_started = 0
	var/fade_length = 0
	var/track_timer

/obj/item/organ/eyes/sumiari/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = FALSE, initialising)
	. = ..()
	// Parent treats lighting_alpha 0 as "unset" when TRAIT_NIGHT_VISION is present.
	lighting_alpha = SUMIARI_LIGHTING_ALPHA
	if(!owner)
		return
	owner.update_sight()
	RegisterSignal(owner, COMSIG_MOB_LOGIN, PROC_REF(on_owner_login))
	RegisterSignal(owner, COMSIG_MOB_LOGOUT, PROC_REF(on_owner_logout))
	if(owner.client)
		start_tracking()

/obj/item/organ/eyes/sumiari/Remove(mob/living/carbon/M, special = 0)
	stop_tracking()
	if(M)
		UnregisterSignal(M, list(COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT))
		clear_vision_filters(M)
		M.see_in_dark = initial(M.see_in_dark)
		M.see_invisible = initial(M.see_invisible)
		M.lighting_alpha = initial(M.lighting_alpha)
	return ..()

/obj/item/organ/eyes/sumiari/Destroy()
	stop_tracking()
	if(owner)
		clear_vision_filters(owner)
	return ..()

/obj/item/organ/eyes/sumiari/proc/on_owner_login(datum/source)
	SIGNAL_HANDLER
	start_tracking()

/obj/item/organ/eyes/sumiari/proc/on_owner_logout(datum/source)
	SIGNAL_HANDLER
	stop_tracking()

/obj/item/organ/eyes/sumiari/proc/start_tracking()
	if(!owner?.client)
		return
	refresh_vision(TRUE)
	if(track_timer)
		return
	track_timer = addtimer(CALLBACK(src, PROC_REF(tracking_tick)), SUMIARI_SAMPLE_INTERVAL, TIMER_STOPPABLE)

/obj/item/organ/eyes/sumiari/proc/stop_tracking()
	if(track_timer)
		deltimer(track_timer)
		track_timer = null

/obj/item/organ/eyes/sumiari/proc/tracking_tick()
	track_timer = null
	if(!owner?.client)
		return
	refresh_vision(FALSE)
	track_timer = addtimer(CALLBACK(src, PROC_REF(tracking_tick)), SUMIARI_SAMPLE_INTERVAL, TIMER_STOPPABLE)

/obj/item/organ/eyes/sumiari/proc/visual_intensity()
	if(isnull(displayed_intensity) || !fade_length)
		return displayed_intensity
	var/progress = CLAMP01((world.time - fade_started) / fade_length)
	return fade_from + (target_intensity - fade_from) * progress

/obj/item/organ/eyes/sumiari/proc/refresh_vision(immediate = FALSE)
	if(!owner)
		return
	var/raw = sumiari_turf_intensity(get_turf(owner))
	var/visual = visual_intensity()
	if(isnull(displayed_intensity) || immediate)
		displayed_intensity = raw
		target_intensity = raw
		fade_from = raw
		fade_started = world.time
		fade_length = 0
		paint_vision(0)
		return
	if(abs(raw - target_intensity) < SUMIARI_LIGHT_EPSILON && abs(raw - visual) < SUMIARI_LIGHT_EPSILON)
		displayed_intensity = raw
		target_intensity = raw
		fade_length = 0
		return
	if(abs(raw - target_intensity) >= SUMIARI_LIGHT_EPSILON)
		fade_from = visual
		target_intensity = raw
		fade_started = world.time
		fade_length = raw > visual ? SUMIARI_FADE_TO_GRAY : SUMIARI_FADE_TO_COLOR
	var/progress = fade_length ? CLAMP01((world.time - fade_started) / fade_length) : 1
	displayed_intensity = fade_from + (target_intensity - fade_from) * progress
	paint_vision(SUMIARI_SAMPLE_INTERVAL)

/obj/item/organ/eyes/sumiari/proc/paint_vision(fade_time)
	if(!owner?.hud_used)
		return
	var/list/matrix = sumiari_color_matrix(displayed_intensity)
	for(var/plane_key in GLOB.sumiari_vision_planes)
		var/atom/movable/screen/plane_master/plane = owner.hud_used.plane_masters[plane_key]
		if(!plane)
			continue
		paint_plane(plane, matrix, fade_time)

/obj/item/organ/eyes/sumiari/proc/paint_plane(atom/movable/screen/plane_master/plane, list/matrix, fade_time)
	if(!plane)
		return
	var/filter = plane.get_filter("sumiari_vision")
	if(sumiari_matrix_is_identity(displayed_intensity))
		if(filter)
			plane.remove_filter("sumiari_vision")
		return
	if(!filter)
		plane.add_filter("sumiari_vision", 20, color_matrix_filter(matrix))
		filter = plane.get_filter("sumiari_vision")
		if(!filter || fade_time <= 0)
			return
	if(fade_time <= 0)
		animate(filter, color = matrix, time = 0, flags = ANIMATION_END_NOW)
		return
	animate(filter, color = matrix, time = fade_time, easing = LINEAR_EASING, flags = ANIMATION_END_NOW)

/obj/item/organ/eyes/sumiari/proc/clear_vision_filters(mob/living/carbon/M)
	if(!M?.hud_used)
		return
	for(var/plane_key in GLOB.sumiari_vision_planes)
		var/atom/movable/screen/plane_master/plane = M.hud_used.plane_masters[plane_key]
		plane?.remove_filter("sumiari_vision")

/atom/movable/screen/plane_master/proc/apply_sumiari_sight(mob/mymob)
	if(!iscarbon(mymob))
		return
	if(!GLOB.sumiari_vision_planes["[plane]"])
		return
	var/mob/living/carbon/carbon = mymob
	var/obj/item/organ/eyes/sumiari/eyes = carbon.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes))
		remove_filter("sumiari_vision")
		return
	eyes.paint_plane(src, sumiari_color_matrix(eyes.displayed_intensity), 0)

// Strength of one light sample. Peak channel, so a red lamp matches a white lamp of the same power.
/proc/sumiari_channel_intensity(red, green, blue)
	return max(red, green, blue)

// Combined brightness at a turf. 0 is pitch black, 1 is full light. Color is ignored.
/proc/sumiari_turf_intensity(turf/T)
	if(!isturf(T))
		return 0
	if(!T.has_dynamic_lighting())
		return 1
	var/lamps = 0
	var/counted = 0
	if(T.corners)
		for(var/datum/lighting_corner/corner as anything in T.corners)
			if(!corner)
				continue
			lamps += sumiari_channel_intensity(corner.lum_r, corner.lum_g, corner.lum_b)
			counted++
	if(counted)
		lamps /= counted
	return CLAMP01(lamps + sumiari_sun_intensity(T) + T.dynamic_lumcount)

// Sunlight is not stored in the corner RGB sums. Coverage is 0-1; brightness is the sun color's peak channel.
/proc/sumiari_sun_intensity(turf/T)
	if(!T?.outdoor_effect)
		return 0
	var/cover = 0
	if(T.outdoor_effect.state != SKY_BLOCKED)
		cover = 1
	else if(T.corners)
		var/total = 0
		var/counted = 0
		for(var/datum/lighting_corner/corner as anything in T.corners)
			if(!corner)
				continue
			total += corner.sunFalloff
			counted++
		if(counted)
			cover = total / counted
	return cover * sumiari_sun_strength()

/proc/sumiari_sun_strength()
	if(!SSoutdoor_effects)
		return 0
	var/picked = SSoutdoor_effects.picked_color
	if(istext(picked) && length(picked) >= 7)
		return sumiari_hex_strength(picked)
	var/datum/time_of_day/step = SSoutdoor_effects.current_step_datum
	if(!step)
		return 0
	if(istext(step.color) && length(step.color) >= 7)
		return sumiari_hex_strength(step.color)
	if(islist(step.color) && length(step.color))
		return sumiari_hex_strength(step.color[1])
	return 0

/proc/sumiari_hex_strength(color)
	if(!istext(color) || length(color) < 7)
		return 0
	return max(GetRedPart(color), GetGreenPart(color), GetBluePart(color)) / 255

/proc/sumiari_saturation_at(intensity)
	if(isnull(intensity))
		intensity = 0
	intensity = CLAMP01(intensity)
	if(intensity >= SUMIARI_MONO_FULL)
		return 0
	return 1 - (intensity / SUMIARI_MONO_FULL)

/proc/sumiari_glare_at(intensity)
	if(isnull(intensity))
		intensity = 0
	intensity = CLAMP01(intensity)
	if(intensity <= SUMIARI_GLARE_START)
		return 0
	return CLAMP01((intensity - SUMIARI_GLARE_START) / (SUMIARI_GLARE_FULL - SUMIARI_GLARE_START))

/proc/sumiari_matrix_is_identity(intensity)
	return sumiari_saturation_at(intensity) >= 0.999 && sumiari_glare_at(intensity) <= 0.001

// Column-major 4x4 plus RGBA constants, matching color_matrix_identity().
/proc/sumiari_color_matrix(intensity)
	if(isnull(intensity))
		intensity = 0
	var/saturation = sumiari_saturation_at(intensity)
	var/glare = sumiari_glare_at(intensity)
	var/ink_add = SUMIARI_INK_PIVOT * (1 - SUMIARI_INK_CONTRAST)
	var/slope = 1 + glare * (SUMIARI_GLARE_SLOPE - 1)
	var/bias = glare * SUMIARI_GLARE_BIAS
	var/scale = slope * SUMIARI_INK_CONTRAST
	var/add = slope * ink_add + bias
	var/ink = 1 - saturation
	var/wr = ink * scale * LUMA_R
	var/wg = ink * scale * LUMA_G
	var/wb = ink * scale * LUMA_B
	var/constant = ink * add
	// Same column order as color_matrix_saturation(): each input channel, then alpha, then constants.
	return list(
		wr + saturation, wr, wr, 0,
		wg, wg + saturation, wg, 0,
		wb, wb, wb + saturation, 0,
		0, 0, 0, 1,
		constant, constant, constant, 0)

/proc/sumiari_apply_matrix(list/matrix, red, green, blue)
	return list(
		matrix[1] * red + matrix[5] * green + matrix[9] * blue + matrix[17],
		matrix[2] * red + matrix[6] * green + matrix[10] * blue + matrix[18],
		matrix[3] * red + matrix[7] * green + matrix[11] * blue + matrix[19])

/proc/sumiari_vision_report(mob/living/carbon/C)
	if(!istype(C))
		return "sumiari vision: no carbon"
	var/obj/item/organ/eyes/eyes = C.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes, /obj/item/organ/eyes/sumiari))
		return "sumiari vision: [C] has no sumiari eyes ([eyes?.type || "none"])"
	var/obj/item/organ/eyes/sumiari/sumiari = eyes
	var/raw = sumiari_turf_intensity(get_turf(C))
	var/shown = sumiari.displayed_intensity
	if(isnull(shown))
		shown = raw
	return "sumiari vision: mob=[C] client=[C.client ? "yes" : "no"] raw_intensity=[raw] shown_intensity=[shown] saturation=[sumiari_saturation_at(shown)] glare=[sumiari_glare_at(shown)] organ_see_in_dark=[sumiari.see_in_dark] organ_see_invisible=[sumiari.see_invisible] organ_lighting_alpha=[sumiari.lighting_alpha] mob_see_in_dark=[C.see_in_dark] mob_see_invisible=[C.see_invisible] mob_lighting_alpha=[C.lighting_alpha]"

var/global/sumiari_run_headless_test = FALSE

// DreamDaemon -params arrives as world/New's argument. world.params is not set yet, and the timer
// subsystem does not exist until the master controller finishes initializing (that proc does not wait).
/proc/sumiari_note_test_request(startup_params)
	if(islist(startup_params) && startup_params["sumiari_test"])
		sumiari_run_headless_test = TRUE
		return
	if(findtext("[startup_params]", "sumiari_test"))
		sumiari_run_headless_test = TRUE

/proc/sumiari_schedule_headless_test()
	if(islist(world.params))
		for(var/key in world.params)
			if(findtext("[key]=[world.params[key]]", "sumiari_test"))
				sumiari_run_headless_test = TRUE
				break
	else if(findtext("[world.params]", "sumiari_test"))
		sumiari_run_headless_test = TRUE
	if(!sumiari_run_headless_test)
		return
	// Called at the end of subsystem init, before the world sleeps with nobody logged in.
	// A timer would never fire in that sleep, so the check runs here.
	log_world("SUMIARI TEST scheduled")
	sumiari_headless_check()

/proc/sumiari_headless_check(attempt = 0)
	if((!SSlighting?.initialized || !SSatoms?.initialized) && attempt < 36)
		log_world("SUMIARI TEST waiting for init attempt=[attempt]")
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(sumiari_headless_check), attempt + 1), 5 SECONDS)
		return
	var/list/red_dark = sumiari_apply_matrix(sumiari_color_matrix(0), 1, 0, 0)
	var/list/red_noon = sumiari_apply_matrix(sumiari_color_matrix(1), 1, 0, 0)
	var/list/black_noon = sumiari_apply_matrix(sumiari_color_matrix(1), 0, 0, 0)
	var/list/white_noon = sumiari_apply_matrix(sumiari_color_matrix(1), 1, 1, 1)
	var/list/black_ink = sumiari_apply_matrix(sumiari_color_matrix(SUMIARI_MONO_FULL), 0, 0, 0)
	log_world("SUMIARI TEST matrix dark_red=[red_dark[1]],[red_dark[2]],[red_dark[3]] noon_red=[red_noon[1]],[red_noon[2]],[red_noon[3]] noon_black=[black_noon[1]] noon_white=[white_noon[1]] ink_black=[black_ink[1]]")
	log_world("SUMIARI TEST channels red=[sumiari_channel_intensity(1, 0, 0)] white=[sumiari_channel_intensity(1, 1, 1)]")
	if(abs(red_dark[1] - 1) > 0.02 || abs(red_dark[2]) > 0.02 || abs(red_dark[3]) > 0.02)
		log_world("SUMIARI TEST FAIL darkness did not stay in color")
	else if(abs(red_noon[1] - red_noon[2]) > 0.02 || abs(red_noon[2] - red_noon[3]) > 0.02)
		log_world("SUMIARI TEST FAIL full light was not colorless")
	else if(black_noon[1] <= 0.05 || white_noon[1] <= 1 || black_ink[1] >= 0)
		log_world("SUMIARI TEST FAIL ink or glare curve")
	else if(abs(sumiari_channel_intensity(1, 0, 0) - sumiari_channel_intensity(1, 1, 1)) > 0.001)
		log_world("SUMIARI TEST FAIL red light did not match white light")
	else
		log_world("SUMIARI TEST matrix PASS")
	var/min_intensity = 1
	var/max_intensity = 0
	var/sampled = 0
	for(var/turf/scan in world)
		if(scan.z != 1)
			continue
		sampled++
		if(sampled % 6)
			continue
		var/value = sumiari_turf_intensity(scan)
		min_intensity = min(min_intensity, value)
		max_intensity = max(max_intensity, value)
	log_world("SUMIARI TEST map z1 samples=[round(sampled / 6)] min_intensity=[min_intensity] max_intensity=[max_intensity]")
	var/turf/T = locate(20, 20, 1)
	if(!isturf(T))
		log_world("SUMIARI TEST FAIL no turf")
		return
	var/mob/living/carbon/human/human = new(T)
	human.set_species(/datum/species/human/northern)
	log_world("SUMIARI TEST [sumiari_vision_report(human)]")
	var/obj/item/organ/eyes/eyes = human.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes, /obj/item/organ/eyes/sumiari) || eyes.lighting_alpha != SUMIARI_LIGHTING_ALPHA || eyes.see_invisible < SUMIARI_SEE_INVISIBLE || eyes.see_in_dark < SUMIARI_SEE_IN_DARK)
		log_world("SUMIARI TEST FAIL organ sight")
	else
		log_world("SUMIARI TEST organ sight PASS")
	if(eyes)
		eyes.Remove(human)
	log_world("SUMIARI TEST after_remove eyes=[human.getorganslot(ORGAN_SLOT_EYES)?.type || "none"] see_in_dark=[human.see_in_dark] see_invisible=[human.see_invisible] lighting_alpha=[human.lighting_alpha]")
	qdel(human)
	log_world("SUMIARI TEST DONE")

/client/proc/sumiari_vision_debug()
	set category = "Debug"
	set name = "Sumiari Vision Debug"
	set desc = "Log the Sumiari luminosity, saturation, and glare for a mob. Works without looking at their screen."
	if(!holder)
		return
	var/list/choices = list()
	if(iscarbon(mob))
		choices["Myself ([mob])"] = mob
	for(var/mob/living/carbon/nearby in view(7, mob))
		choices["[nearby.name] ([nearby.type])"] = nearby
	if(!length(choices))
		to_chat(src, "No carbons nearby.")
		return
	var/picked = input(src, "Whose vision?", "Sumiari Vision Debug") as null|anything in choices
	if(!picked)
		return
	var/line = sumiari_vision_report(choices[picked])
	log_world(line)
	to_chat(src, line)

// Temporary: humen use these eyes so the vision can be played. Swap keeps eye color from character setup.
/datum/species/human/northern/on_species_gain(mob/living/carbon/C, datum/species/old_species, datum/preferences/pref_load)
	. = ..()
	sumiari_grant_eyes(C)

/proc/sumiari_grant_eyes(mob/living/carbon/C)
	if(!istype(C))
		return
	var/obj/item/organ/eyes/current = C.getorganslot(ORGAN_SLOT_EYES)
	if(!current || istype(current, /obj/item/organ/eyes/sumiari))
		return
	var/obj/item/organ/eyes/sumiari/replacement = new
	replacement.eye_color = current.eye_color
	replacement.heterochromia = current.heterochromia
	replacement.second_color = current.second_color
	replacement.update_accessory_colors()
	replacement.Insert(C, special = TRUE, drop_if_replaced = FALSE)
