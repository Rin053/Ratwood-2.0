// Sumiari vision.
// Pitch black is full color. Wherever a normal human sees light, that same image is an ink wash.
// The wash keeps the sprite's brightness: Rec.709 luma, then a gentle slope that does not threshold.
// A contrast crush turned dither into white specks on black. The glare overlay is off, because a
// normal pool is already full-bright on the lighting plane and the old lift fogged that whole pool.
// The wash is not a second light model. It is the vanilla lighting plane, used as a mask:
// static lights keep their corner-smoothed gradient, movable lights keep the radial cookie,
// sunlight stays in the capture, and fire flicker updates the mask on the same frame.
// dynamic_lumcount is a flat stamp and is not this mask.
//
// The camera-static relay of *sumiari_scene drew nothing on 516.1688. That plate had no atoms.
// An asterisk render_target stores the plane's atoms, not the filters hung on its master, and the
// asterisk keeps the filtered draw off the screen. Sampling it stays blank even when the mask is forced.
// Color matrices on the world plane masters do desaturate on that client, so the wash lives there.
//
// Composite, bottom to top:
// 1. World planes draw themselves, in color, with no light tint. Their render targets have no asterisk.
// 2. Lighting plane 17 stays at alpha 255 and render_target "*lighting". The asterisk is the only hide.
//    Alpha 0 blanks that capture. Movable-light plane 20 is "*O_LIGHT_VISUAL_PLANE" at alpha 255.
// 3. Eight offscreen plates turn *lighting into *sumiari_mask. Each plate is a plane master that only
//    stores the asterisk target, plus a child that draws the source. The child uses render_source, not a
//    layer filter on a 32×32 icon: that filter resampled the whole view down to about one pixel per tile,
//    and the alpha mask scaled it back up as hard tile steps. The child is the size of the view and sits
//    at SCREEN_SOUTHWEST, so the corner gradient and the cookie falloff stay per pixel, and they flicker
//    with the lighting plane. Color matrices and the max blend run on that full image.
// 4. Live ink is a filter list on the above-lighting plane master (plane 21, above every world plane
//    and under the HUD). It stacks those world captures, runs the ink matrix, then masks with
//    *sumiari_mask. Mask 0 leaves that plane transparent, so the color world underneath shows through.
//    Mask 1 covers it with ink. This is not a relay of an empty plate.
// 5. Force ink does not use that stack. Each world plane master gets the ink color matrix directly.
//    Force color takes those filters back off.
//
// Reusable as /obj/item/organ/eyes/sumiari. Humen wear these by default until the Sumiari race exists.
// Revert the human default in code/modules/mob/living/carbon/human/species_types/roguetown/human/humen.dm.

// Drawn brightness where the wash is exactly colorless. 0 is true darkness (full color).
// The fade is linear across that whole span: half the brightness is half the color.
// It meets 0 at this point and stays there. There is no step, and no tint left over past it.
#define SUMIARI_MONO_FULL 1
// Glare eases in across the brightest end of that same line. Full brightness is exactly colorless.
#define SUMIARI_GLARE_START 0.82
#define SUMIARI_GLARE_FULL 1.0
// Not applied. A slope under 1 and a positive bias lifted every fully lit pixel toward paper-white.
#define SUMIARI_GLARE_SLOPE 1
// Not applied. 0.26 was the white fog on light pools.
#define SUMIARI_GLARE_BIAS 0

// Vision-only flourishes. Each one is the ink wash, nothing else. 0 turns that flourish off.
// Left off: each one is another fullscreen plate, and the view has to stay cheap and visible first.
// A faint ink edge on colored darkness. The center of the view stays clear, and lit ground stays bare.
#define SUMIARI_INK_VIGNETTE 0
// Edge strength, 0 to 1. The icon is drawn once from this value.
#define SUMIARI_INK_VIGNETTE_ALPHA 0.22
// A little of the real sun or moon color, added only where the world is still in color.
// Open night picks up the moon. A cave has no sunlight plane, so it stays neutral.
#define SUMIARI_MOON_TINT 0
// How much of that sky color is added. Kept small so it reads as paper, not a blue filter.
#define SUMIARI_MOON_TINT_STRENGTH 0.14
// Off. The lighting-plane mask is already about 1 across a normal pool (a campfire interior is "fully lit"),
// so a haze that starts at 0.82 covered the whole pool and turned it white. Turf debug still said glare 0,
// because that number is lumcount, not the mask. The gray pool is the luma wash alone.
#define SUMIARI_NIGHT_GLARE 0
// Glare alpha at full brightness when the sun is down. Unused while the haze is off.
#define SUMIARI_NIGHT_GLARE_SCALE 0.4

// Rec.709 luma. A gray pixel keeps the brightness of the color pixel.
#define SUMIARI_LUMA_R 0.2126
#define SUMIARI_LUMA_G 0.7152
#define SUMIARI_LUMA_B 0.0722
// Gentle paper curve on that luma. Slope under 1 squeezes dither instead of stretching it into speckle.
// The lift is (1 - slope) / 2, so a mid gray stays a mid gray. Nothing is forced to 0 or 1.
#define SUMIARI_INK_SLOPE 0.96
#define SUMIARI_INK_LIFT 0.02

// Full strength, and the asterisk keeps it off the screen. Alpha 0 blanks the capture the mask reads.
#define SUMIARI_LIGHTING_ALPHA LIGHTING_PLANE_ALPHA_VISIBLE
// The mask reads this render target and nothing else. dynamic_lumcount is not an input.
#define SUMIARI_LIGHTING_SOURCE "*lighting"
// Asterisk plus O_LIGHTING_VISUAL_RENDER_TARGET. The define already includes quotes, so it cannot be nested in another string.
#define SUMIARI_OLIGHT_SOURCE "*O_LIGHT_VISUAL_PLANE"
#define SUMIARI_WASH_LIVE "live"
#define SUMIARI_WASH_INK "ink"
#define SUMIARI_WASH_COLOR "color"
// 8 mask plates, each a master plus the child that actually draws the capture, plus one glare object.
#define SUMIARI_PIECE_CAP 24
// Covers a 15x15 view (radius 7). Opaque walls and trees still block sight. This is not x-ray.
#define SUMIARI_SEE_IN_DARK 8
// Darkness-sneak raises invisibility to SEE_INVISIBLE_LIVING + skill*0.55 + 1 (about 29 at legendary).
// 35 sees that concealment and stays under SEE_INVISIBLE_OBSERVER (60), so ghosts stay hidden.
#define SUMIARI_SEE_INVISIBLE (SEE_INVISIBLE_LIVING + 10)

// Live ink is a filter on this plane master. It is above the map and the hidden lighting planes, under fullscreen and the HUD.
#define SUMIARI_INK_PLANE ABOVE_LIGHTING_PLANE
// Glare is a screen object one plane higher, so its mask cannot punch the ink filter under it.
#define SUMIARI_RELAY_PLANE CAMERA_STATIC_PLANE
#define SUMIARI_RELAY_LAYER_BASE 40

// Offscreen plates. These sit under the world, so a client that ignores the asterisk still covers them with the map.
#define SUMIARI_PLANE_RED -60
#define SUMIARI_PLANE_GREEN -59
#define SUMIARI_PLANE_BLUE -58
#define SUMIARI_PLANE_ALPHA -57
#define SUMIARI_PLANE_UNLIT -56
#define SUMIARI_PLANE_LIGHT -55
#define SUMIARI_PLANE_MASK -54
#define SUMIARI_PLANE_GLARE -53
#define SUMIARI_PLANE_DARK -51
#define SUMIARI_PLANE_MOON -50

#define SUMIARI_TARGET_RED "sumiari_ch_r"
#define SUMIARI_TARGET_GREEN "sumiari_ch_g"
#define SUMIARI_TARGET_BLUE "sumiari_ch_b"
#define SUMIARI_TARGET_ALPHA "sumiari_alpha"
#define SUMIARI_TARGET_UNLIT "sumiari_unlit"
#define SUMIARI_TARGET_LIGHT "sumiari_light"
#define SUMIARI_TARGET_MASK "sumiari_mask"
#define SUMIARI_TARGET_GLARE "sumiari_glare"
#define SUMIARI_TARGET_DARK "sumiari_dark"
#define SUMIARI_TARGET_MOON "sumiari_moon"

// Stored in place of a null render_target. BYOND drops a list entry whose value is null.
#define SUMIARI_NO_TARGET ""

// Draw order is the order a normal human composites the world. Lowest first.
GLOBAL_LIST_INIT(sumiari_vision_plane_order, list(
	OPENSPACE_PLANE,
	OPENSPACE_BACKDROP_PLANE,
	FLOOR_PLANE,
	WALL_PLANE,
	GAME_PLANE_LOWER,
	GAME_PLANE,
	GAME_PLANE_FOV_HIDDEN,
	GAME_PLANE_UPPER,
	GAME_PLANE_HIGHEST,
	WEATHER_EFFECT_PLANE,
	WEATHER_PLANE,
	ABOVE_LIGHTING_PLANE,
))

/proc/sumiari_plane_is_world(plane)
	return (plane in GLOB.sumiari_vision_plane_order)

// No asterisk. The plane keeps drawing, and this name is the copy the scene plate samples.
/proc/sumiari_world_render_target(plane)
	return "sumiari_w[plane]"

/proc/sumiari_world_render_source(plane)
	return "sumiari_w[plane]"

// Asterisk is part of the name. Sample the same string the plate stores.
/proc/sumiari_offscreen(name)
	return "*[name]"

/obj/item/organ/eyes/sumiari
	name = "sumiari eyes"
	desc = "They drink the color out of lamplight and pour it back into the dark."
	see_in_dark = SUMIARI_SEE_IN_DARK
	see_invisible = SUMIARI_SEE_INVISIBLE
	lighting_alpha = SUMIARI_LIGHTING_ALPHA
	var/vision_on = FALSE
	var/list/saved_render_targets
	var/list/screen_pieces
	// The glare sampler's color matrix is rebuilt when the sun moves, so night haze can ease without a new composite.
	var/atom/movable/screen/sumiari_sampler/glare_plate
	// Pixel size of the mask canvas. A view change rebuilds it so the sample stays one pixel per screen pixel.
	var/mask_pixels_x = 0
	var/mask_pixels_y = 0
	// live uses the lighting mask. ink forces that mask to 1. color forces it to 0.
	var/wash_mode = SUMIARI_WASH_LIVE

var/global/list/sumiari_active_eyes = list()
var/global/sumiari_screen_live = 0
// Headless sweep builds the composite with a hud and no client. Live play still requires a client.
var/global/sumiari_test_without_client = FALSE

/obj/item/organ/eyes/sumiari/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = FALSE, initialising)
	. = ..()
	// Full alpha. The asterisk on the lighting plane is what keeps the darkness off the world.
	// 0 would be treated as unset by the parent when TRAIT_NIGHT_VISION is present, and it blanks the capture.
	lighting_alpha = SUMIARI_LIGHTING_ALPHA
	if(!owner)
		return
	owner.update_sight()
	RegisterSignal(owner, COMSIG_MOB_LOGIN, PROC_REF(on_owner_login))
	RegisterSignal(owner, COMSIG_MOB_LOGOUT, PROC_REF(on_owner_logout))
	RegisterSignal(owner, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_owner_z_change))
	attach_client_vision()

/obj/item/organ/eyes/sumiari/Remove(mob/living/carbon/M, special = 0)
	if(M)
		UnregisterSignal(M, list(COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT, COMSIG_MOVABLE_Z_CHANGED))
		M.see_in_dark = initial(M.see_in_dark)
		M.see_invisible = initial(M.see_invisible)
		M.lighting_alpha = initial(M.lighting_alpha)
	release_client_vision(M)
	return ..()

/obj/item/organ/eyes/sumiari/Destroy()
	release_client_vision(owner)
	return ..()

/obj/item/organ/eyes/sumiari/proc/on_owner_login(datum/source)
	SIGNAL_HANDLER
	attach_client_vision()

/obj/item/organ/eyes/sumiari/proc/on_owner_logout(datum/source)
	SIGNAL_HANDLER
	release_client_vision(owner)

// Plane masters survive a z-change. Recapture so a backdrop that ran on the way through cannot leave a plane unmasked.
/obj/item/organ/eyes/sumiari/proc/on_owner_z_change(datum/source, old_z, new_z)
	SIGNAL_HANDLER
	if(!vision_on || old_z == new_z)
		return
	hold_lighting_capture()
	capture_world_planes()
	apply_wash_filters()

/obj/item/organ/eyes/sumiari/proc/attach_client_vision()
	if(!owner?.hud_used)
		return
	if(!owner.client && !sumiari_test_without_client)
		return
	if(vision_on && length(screen_pieces) && mask_canvas_matches())
		sumiari_active_eyes[src] = TRUE
		present_screen_pieces()
		hold_lighting_capture()
		capture_world_planes()
		apply_wash_filters()
		return
	// The view grew or shrank. The old canvas would resample the lighting plane, which is the tile step.
	if(vision_on && length(screen_pieces))
		clear_screen_pieces()
	vision_on = TRUE
	sumiari_active_eyes[src] = TRUE
	if(!saved_render_targets)
		saved_render_targets = list()
	hold_lighting_capture()
	capture_world_planes()
	build_screen_pieces()
	present_screen_pieces()

/obj/item/organ/eyes/sumiari/proc/release_client_vision(mob/living/carbon/M)
	sumiari_active_eyes -= src
	vision_on = FALSE
	wash_mode = SUMIARI_WASH_LIVE
	glare_plate = null
	clear_master_wash(M)
	clear_screen_pieces(M)
	restore_render_targets(M)
	saved_render_targets = null
	var/mob/living/carbon/who = M || owner
	var/atom/movable/screen/plane_master/lighting/lighting = who?.hud_used?.plane_masters["[LIGHTING_PLANE]"]
	if(lighting)
		lighting.filters = sumiari_lighting_punch_filters(O_LIGHTING_VISUAL_RENDER_TARGET)
		lighting.alpha = who.lighting_alpha

/obj/item/organ/eyes/sumiari/proc/present_screen_pieces()
	if(!owner)
		return
	for(var/atom/movable/screen/piece as anything in screen_pieces)
		owner.add_screen_object(piece)

/obj/item/organ/eyes/sumiari/proc/clear_screen_pieces(mob/living/carbon/M)
	var/mob/living/carbon/who = M || owner
	if(who)
		for(var/atom/movable/screen/piece as anything in screen_pieces)
			who.remove_screen_object(piece)
	if(screen_pieces)
		QDEL_LIST(screen_pieces)
	screen_pieces = null

/obj/item/organ/eyes/sumiari/proc/remember_render_target(atom/movable/screen/plane_master/plane, desired)
	if(!plane || plane.render_target == desired)
		return
	if(!saved_render_targets)
		saved_render_targets = list()
	var/key = "[plane.plane]"
	if(!(key in saved_render_targets))
		saved_render_targets[key] = plane.render_target || SUMIARI_NO_TARGET
	plane.render_target = desired

/obj/item/organ/eyes/sumiari/proc/restore_render_targets(mob/living/carbon/M)
	var/mob/living/carbon/who = M || owner
	if(!who?.hud_used || !saved_render_targets)
		return
	for(var/key in saved_render_targets)
		var/atom/movable/screen/plane_master/plane = who.hud_used.plane_masters[key]
		if(!plane)
			continue
		var/saved = saved_render_targets[key]
		plane.render_target = (saved == SUMIARI_NO_TARGET) ? null : saved

// Capture the vanilla lighting image at full strength and do not draw it. The asterisk is the hide.
// The movable-light plane is captured the same way, and the lighting plane's punch filter is pointed at that name.
/obj/item/organ/eyes/sumiari/proc/hold_lighting_capture()
	if(!owner?.hud_used)
		return
	owner.lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
	var/atom/movable/screen/plane_master/lighting/lighting = owner.hud_used.plane_masters["[LIGHTING_PLANE]"]
	if(lighting)
		lighting.alpha = LIGHTING_PLANE_ALPHA_VISIBLE
		remember_render_target(lighting, SUMIARI_LIGHTING_SOURCE)
		lighting.filters = sumiari_lighting_punch_filters(SUMIARI_OLIGHT_SOURCE)
	var/atom/movable/screen/plane_master/cookie = owner.hud_used.plane_masters["[O_LIGHTING_VISUAL_PLANE]"]
	if(cookie)
		cookie.alpha = LIGHTING_PLANE_ALPHA_VISIBLE
		remember_render_target(cookie, SUMIARI_OLIGHT_SOURCE)

// Inverse-alpha holes for emissives and movable lights. olight_source is the cookie plane's render target.
/proc/sumiari_lighting_punch_filters(olight_source)
	return list(
		filter(type = "alpha", render_source = EMISSIVE_RENDER_TARGET, flags = MASK_INVERSE),
		filter(type = "alpha", render_source = EMISSIVE_UNBLOCKABLE_RENDER_TARGET, flags = MASK_INVERSE),
		filter(type = "alpha", render_source = olight_source, flags = MASK_INVERSE),
	)

/obj/item/organ/eyes/sumiari/proc/capture_world_planes()
	if(!owner?.hud_used)
		return
	for(var/plane in GLOB.sumiari_vision_plane_order)
		var/atom/movable/screen/plane_master/master = owner.hud_used.plane_masters["[plane]"]
		if(!master)
			continue
		remember_render_target(master, sumiari_world_render_target(plane))

/obj/item/organ/eyes/sumiari/proc/capture_world_plane(atom/movable/screen/plane_master/plane)
	if(!vision_on || !plane)
		return
	remember_render_target(plane, sumiari_world_render_target(plane.plane))

/obj/item/organ/eyes/sumiari/proc/build_screen_pieces()
	glare_plate = null
	if(screen_pieces)
		QDEL_LIST(screen_pieces)
	screen_pieces = list()
	build_mask_plates()
	build_glare_object()
	build_flourishes()
	apply_wash_filters()

// The asterisk capture stores atoms on the plane, not filters on the master. The child is that atom.
// source_name is the child's render_source, so the sample is the plane's own pixels. The filters only
// recolor or blend. A layer filter of the source onto a small icon is what made the tile steps.
/obj/item/organ/eyes/sumiari/proc/add_plate(plane, target_name, source_name, list/plate_filters)
	var/list/span = sumiari_mask_span(owner?.client?.view)
	var/atom/movable/screen/sumiari_plate/plate = new
	plate.plane = plane
	plate.name = target_name
	plate.render_target = sumiari_offscreen(target_name)
	plate.blockscharging = FALSE
	var/atom/movable/screen/sumiari_sampler/sampler = new
	sampler.plane = plane
	sampler.name = "[target_name] sample"
	sampler.render_source = source_name
	sampler.icon = sumiari_mask_canvas(owner?.client?.view)
	sampler.icon_state = ""
	sampler.screen_loc = "SCREEN_SOUTHWEST"
	sampler.sumiari_pixels_x = span[1]
	sampler.sumiari_pixels_y = span[2]
	sampler.filters = plate_filters
	sampler.blockscharging = FALSE
	if(target_name == SUMIARI_TARGET_GLARE)
		glare_plate = sampler
	screen_pieces += plate
	screen_pieces += sampler
	return sampler

/obj/item/organ/eyes/sumiari/proc/mask_canvas_matches()
	var/list/span = sumiari_mask_span(owner?.client?.view)
	return mask_pixels_x == span[1] && mask_pixels_y == span[2] && mask_pixels_x > 0

/obj/item/organ/eyes/sumiari/proc/build_mask_plates()
	// mask = 1 - A * (1 - max(R, G, B)), taken from the lighting-plane render. Not from dynamic_lumcount.
	var/list/span = sumiari_mask_span(owner?.client?.view)
	mask_pixels_x = span[1]
	mask_pixels_y = span[2]
	add_plate(SUMIARI_PLANE_RED, SUMIARI_TARGET_RED, SUMIARI_LIGHTING_SOURCE, sumiari_lighting_channel_filters(1))
	add_plate(SUMIARI_PLANE_GREEN, SUMIARI_TARGET_GREEN, SUMIARI_LIGHTING_SOURCE, sumiari_lighting_channel_filters(2))
	add_plate(SUMIARI_PLANE_BLUE, SUMIARI_TARGET_BLUE, SUMIARI_LIGHTING_SOURCE, sumiari_lighting_channel_filters(3))
	add_plate(SUMIARI_PLANE_ALPHA, SUMIARI_TARGET_ALPHA, SUMIARI_LIGHTING_SOURCE, sumiari_lighting_channel_filters(4))
	// Green is the full-resolution base. Subtract-then-add is max, because subtract clamps at 0.
	add_plate(SUMIARI_PLANE_UNLIT, SUMIARI_TARGET_UNLIT, sumiari_offscreen(SUMIARI_TARGET_GREEN), list(
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_RED), blend_mode = BLEND_SUBTRACT),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_RED), blend_mode = BLEND_ADD),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_BLUE), blend_mode = BLEND_SUBTRACT),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_BLUE), blend_mode = BLEND_ADD),
		filter(type = "color", color = sumiari_matrix_force_alpha()),
		filter(type = "color", color = sumiari_matrix_invert_gray()),
	))
	add_plate(SUMIARI_PLANE_LIGHT, SUMIARI_TARGET_LIGHT, sumiari_offscreen(SUMIARI_TARGET_ALPHA), list(
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_UNLIT), blend_mode = BLEND_MULTIPLY),
		filter(type = "color", color = sumiari_matrix_invert_gray()),
	))
	add_plate(SUMIARI_PLANE_MASK, SUMIARI_TARGET_MASK, sumiari_offscreen(SUMIARI_TARGET_LIGHT), list(
		filter(type = "color", color = sumiari_matrix_gray_to_alpha()),
	))
	add_plate(SUMIARI_PLANE_GLARE, SUMIARI_TARGET_GLARE, sumiari_offscreen(SUMIARI_TARGET_LIGHT), list(
		filter(type = "color", color = sumiari_matrix_glare_to_alpha()),
	))

// Glare sits above the ink plane. Alpha 0 until live mode turns it on.
/obj/item/organ/eyes/sumiari/proc/build_glare_object()
#if SUMIARI_NIGHT_GLARE
	var/atom/movable/screen/sumiari_relay/glare = new
	glare.name = "sumiari glare"
	glare.plane = SUMIARI_RELAY_PLANE
	glare.layer = SUMIARI_RELAY_LAYER_BASE + 1
	glare.alpha = 0
	glare.blockscharging = FALSE
	screen_pieces += glare
#endif

// Drop wash filters from the world plane masters. Backdrop filters (occlusion, blur, sight blockers) stay.
/obj/item/organ/eyes/sumiari/proc/clear_master_wash(mob/living/carbon/M)
	var/mob/living/carbon/who = M || owner
	if(!who?.hud_used)
		return
	for(var/plane in GLOB.sumiari_vision_plane_order)
		sumiari_strip_master_wash(who.hud_used.plane_masters["[plane]"])

// live stacks the world onto the above-lighting master and masks it.
// ink paints the ink matrix onto every world plane master and does not consult the mask.
// color leaves the masters as the backdrop built them.
/obj/item/organ/eyes/sumiari/proc/apply_wash_filters()
	if(!owner?.hud_used)
		return
	for(var/plane in GLOB.sumiari_vision_plane_order)
		var/atom/movable/screen/plane_master/master = owner.hud_used.plane_masters["[plane]"]
		sumiari_strip_master_wash(master)
		if(!master)
			continue
		if(wash_mode == SUMIARI_WASH_INK)
			sumiari_add_filter(master, filter(type = "color", color = sumiari_color_matrix(SUMIARI_MONO_FULL, 0)))
			continue
		if(wash_mode != SUMIARI_WASH_LIVE || master.plane != SUMIARI_INK_PLANE)
			continue
		for(var/stacked in GLOB.sumiari_vision_plane_order)
			var/atom/movable/screen/plane_master/source = owner.hud_used.plane_masters["[stacked]"]
			if(!source)
				continue
			sumiari_add_filter(master, filter(type = "layer", render_source = sumiari_world_render_source(stacked), blend_mode = source.blend_mode))
		sumiari_add_filter(master, filter(type = "color", color = sumiari_color_matrix(SUMIARI_MONO_FULL, 0)))
		sumiari_add_filter(master, filter(type = "alpha", render_source = sumiari_offscreen(SUMIARI_TARGET_MASK)))
	var/atom/movable/screen/sumiari_relay/glare = sumiari_find_piece(src, "sumiari glare")
	if(!glare)
		return
	if(wash_mode != SUMIARI_WASH_LIVE)
		glare.alpha = 0
		glare.filters = null
		return
	var/list/glare_filters = list()
	for(var/stacked in GLOB.sumiari_vision_plane_order)
		var/atom/movable/screen/plane_master/source = owner.hud_used.plane_masters["[stacked]"]
		if(!source)
			continue
		glare_filters += filter(type = "layer", render_source = sumiari_world_render_source(stacked), blend_mode = source.blend_mode)
	glare_filters += filter(type = "color", color = sumiari_color_matrix(SUMIARI_MONO_FULL, 1))
	glare_filters += filter(type = "alpha", render_source = sumiari_offscreen(SUMIARI_TARGET_GLARE))
	glare.alpha = 255
	glare.filters = glare_filters

// Ink edge, and a trace of the sky's own color, both limited to pixels the lighting plane still calls dark.
/obj/item/organ/eyes/sumiari/proc/build_flourishes()
#if SUMIARI_INK_VIGNETTE || SUMIARI_MOON_TINT
	add_plate(SUMIARI_PLANE_DARK, SUMIARI_TARGET_DARK, sumiari_offscreen(SUMIARI_TARGET_LIGHT), list(
		filter(type = "color", color = sumiari_matrix_invert_gray()),
		filter(type = "color", color = sumiari_matrix_gray_to_alpha()),
	))
#endif
#if SUMIARI_MOON_TINT
	add_plate(SUMIARI_PLANE_MOON, SUMIARI_TARGET_MOON, SUNLIGHTING_RENDER_TARGET, list(
		filter(type = "color", color = sumiari_matrix_moon_tint()),
	))
	var/atom/movable/screen/sumiari_relay/moon = new
	moon.name = "sumiari moon"
	moon.layer = SUMIARI_RELAY_LAYER_BASE + 28
	moon.blend_mode = BLEND_ADD
	moon.blockscharging = FALSE
	moon.filters = list(
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_MOON), blend_mode = BLEND_OVERLAY),
		filter(type = "alpha", render_source = sumiari_offscreen(SUMIARI_TARGET_DARK)),
	)
	screen_pieces += moon
#endif
#if SUMIARI_INK_VIGNETTE
	var/atom/movable/screen/sumiari_vignette/vignette = new
	vignette.icon = sumiari_vignette_icon()
	vignette.blockscharging = FALSE
	vignette.filters = list(filter(type = "alpha", render_source = sumiari_offscreen(SUMIARI_TARGET_DARK)))
	screen_pieces += vignette
#endif

/obj/item/organ/eyes/sumiari/proc/refresh_time_filters()
	if(!vision_on || !glare_plate)
		return
	glare_plate.filters = list(
		filter(type = "color", color = sumiari_matrix_glare_to_alpha()),
	)

/atom/movable/screen/plane_master/proc/apply_sumiari_sight(mob/mymob)
	if(!sumiari_plane_is_world(plane))
		return
	if(!iscarbon(mymob))
		return
	var/mob/living/carbon/carbon = mymob
	var/obj/item/organ/eyes/sumiari/eyes = carbon.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes))
		if(render_target == sumiari_world_render_target(plane))
			render_target = null
		return
	eyes.attach_client_vision()
	if(!eyes.vision_on)
		return
	eyes.capture_world_plane(src)
	eyes.apply_wash_filters()

// Reading a filter var it does not have is a runtime, and that runtime was aborting the strip.
// Blur and drop-shadow stay on the plane masters. Only layer, alpha, and color are ours to inspect.
/proc/sumiari_filter_kind(sample)
	if(!sample)
		return
	return sample:type

/proc/sumiari_is_wash_filter(sample)
	var/kind = sumiari_filter_kind(sample)
	if(kind == "layer" || kind == "alpha")
		var/source = sample:render_source
		if(source == sumiari_offscreen(SUMIARI_TARGET_MASK) || source == sumiari_offscreen(SUMIARI_TARGET_GLARE))
			return TRUE
		for(var/plane in GLOB.sumiari_vision_plane_order)
			if(source == sumiari_world_render_source(plane))
				return TRUE
		return FALSE
	if(kind == "color")
		return sumiari_filter_is_full_ink(sample)
	return FALSE

/proc/sumiari_filter_is_full_ink(sample)
	if(sumiari_filter_kind(sample) != "color")
		return FALSE
	var/color = sample:color
	if(!islist(color) || length(color) < 17)
		return FALSE
	var/list/ink = sumiari_color_matrix(SUMIARI_MONO_FULL, 0)
	return abs(color[1] - ink[1]) < 0.001 && abs(color[2] - ink[2]) < 0.001 && abs(color[5] - ink[5]) < 0.001 && abs(color[17] - ink[17]) < 0.001

/proc/sumiari_strip_master_wash(atom/movable/screen/plane_master/master)
	if(!master?.filters)
		return
	var/list/kept = list()
	for(var/sample in master.filters)
		if(sumiari_is_wash_filter(sample))
			continue
		kept += sample
	if(length(kept))
		master.filters = kept
	else
		master.filters = null

/proc/sumiari_add_filter(atom/movable/target, filter_entry)
	if(!target)
		return
	if(target.filters)
		target.filters += filter_entry
	else
		target.filters = list(filter_entry)

// One offscreen step. The master only holds the asterisk target. The sampler child is what the capture stores.
// CENTER, same as the lighting plane master, so this buffer shares that plane's origin.
/atom/movable/screen/sumiari_plate
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "blank"
	appearance_flags = PLANE_MASTER | NO_CLIENT_COLOR | PASS_MOUSE | KEEP_TOGETHER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_DEFAULT
	screen_loc = "CENTER"
	blockscharging = FALSE

/atom/movable/screen/sumiari_plate/Initialize(mapload)
	. = ..()
	sumiari_screen_live++

/atom/movable/screen/sumiari_plate/Destroy()
	sumiari_screen_live--
	return ..()

// Drawn into the plate's asterisk capture. Not a plane master, so it cannot replace the plate.
// render_source replaces this icon. The icon is still the size of the view: a 32×32 stand-in is what
// resampled *lighting down to one pixel a tile. SCREEN_SOUTHWEST is the 516 anchor, bottom-left to bottom-left.
/atom/movable/screen/sumiari_sampler
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "blank"
	appearance_flags = NO_CLIENT_COLOR | PASS_MOUSE | KEEP_TOGETHER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_DEFAULT
	screen_loc = "SCREEN_SOUTHWEST"
	blockscharging = FALSE
	var/sumiari_pixels_x = 0
	var/sumiari_pixels_y = 0

/atom/movable/screen/sumiari_sampler/Initialize(mapload)
	. = ..()
	sumiari_screen_live++

/atom/movable/screen/sumiari_sampler/Destroy()
	sumiari_screen_live--
	return ..()

// The ink wash, or its glare, laid over the color world. Alpha comes from the lighting mask, so true darkness draws nothing here.
// No NO_CLIENT_COLOR: the game plane takes client colour, and so does this copy of it.
// Death's monochrome, and any other client colour, therefore covers the wash.
/atom/movable/screen/sumiari_relay
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = ""
	screen_loc = "CENTER-2:-16,CENTER"
	plane = SUMIARI_RELAY_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PASS_MOUSE | KEEP_TOGETHER
	blend_mode = BLEND_DEFAULT
	blockscharging = FALSE

/atom/movable/screen/sumiari_relay/Initialize(mapload)
	. = ..()
	sumiari_screen_live++

/atom/movable/screen/sumiari_relay/Destroy()
	sumiari_screen_live--
	return ..()

// Full-view ink edge. The darkness mask hides it wherever the lighting plane is bright.
/atom/movable/screen/sumiari_vignette
	icon_state = ""
	screen_loc = "CENTER-7,CENTER-7"
	plane = SUMIARI_RELAY_PLANE
	layer = SUMIARI_RELAY_LAYER_BASE + 30
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PASS_MOUSE | KEEP_TOGETHER
	blend_mode = BLEND_DEFAULT
	blockscharging = FALSE

/atom/movable/screen/sumiari_vignette/Initialize(mapload)
	. = ..()
	sumiari_screen_live++

/atom/movable/screen/sumiari_vignette/Destroy()
	sumiari_screen_live--
	return ..()

/proc/sumiari_refresh_client_vision(mob/M)
	if(!iscarbon(M))
		return
	var/obj/item/organ/eyes/sumiari/eyes = M.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes))
		return
	eyes.attach_client_vision()

/proc/sumiari_hold_lighting_capture(mob/M)
	if(!iscarbon(M))
		return
	var/obj/item/organ/eyes/sumiari/eyes = M.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes) || !eyes.vision_on)
		return
	eyes.hold_lighting_capture()

// How strongly one lighting-plane pixel lights the world under BLEND_MULTIPLY.
// Opaque black is darkness. Opaque white, or any fully transparent hole, is full light.
// Half gray is half light. The peak channel is used, so a red lamp matches a white one.
/proc/sumiari_light_mask(red, green, blue, alpha)
	return 1 - alpha * (1 - max(red, green, blue))

// Pixel size of the current view. The mask canvas matches this so the lighting plane is not resampled.
/proc/sumiari_mask_span(view)
	return view_to_pixels(view || world.view)

// One transparent icon per view size. Shared. The sampler's render_source is the real image.
/proc/sumiari_mask_canvas(view)
	var/static/list/cache
	if(!cache)
		cache = list()
	var/list/span = sumiari_mask_span(view)
	var/key = "[span[1]]x[span[2]]"
	var/icon/cached = cache[key]
	if(cached)
		return cached
	var/icon/canvas = icon('icons/mob/screen_gen.dmi', "blank")
	canvas.Scale(span[1], span[2])
	cache[key] = canvas
	return canvas

// Color matrix only. The lighting plane arrives through the sampler's render_source, at the plane's own resolution.
/proc/sumiari_lighting_channel_filters(channel)
	return list(
		filter(type = "color", color = sumiari_matrix_channel(channel)),
	)

// channel 1/2/3 copies that color into gray and forces alpha to 1. Channel 4 copies alpha into gray.
/proc/sumiari_matrix_channel(channel)
	switch(channel)
		if(1)
			return list(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)
		if(2)
			return list(0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)
		if(3)
			return list(0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1)
		if(4)
			return list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1)
	return color_matrix_identity()

/proc/sumiari_matrix_force_alpha()
	return list(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1)

// Grayscale value lives in R. Output is 1 - R on every channel, alpha forced to 1.
/proc/sumiari_matrix_invert_gray()
	return list(-1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1)

// White RGB, alpha = R. The alpha mask filter reads that alpha.
/proc/sumiari_matrix_gray_to_alpha()
	return list(0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0)

// Alpha is 0 below the glare threshold and 1 at full brightness. The renderer clamps.
// sun_override forces the night ease. Null uses the live sun.
/proc/sumiari_matrix_glare_to_alpha(sun_override)
	var/span = SUMIARI_GLARE_FULL - SUMIARI_GLARE_START
	var/night = sumiari_night_glare_scale(sun_override)
	var/scale = night / span
	var/bias = night * (-SUMIARI_GLARE_START / span)
	return list(0, 0, 0, scale, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, bias)

// Scales the sunlight plane and forces its alpha to 1. The darkness mask then decides where it shows.
/proc/sumiari_matrix_moon_tint()
	var/strength = SUMIARI_MOON_TINT_STRENGTH
	return list(strength, 0, 0, 0, 0, strength, 0, 0, 0, 0, strength, 0, 0, 0, 0, 0, 0, 0, 0, 1)

// 1 in daylight. SUMIARI_NIGHT_GLARE_SCALE when the sun is down. Linear between those.
/proc/sumiari_night_glare_scale(sun_override)
#if !SUMIARI_NIGHT_GLARE
	return 1
#else
	var/sun = isnull(sun_override) ? sumiari_sun_strength() : sun_override
	if(sun >= SUMIARI_GLARE_START)
		return 1
	if(sun <= 0)
		return SUMIARI_NIGHT_GLARE_SCALE
	return SUMIARI_NIGHT_GLARE_SCALE + (1 - SUMIARI_NIGHT_GLARE_SCALE) * (sun / SUMIARI_GLARE_START)
#endif

// One full-view ink edge. Drawn once and reused. Transparent in the middle, ink at the rim.
/proc/sumiari_vignette_icon()
	var/static/icon/cached
	if(cached)
		return cached
	var/icon/canvas = icon('icons/mob/screen_gen.dmi', "blank")
	canvas.Scale(96, 96)
	canvas.MapColors(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	var/side = 96
	var/bands = 18
	for(var/band in 1 to bands)
		var/alpha = round(255 * SUMIARI_INK_VIGNETTE_ALPHA * band / bands)
		var/ink = rgb(12, 14, 18, alpha)
		canvas.DrawBox(ink, band, band, side - band + 1, band)
		canvas.DrawBox(ink, band, side - band + 1, side - band + 1, side - band + 1)
		canvas.DrawBox(ink, band, band, band, side - band + 1)
		canvas.DrawBox(ink, side - band + 1, band, side - band + 1, side - band + 1)
	canvas.Scale(480, 480)
	cached = canvas
	return cached

/proc/sumiari_on_sun_changed()
	for(var/obj/item/organ/eyes/sumiari/eyes as anything in sumiari_active_eyes)
		if(QDELETED(eyes))
			continue
		eyes.refresh_time_filters()

// Strength of one light sample. Peak channel, so a red lamp matches a white lamp of the same power.
/proc/sumiari_channel_intensity(red, green, blue)
	return max(red, green, blue)

// Brightness the lighting overlay actually draws for one corner. At most 1.
// cache_* is lum scaled so the strongest channel is at most 1. A stale cache (still 0) falls back to that same clamp.
/proc/sumiari_corner_drawn(datum/lighting_corner/corner)
	if(!corner)
		return 0
	var/drawn = sumiari_channel_intensity(corner.cache_r, corner.cache_g, corner.cache_b)
	var/peak = sumiari_channel_intensity(corner.lum_r, corner.lum_g, corner.lum_b)
	if(peak > 1)
		peak = 1
	if(peak > drawn)
		return peak
	return drawn

/proc/sumiari_sky_name(state)
	switch(state)
		if(SKY_BLOCKED)
			return "blocked"
		if(SKY_VISIBLE)
			return "visible"
		if(SKY_VISIBLE_BORDER)
			return "border"
	return "none"

// How much of the sun mask is drawn here. Open sky and its border are fully lit. A roof only gets falloff from a nearby opening.
/proc/sumiari_sun_mask(turf/T)
	if(!T?.outdoor_effect)
		return 0
	if(T.outdoor_effect.state != SKY_BLOCKED)
		return 1
	if(!T.corners)
		return 0
	var/total = 0
	var/counted = 0
	for(var/datum/lighting_corner/corner as anything in T.corners)
		if(!corner)
			continue
		total += corner.sunFalloff
		counted++
	if(!counted)
		return 0
	return total / counted

// Numbers behind one turf's brightness. "intensity" is what the vision uses.
/proc/sumiari_light_sample(turf/T)
	. = list(
		"intensity" = 0,
		"lamps" = 0,
		"raw_peak" = 0,
		"sun" = 0,
		"sun_mask" = 0,
		"sun_strength" = 0,
		"dynamic" = 0,
		"text" = "sumiari light: no turf",
		)
	if(!isturf(T))
		return
	var/sun_strength = sumiari_sun_strength()
	var/sun_mask = sumiari_sun_mask(T)
	var/sun = sun_mask * sun_strength
	var/dynamic = T.dynamic_lumcount
	var/movable = sumiari_movable_brightness(T)
	if(!T.has_dynamic_lighting())
		.["intensity"] = 1
		.["sun"] = sun
		.["sun_mask"] = sun_mask
		.["sun_strength"] = sun_strength
		.["dynamic"] = dynamic
		.["text"] = "sumiari light: [T.x],[T.y],[T.z] static_full area=[T.loc] intensity=1 sun=[sun] dyn=[dynamic] movable=[movable]"
		return
	var/lamps = 0
	var/raw_peak = 0
	var/falloff = 0
	var/counted = 0
	var/list/corner_text = list()
	if(T.corners)
		for(var/datum/lighting_corner/corner as anything in T.corners)
			if(!corner)
				corner_text += "null"
				continue
			counted++
			lamps += sumiari_corner_drawn(corner)
			raw_peak += min(1, sumiari_channel_intensity(corner.lum_r, corner.lum_g, corner.lum_b))
			falloff += corner.sunFalloff
			corner_text += "[corner.lum_r],[corner.lum_g],[corner.lum_b] cache=[corner.cache_r],[corner.cache_g],[corner.cache_b] falloff=[corner.sunFalloff]"
	if(counted)
		lamps /= counted
		raw_peak /= counted
		falloff /= counted
	// dynamic_lumcount is a flat stamp (0.5 on every turf in view of a held light). It is not the
	// mask the player sees, so a pitch-black cave tile inside that radius was reading as half lit.
	// Held lights contribute their visual falloff instead. Corner cache is the static-light overlay.
	var/intensity = CLAMP01(lamps + sun + movable)
	var/overlay = "none"
	var/datum/lighting_object/lighting = T.lighting_object
	if(lighting?.current_underlay == GLOB.lighting_underlay_dark)
		overlay = "dark"
	else if(lighting?.current_underlay == GLOB.lighting_underlay_transparent)
		overlay = "clear"
	else if(lighting?.current_underlay)
		overlay = "partial alpha=[lighting.current_underlay.alpha]"
	var/sky = "none"
	var/sun_overlay_lum = 0
	if(T.outdoor_effect)
		sky = sumiari_sky_name(T.outdoor_effect.state)
		sun_overlay_lum = T.outdoor_effect.sunlight_overlay?.luminosity
	var/list/nearby = list()
	for(var/atom/source in range(4, T))
		if(!source.light_on || source.light_outer_range <= 0 || source.light_power <= 0)
			continue
		nearby += "[source.name]@[source.x],[source.y] power=[source.light_power] range=[source.light_outer_range]"
		if(length(nearby) >= 6)
			break
	.["intensity"] = intensity
	.["lamps"] = lamps
	.["raw_peak"] = raw_peak
	.["sun"] = sun
	.["sun_mask"] = sun_mask
	.["sun_strength"] = sun_strength
	.["dynamic"] = dynamic
	.["text"] = "sumiari light: [T.x],[T.y],[T.z] area=[T.loc] intensity=[intensity] lamps=[lamps] raw_peak=[raw_peak] sun=[sun] sun_mask=[sun_mask] sun_strength=[sun_strength] sun_state=[sky] sun_overlay_lum=[sun_overlay_lum] falloff=[falloff] movable=[movable] dyn=[dynamic] get_lumcount=[T.get_lumcount()] luminosity=[T.luminosity] overlay=[overlay] softly_lit=[T.is_softly_lit() ? 1 : 0] sun_color=[SSoutdoor_effects?.picked_color] tod=[SSoutdoor_effects?.current_step_datum?.type] corners=\[[corner_text.Join(" | ")]\] lights=\[[nearby.Join(" ; ")]\]"

/proc/sumiari_turf_intensity(turf/T)
	return sumiari_light_sample(T)["intensity"]

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

// Visual brightness of one held or dropped light on this turf. Same curve the static lights use,
// out to the edge of the mask. The flat dynamic_lumcount stamp is not this number.
/proc/sumiari_point_falloff(turf/T, atom/source)
	if(!T || !source || !source.light_on || source.light_power <= 0 || source.light_outer_range <= 0)
		return 0
	if(source.light_system != MOVABLE_LIGHT)
		return 0
	var/turf/origin = get_turf(source)
	if(!origin || origin.z != T.z)
		return 0
	var/range = clamp(CEILING(source.light_outer_range, 0.5), 1, 6)
	var/dx = origin.x - T.x
	var/dy = origin.y - T.y
	if(abs(dx) > range || abs(dy) > range)
		return 0
	var/inner = source.light_inner_range
	if(inner >= range)
		inner = range / 4
	var/divisor = max(range - inner, 1)
	var/dist = sqrt((dx * dx) + (dy * dy) + LIGHTING_HEIGHT)
	var/falloff = CLAMP01((range - dist) / divisor)
	if(source.light_falloff_curve > 0)
		falloff = falloff ** source.light_falloff_curve
	falloff *= source.light_power
	if(istext(source.light_color) && length(source.light_color) >= 7)
		falloff *= sumiari_hex_strength(source.light_color)
	return falloff

/proc/sumiari_movable_brightness(turf/T)
	if(!isturf(T))
		return 0
	var/total = 0
	var/list/seen = list()
	for(var/atom/movable/source in range(6, T))
		if(source.light_system == MOVABLE_LIGHT && source.light_on)
			seen[source] = TRUE
			total += sumiari_point_falloff(T, source)
		if(!ismob(source))
			continue
		for(var/obj/item/item in source.contents)
			if(seen[item] || item.light_system != MOVABLE_LIGHT || !item.light_on)
				continue
			seen[item] = TRUE
			total += sumiari_point_falloff(T, item)
	return total

/proc/sumiari_saturation_at(intensity)
	if(isnull(intensity))
		intensity = 0
	intensity = CLAMP01(intensity)
	// Linear. Halfway from true darkness to a fully lit tile is half color.
	// At full brightness the result is exactly 0, so a lit tile has no tint tail.
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
// Full ink is Rec.709 luma, then a gentle slope and lift. Brightness stays with the sprite.
// glare_override is accepted so old callers still compile. It does not lift or crush:
// that lift was the white fog, because a normal pool is already full-bright on the lighting plane.
// The lighting-plane mask blends color and this gray, so a half-lit pixel is half color.
/proc/sumiari_color_matrix(intensity, glare_override)
	if(isnull(intensity))
		intensity = 0
	var/saturation = sumiari_saturation_at(intensity)
	// Read so the argument stays live. Brightness does not follow it.
	if(glare_override > 1)
		glare_override = 1
	var/scale = SUMIARI_INK_SLOPE
	var/add = SUMIARI_INK_LIFT
	var/constant = (1 - saturation) * add
	// A fully lit tile is exact grayscale. Each output row is identical, so a green or magenta
	// sprite cannot leave one channel higher than the others.
	if(saturation <= 0)
		var/luma_r = scale * SUMIARI_LUMA_R
		var/luma_g = scale * SUMIARI_LUMA_G
		var/luma_b = scale * SUMIARI_LUMA_B
		return list(
			luma_r, luma_r, luma_r, 0,
			luma_g, luma_g, luma_g, 0,
			luma_b, luma_b, luma_b, 0,
			0, 0, 0, 1,
			add, add, add, 0)
	var/ink = 1 - saturation
	var/wr = ink * scale * SUMIARI_LUMA_R
	var/wg = ink * scale * SUMIARI_LUMA_G
	var/wb = ink * scale * SUMIARI_LUMA_B
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
	var/turf/standing = get_turf(C)
	var/list/sample = sumiari_light_sample(standing)
	var/raw = sample["intensity"]
	var/verdict = "off"
	if(sumiari.vision_on)
		var/problems = sumiari_composite_problems(C, sumiari)
		verdict = problems ? "FAIL [problems]" : "PASS"
	var/plane_alpha = "none"
	var/darkness = "none"
	var/atom/movable/screen/plane_master/lighting/lighting = C.hud_used?.plane_masters["[LIGHTING_PLANE]"]
	if(lighting)
		plane_alpha = "[lighting.alpha]"
		if(lighting.render_target == SUMIARI_LIGHTING_SOURCE && lighting.alpha == LIGHTING_PLANE_ALPHA_VISIBLE)
			darkness = "offscreen"
		else if(!lighting.alpha)
			darkness = "blank"
		else if(!sumiari_target_hidden(lighting.render_target))
			darkness = "VISIBLE"
	var/view_text = sumiari_view_coverage(C)
	return "sumiari vision: mob=[C] client=[C.client ? "yes" : "no"] wash=[sumiari.wash_mode] mask=[SUMIARI_LIGHTING_SOURCE] (dyn is not the mask) canvas=[sumiari.mask_pixels_x]x[sumiari.mask_pixels_y] darkness=[darkness] composite=[verdict] pieces=[length(sumiari.screen_pieces)] cap=[SUMIARI_PIECE_CAP] [view_text] [sumiari_ink_debug(C, sumiari)] turf_intensity=[raw] turf_saturation=[sumiari_saturation_at(raw)] turf_glare=[sumiari_glare_at(raw)] organ_see_in_dark=[sumiari.see_in_dark] organ_see_invisible=[sumiari.see_invisible] organ_lighting_alpha=[sumiari.lighting_alpha] mob_see_in_dark=[C.see_in_dark] mob_see_invisible=[C.see_invisible] mob_lighting_alpha=[C.lighting_alpha] lighting_plane_alpha=[plane_alpha] | [sample["text"]]"

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
	var/list/black_noon = sumiari_apply_matrix(sumiari_color_matrix(1, 0), 0, 0, 0)
	var/list/white_noon = sumiari_apply_matrix(sumiari_color_matrix(1, 0), 1, 1, 1)
	var/list/green_noon = sumiari_apply_matrix(sumiari_color_matrix(1, 0), 0, 1, 0)
	var/green_luma = SUMIARI_INK_SLOPE * SUMIARI_LUMA_G + SUMIARI_INK_LIFT
	var/lo_luma = SUMIARI_LUMA_R * 0.12 + SUMIARI_LUMA_G * 0.18 + SUMIARI_LUMA_B * 0.08
	var/hi_luma = SUMIARI_LUMA_R * 0.42 + SUMIARI_LUMA_G * 0.55 + SUMIARI_LUMA_B * 0.30
	var/list/dither_lo = sumiari_apply_matrix(sumiari_color_matrix(1, 0), 0.12, 0.18, 0.08)
	var/list/dither_hi = sumiari_apply_matrix(sumiari_color_matrix(1, 0), 0.42, 0.55, 0.30)
	var/gap_in = hi_luma - lo_luma
	var/gap_out = dither_hi[1] - dither_lo[1]
	var/list/black_half = sumiari_apply_matrix(sumiari_color_matrix(0.5), 0, 0, 0)
	var/half_sat = sumiari_saturation_at(SUMIARI_MONO_FULL * 0.5)
	var/list/green_half = sumiari_apply_matrix(sumiari_color_matrix(SUMIARI_MONO_FULL * 0.5), 0, 1, 0)
	log_world("SUMIARI TEST matrix dark_red=[red_dark[1]],[red_dark[2]],[red_dark[3]] noon_red=[red_noon[1]],[red_noon[2]],[red_noon[3]] noon_black=[black_noon[1]] noon_white=[white_noon[1]] noon_green=[green_noon[1]] green_luma=[green_luma] dither_gap_in=[gap_in] dither_gap_out=[gap_out] half_black=[black_half[1]] sat0=[sumiari_saturation_at(0)] sat_half=[half_sat] sat_full=[sumiari_saturation_at(SUMIARI_MONO_FULL)]")
	log_world("SUMIARI TEST channels red=[sumiari_channel_intensity(1, 0, 0)] white=[sumiari_channel_intensity(1, 1, 1)]")
	if(abs(sumiari_saturation_at(0) - 1) > 0.001 || abs(half_sat - 0.5) > 0.001 || sumiari_saturation_at(SUMIARI_MONO_FULL) != 0 || abs(sumiari_saturation_at(SUMIARI_MONO_FULL * 0.25) - 0.75) > 0.001)
		log_world("SUMIARI TEST FAIL saturation was not a straight line from full color to exactly zero")
	else if(abs(red_dark[1] - 1) > 0.02 || abs(red_dark[2]) > 0.02 || abs(red_dark[3]) > 0.02)
		log_world("SUMIARI TEST FAIL darkness did not stay in color")
	else if(abs(red_noon[1] - red_noon[2]) > 0.001 || abs(red_noon[2] - red_noon[3]) > 0.001)
		log_world("SUMIARI TEST FAIL full light was not colorless")
	else if(abs(green_noon[1] - green_luma) > 0.02 || abs(green_noon[1] - green_noon[2]) > 0.001 || abs(green_noon[2] - green_noon[3]) > 0.001)
		log_world("SUMIARI TEST FAIL ink did not keep Rec.709 luma green=[green_noon[1]],[green_noon[2]],[green_noon[3]] luma=[green_luma]")
	else if(white_noon[1] > 1.001 || black_noon[1] < -0.001 || black_noon[1] > 0.08 || abs(black_half[1] - SUMIARI_INK_LIFT * 0.5) > 0.02)
		log_world("SUMIARI TEST FAIL ink curve thresholded or bloomed white=[white_noon[1]] black=[black_noon[1]] half_black=[black_half[1]]")
	else if(gap_out > gap_in * 1.02 || gap_out < gap_in * 0.9)
		log_world("SUMIARI TEST FAIL ink stretched dither gap_in=[gap_in] gap_out=[gap_out]")
	else if(abs((green_half[2] - green_half[1]) - 0.5) > 0.02)
		log_world("SUMIARI TEST FAIL half darkness was not half color green=[green_half[1]],[green_half[2]],[green_half[3]]")
	else if(abs(sumiari_channel_intensity(1, 0, 0) - sumiari_channel_intensity(1, 1, 1)) > 0.001)
		log_world("SUMIARI TEST FAIL red light did not match white light")
	else if(!sumiari_lit_matrix_is_gray())
		log_world("SUMIARI TEST FAIL lit matrix leaked color")
	else if(!sumiari_mask_math_ok())
		log_world("SUMIARI TEST FAIL lighting-plane mask math")
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
	sumiari_probe_gnoll()
	sumiari_test_without_client = TRUE
	sumiari_runtime_sweep()
	sumiari_test_without_client = FALSE
	log_world("SUMIARI TEST DONE")

// The GPU mask is this formula. Below the glare threshold, blending full color with the no-glare ink
// by that amount matches the saturation matrix, so half light is still half color.
/proc/sumiari_mask_math_ok()
	if(abs(sumiari_light_mask(0, 0, 0, 1)) > 0.001)
		return FALSE
	if(abs(sumiari_light_mask(1, 1, 1, 1) - 1) > 0.001)
		return FALSE
	if(abs(sumiari_light_mask(0.5, 0.5, 0.5, 1) - 0.5) > 0.001)
		return FALSE
	if(abs(sumiari_light_mask(1, 0.2, 0.1, 1) - 1) > 0.001)
		return FALSE
	if(abs(sumiari_light_mask(0.2, 0.2, 0.2, 0) - 1) > 0.001)
		return FALSE
	if(abs(sumiari_light_mask(0, 0, 0, 0.5) - 0.5) > 0.001)
		return FALSE
	if(abs(sumiari_light_mask(0.8, 0.1, 0.1, 0.25) - (1 - 0.25 * (1 - 0.8))) > 0.001)
		return FALSE
	if(abs(sumiari_glare_at(SUMIARI_GLARE_START)) > 0.001 || abs(sumiari_glare_at(1) - 1) > 0.001)
		return FALSE
	if(abs(sumiari_glare_at(0.91) - ((0.91 - SUMIARI_GLARE_START) / (SUMIARI_GLARE_FULL - SUMIARI_GLARE_START))) > 0.02)
		return FALSE
	var/list/glare_matrix = sumiari_matrix_glare_to_alpha()
	var/glare_start = glare_matrix[4] * SUMIARI_GLARE_START + glare_matrix[20]
	var/glare_full = glare_matrix[4] + glare_matrix[20]
	var/night_now = sumiari_night_glare_scale()
	if(abs(glare_start) > 0.02 || abs(glare_full - night_now) > 0.02)
		log_world("SUMIARI TEST glare matrix start=[glare_start] full=[glare_full] night=[night_now]")
		return FALSE
	var/list/day_matrix = sumiari_matrix_glare_to_alpha(1)
	var/list/night_matrix = sumiari_matrix_glare_to_alpha(0)
	var/day_full = day_matrix[4] + day_matrix[20]
	var/night_full = night_matrix[4] + night_matrix[20]
	if(abs(day_full - 1) > 0.02 || abs(night_full - sumiari_night_glare_scale(0)) > 0.02)
		log_world("SUMIARI TEST glare day=[day_full] night=[night_full]")
		return FALSE
	if(abs(sumiari_night_glare_scale(0) - SUMIARI_NIGHT_GLARE_SCALE) > 0.001 && SUMIARI_NIGHT_GLARE)
		return FALSE
	if(abs(sumiari_night_glare_scale(1) - 1) > 0.001)
		return FALSE
	if(length(sumiari_matrix_channel(1)) != 20 || length(sumiari_matrix_gray_to_alpha()) != 20 || length(sumiari_matrix_invert_gray()) != 20)
		return FALSE
	var/list/samples = list(list(1, 0, 0), list(0, 1, 0), list(0.2, 0.7, 0.1), list(0, 0, 0), list(1, 1, 1))
	var/list/ink_matrix = sumiari_color_matrix(SUMIARI_MONO_FULL, 0)
	for(var/intensity in list(0, 0.25, 0.5, SUMIARI_GLARE_START))
		var/list/mixed = sumiari_color_matrix(intensity)
		for(var/list/sample in samples)
			var/list/inked = sumiari_apply_matrix(ink_matrix, sample[1], sample[2], sample[3])
			var/list/via_matrix = sumiari_apply_matrix(mixed, sample[1], sample[2], sample[3])
			for(var/channel in 1 to 3)
				var/lerped = sample[channel] + (inked[channel] - sample[channel]) * intensity
				if(abs(lerped - via_matrix[channel]) > 0.02)
					log_world("SUMIARI TEST blend mismatch intensity=[intensity] channel=[channel] lerped=[lerped] matrix=[via_matrix[channel]]")
					return FALSE
	return TRUE

// Fully lit matrices must turn saturated sprites into one gray. Partial light keeps exactly that much color, no more.
/proc/sumiari_lit_matrix_is_gray()
	for(var/intensity in list(SUMIARI_MONO_FULL, 1))
		var/list/green = sumiari_apply_matrix(sumiari_color_matrix(intensity), 0, 1, 0)
		var/list/magenta = sumiari_apply_matrix(sumiari_color_matrix(intensity), 1, 0.1, 0.85)
		if(abs(green[1] - green[2]) > 0.001 || abs(green[2] - green[3]) > 0.001)
			log_world("SUMIARI TEST leak green intensity=[intensity] out=[green[1]],[green[2]],[green[3]]")
			return FALSE
		if(abs(magenta[1] - magenta[2]) > 0.001 || abs(magenta[2] - magenta[3]) > 0.001)
			log_world("SUMIARI TEST leak magenta intensity=[intensity] out=[magenta[1]],[magenta[2]],[magenta[3]]")
			return FALSE
	return TRUE

/proc/sumiari_log_sample(name, turf/T)
	if(!isturf(T))
		log_world("SUMIARI TEST [name]: missing")
		return
	var/list/sample = sumiari_light_sample(T)
	log_world("SUMIARI TEST [name] sat=[sumiari_saturation_at(sample["intensity"])] [sample["text"]]")

/proc/sumiari_turf_has_light(turf/T)
	for(var/atom/source in range(1, T))
		if(source.light_on && source.light_outer_range > 0 && source.light_power > 0)
			return TRUE
	return FALSE

/proc/sumiari_probe_gnoll()
	var/turf/darkest
	var/dark_value = 2
	var/turf/by_torch
	var/torch_value = -1
	var/turf/mouth
	var/mouth_sun = -1
	var/turf/east_edge
	var/minx = 9999
	var/maxx = 0
	var/miny = 9999
	var/maxy = 0
	var/cave_z = 0
	var/count = 0
	for(var/turf/T in world)
		if(!istype(T.loc, /area/rogue/under/wretch/gnollcavern))
			continue
		if(T.opacity)
			continue
		count++
		cave_z = T.z
		minx = min(minx, T.x)
		maxx = max(maxx, T.x)
		miny = min(miny, T.y)
		maxy = max(maxy, T.y)
		if(T.x >= maxx)
			east_edge = T
		var/list/sample = sumiari_light_sample(T)
		var/value = sample["intensity"]
		if(value < dark_value)
			dark_value = value
			darkest = T
		if(sumiari_turf_has_light(T) && value > torch_value)
			torch_value = value
			by_torch = T
		var/open_sky = T.outdoor_effect && T.outdoor_effect.state != SKY_BLOCKED
		if((open_sky || sample["sun"] > 0) && sample["sun"] >= mouth_sun)
			mouth_sun = sample["sun"]
			mouth = T
	log_world("SUMIARI TEST gnoll open_turfs=[count] z=[cave_z] bounds=[minx],[miny]-[maxx],[maxy]")
	sumiari_log_sample("gnoll_dark", darkest)
	sumiari_log_sample("gnoll_torch", by_torch)
	sumiari_log_sample("gnoll_mouth", mouth)
	sumiari_log_sample("gnoll_east_edge", east_edge)
	var/turf/sunny
	var/sunny_value = -1
	if(cave_z && maxx)
		var/east_x = min(world.maxx, maxx + 40)
		for(var/turf/east in block(locate(maxx + 1, miny, cave_z), locate(east_x, maxy, cave_z)))
			if(!isturf(east) || east.opacity)
				continue
			if(istype(east.loc, /area/rogue/under/wretch/gnollcavern))
				continue
			if(east.outdoor_effect?.state != SKY_VISIBLE && east.has_dynamic_lighting())
				continue
			var/value = sumiari_turf_intensity(east)
			if(value > sunny_value)
				sunny_value = value
				sunny = east
	sumiari_log_sample("sunny_east", sunny)
	if(!darkest)
		log_world("SUMIARI TEST FAIL gnoll cavern had no open turf")
		return
	if(dark_value > 0.05)
		log_world("SUMIARI TEST FAIL gnoll dark interior intensity=[dark_value] (wanted about 0)")
	else
		log_world("SUMIARI TEST gnoll dark PASS intensity=[dark_value]")
	if(by_torch)
		var/torch_sat = sumiari_saturation_at(torch_value)
		log_world("SUMIARI TEST gnoll torch intensity=[torch_value] sat=[torch_sat]")
	if(sunny && sunny_value < 0.95)
		log_world("SUMIARI TEST FAIL sunny east intensity=[sunny_value]")
	else if(sunny)
		log_world("SUMIARI TEST sunny east PASS intensity=[sunny_value]")
	sumiari_probe_torch_falloff(darkest)

// Drop a torch on the darkest cavern tile and record the fade one step at a time.
/proc/sumiari_probe_torch_falloff(turf/origin)
	if(!isturf(origin))
		return
	var/obj/item/flashlight/flare/torch/torch = new(origin)
	torch.on = TRUE
	torch.update_brightness()
	for(var/step in 0 to 6)
		var/turf/step_turf = locate(origin.x + step, origin.y, origin.z)
		if(!isturf(step_turf))
			log_world("SUMIARI TEST torch_step_[step]: missing")
			continue
		var/list/sample = sumiari_light_sample(step_turf)
		log_world("SUMIARI TEST torch_step_[step] sat=[sumiari_saturation_at(sample["intensity"])] intensity=[sample["intensity"]] movable=[sample["text"]]")
	qdel(torch)

/client/proc/sumiari_vision_debug()
	set category = "Debug"
	set name = "Sumiari Vision Debug"
	set desc = "Log Sumiari eyes and the light on one turf. The picture follows the lighting plane, not that one number."
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

// Forces the ink relay to cover the whole view, or to add nothing, so each path can be seen on its own.
/client/proc/sumiari_wash_test()
	set category = "Debug"
	set name = "Sumiari Wash Test"
	set desc = "Force the Sumiari ink wash on for the whole view, off, or back to the lighting mask."
	if(!holder)
		return
	var/mob/living/carbon/who = mob
	if(!iscarbon(who) && iscarbon(eye))
		who = eye
	var/obj/item/organ/eyes/sumiari/eyes = who?.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes) || !eyes.vision_on)
		to_chat(src, "This body has no live Sumiari wash.")
		return
	var/live = "Live mask (ink only where the lighting plane is bright)"
	var/forced_ink = "Force ink (mask = 1, whole view is ink)"
	var/forced_color = "Force color (mask = 0, world planes stay in color)"
	var/choice = input(src, "Which wash?", "Sumiari Wash Test") as null|anything in list(live, forced_ink, forced_color)
	if(!choice)
		return
	if(choice == forced_ink)
		eyes.wash_mode = SUMIARI_WASH_INK
	else if(choice == forced_color)
		eyes.wash_mode = SUMIARI_WASH_COLOR
	else
		eyes.wash_mode = SUMIARI_WASH_LIVE
	eyes.apply_wash_filters()
	var/expect = "Lit sprites, including the thing that is glowing, turn gray at about their own brightness. The pool is not a white fog. Darkness keeps the sprite color. The HUD stays in color. No green or orange cast."
	if(eyes.wash_mode == SUMIARI_WASH_INK)
		expect = "Every world sprite is a gray of its own brightness: grass stays as light as it was, shading stays shading, and textures do not turn into white specks on black. Darkness is that same gray, not a black void and not the sprite color. The HUD, chat, and stat panel stay in color."
	else if(eyes.wash_mode == SUMIARI_WASH_COLOR)
		expect = "Every world sprite keeps its own color, lit or not. No ink, and no green or orange light cast. The HUD stays in color."
	var/line = "sumiari wash test: mode=[eyes.wash_mode] [expect] [sumiari_ink_debug(who, eyes)] [sumiari_plane_legend()]"
	log_world(line)
	to_chat(src, line)

// Which object carries which picture. The wash test prints this so it can be checked against the screen.
/proc/sumiari_plane_legend()
	return "planes: world color is the map planes themselves (sumiari_w*, no asterisk, drawn). Lighting plane [LIGHTING_PLANE] is [SUMIARI_LIGHTING_SOURCE] alpha 255, not drawn, and is the only mask input. Movable-light plane [O_LIGHTING_VISUAL_PLANE] is [SUMIARI_OLIGHT_SOURCE] alpha 255, not drawn; it punches that capture and does not tint the world. Mask plates [SUMIARI_PLANE_RED] to [SUMIARI_PLANE_GLARE] copy that capture at view resolution (render_source, SCREEN_SOUTHWEST, no 32×32 resample) into [sumiari_offscreen(SUMIARI_TARGET_MASK)]. Live ink is filters on plane [SUMIARI_INK_PLANE]: those world captures, the ink matrix, then [sumiari_offscreen(SUMIARI_TARGET_MASK)]. Force ink is the ink matrix on every world plane master and does not sample a relay. HUD is plane [HUD_PLANE]."

// in_screen, plane, render_source, alpha, and whether that plane's master exists. One block for the live stack, one for the force-ink matrix.
/proc/sumiari_ink_debug(mob/living/carbon/C, obj/item/organ/eyes/sumiari/eyes)
	var/ink_plane = C?.hud_used?.plane_masters?["[SUMIARI_INK_PLANE]"]
	var/floor_plane = C?.hud_used?.plane_masters?["[FLOOR_PLANE]"]
	var/matrices = 0
	var/planes = 0
	for(var/plane in GLOB.sumiari_vision_plane_order)
		planes++
		if(sumiari_master_has_ink_matrix(C?.hud_used?.plane_masters?["[plane]"]))
			matrices++
	return "ink_filter live=[sumiari_carrier_debug(C, ink_plane, "above")] force=[sumiari_carrier_debug(C, floor_plane, "floor")] world_matrices=[matrices]/[planes] glare=[sumiari_carrier_debug(C, sumiari_find_piece(eyes, "sumiari glare"), "glare")]"

/proc/sumiari_carrier_debug(mob/living/carbon/C, atom/movable/screen/thing, label)
	var/in_screen = "no"
	if(C?.client && thing && (thing in C.client.screen))
		in_screen = "yes"
	var/source = "none"
	var/mask = "none"
	var/kind = "none"
	if(thing?.filters)
		for(var/sample in thing.filters)
			var/listed = list(sample)
			var/render_source = sumiari_filter_field(listed, 1, "render_source")
			if(sumiari_filter_is_full_ink(sample))
				kind = (kind == "layer") ? "layer+color" : "color"
				if(source == "none")
					source = "matrix"
			if(!render_source)
				continue
			if(render_source == sumiari_offscreen(SUMIARI_TARGET_MASK) || render_source == sumiari_offscreen(SUMIARI_TARGET_GLARE))
				mask = render_source
				continue
			for(var/plane in GLOB.sumiari_vision_plane_order)
				if(render_source != sumiari_world_render_source(plane))
					continue
				kind = (kind == "color") ? "layer+color" : "layer"
				if(source == "none" || source == "matrix")
					source = render_source
				break
	var/master = C?.hud_used?.plane_masters?["[thing?.plane]"]
	return "[label]{in_screen=[in_screen] plane=[isnull(thing?.plane) ? "none" : thing.plane] alpha=[isnull(thing?.alpha) ? "none" : thing.alpha] master=[master ? "yes" : "no"] kind=[kind] source=[source] mask=[mask]}"

/proc/sumiari_master_has_ink_matrix(atom/movable/screen/plane_master/master)
	if(!master?.filters)
		return FALSE
	for(var/sample in master.filters)
		if(sumiari_filter_is_full_ink(sample))
			return TRUE
	return FALSE

/proc/sumiari_master_layer_source(atom/movable/screen/plane_master/master)
	if(!master?.filters)
		return
	for(var/sample in master.filters)
		var/render_source = sumiari_filter_field(list(sample), 1, "render_source")
		for(var/plane in GLOB.sumiari_vision_plane_order)
			if(render_source == sumiari_world_render_source(plane))
				return render_source

// see_in_dark against the client view. A 15x15 view has radius 7, so 8 covers every tile. Walls still block.
/proc/sumiari_view_coverage(mob/living/carbon/C)
	var/view = C?.client?.view || world.view
	var/list/size = getviewsize(view)
	var/radius = (max(size[1], size[2]) - 1) / 2
	var/covers = C?.see_in_dark >= radius
	return "view=[view] radius=[radius] see_in_dark=[C?.see_in_dark] covers_view=[covers ? "yes" : "NO"]"

// Builds and tears down the composite without a client. The picture itself still needs a player to look at.
/proc/sumiari_runtime_sweep()
	log_world("SUMIARI TEST sweep begin live=[sumiari_screen_live] sun=[sumiari_sun_strength()] night_glare=[sumiari_night_glare_scale()]")
	var/failed = FALSE
	var/legendary_sneak = SEE_INVISIBLE_LIVING + (5 * 0.55) + 1
	if(SUMIARI_SEE_INVISIBLE <= legendary_sneak || SUMIARI_SEE_INVISIBLE >= SEE_INVISIBLE_OBSERVER)
		log_world("SUMIARI TEST FAIL sneak sight [SUMIARI_SEE_INVISIBLE] vs legendary [legendary_sneak]")
		failed = TRUE
	else
		log_world("SUMIARI TEST sneak PASS see_invisible=[SUMIARI_SEE_INVISIBLE] legendary=[legendary_sneak]")
	var/list/trash = list()
	var/turf/origin = locate(20, 20, 1)
	if(!isturf(origin))
		log_world("SUMIARI TEST FAIL sweep had no turf")
		return
	var/mob/living/carbon/human/body = new(origin)
	trash += body
	body.set_species(/datum/species/human/northern)
	var/obj/item/organ/eyes/sumiari/eyes = body.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes))
		log_world("SUMIARI TEST FAIL sweep mob had no sumiari eyes")
		sumiari_sweep_dispose(trash)
		return
	body.hud_used = new body.hud_type(body)
	eyes.attach_client_vision()
	var/pieces = sumiari_screen_live
	log_world("SUMIARI TEST sweep attached vision_on=[eyes.vision_on] pieces=[pieces] glare=[eyes.glare_plate ? "yes" : "no"] cap=[SUMIARI_PIECE_CAP]")
	if(!eyes.vision_on || pieces <= 0 || !eyes.glare_plate)
		log_world("SUMIARI TEST FAIL composite did not build")
		failed = TRUE
	if(!sumiari_sweep_planes_captured(body))
		failed = TRUE
	var/atom/movable/screen/plane_master/openspace = body.hud_used.plane_masters["[OPENSPACE_BACKDROP_PLANE]"]
	var/openspace_blend = sumiari_scene_blend(eyes, OPENSPACE_BACKDROP_PLANE)
	if(!openspace || openspace_blend != openspace.blend_mode)
		log_world("SUMIARI TEST FAIL openspace scene blend=[openspace_blend] master=[openspace?.blend_mode]")
		failed = TRUE
	else
		log_world("SUMIARI TEST openspace PASS blend=[openspace.blend_mode]")
	if(!sumiari_sweep_wash(eyes))
		failed = TRUE
#if SUMIARI_MOON_TINT
	var/found_moon = FALSE
	for(var/atom/movable/screen/piece as anything in eyes.screen_pieces)
		if(piece.name == "sumiari moon")
			found_moon = TRUE
	if(!found_moon)
		log_world("SUMIARI TEST FAIL moon tint relay missing")
		failed = TRUE
	else
		log_world("SUMIARI TEST flourish PASS moon")
#endif
#if SUMIARI_INK_VIGNETTE
	var/found_vignette = FALSE
	for(var/atom/movable/screen/piece as anything in eyes.screen_pieces)
		if(istype(piece, /atom/movable/screen/sumiari_vignette))
			found_vignette = TRUE
	if(!found_vignette)
		log_world("SUMIARI TEST FAIL ink vignette missing")
		failed = TRUE
	else
		log_world("SUMIARI TEST flourish PASS vignette")
#endif
	eyes.attach_client_vision()
	if(sumiari_screen_live != pieces)
		log_world("SUMIARI TEST FAIL second attach leaked [sumiari_screen_live] vs [pieces]")
		failed = TRUE
	eyes.refresh_time_filters()
	sumiari_on_sun_changed()
	if(sumiari_screen_live != pieces)
		log_world("SUMIARI TEST FAIL sun refresh changed piece count")
		failed = TRUE
	var/turf/elsewhere = sumiari_sweep_other_z(origin)
	if(!elsewhere)
		log_world("SUMIARI TEST FAIL no other z")
		failed = TRUE
	else
		body.forceMove(elsewhere)
		if(!eyes.vision_on || sumiari_screen_live != pieces || !sumiari_sweep_planes_captured(body))
			log_world("SUMIARI TEST FAIL z-change vision_on=[eyes.vision_on] pieces=[sumiari_screen_live]")
			failed = TRUE
		else
			log_world("SUMIARI TEST z-change PASS z=[elsewhere.z] pieces=[sumiari_screen_live]")
		body.forceMove(origin)
	var/list/lights = list()
	for(var/i in 1 to 24)
		var/obj/item/flashlight/flare/torch/torch = new(origin)
		torch.on = TRUE
		torch.update_brightness()
		lights += torch
		trash += torch
	if(sumiari_screen_live != pieces)
		log_world("SUMIARI TEST FAIL lights changed piece count to [sumiari_screen_live]")
		failed = TRUE
	else
		log_world("SUMIARI TEST lights PASS count=24 pieces=[pieces]")
	for(var/obj/item/flashlight/flare/torch/torch as anything in lights)
		qdel(torch)
		trash -= torch
	if(!sumiari_sweep_blindness(body, eyes))
		failed = TRUE
	if(eyes.vision_on && sumiari_screen_live == pieces)
		log_world("SUMIARI TEST blindness kept composite PASS")
	else
		log_world("SUMIARI TEST FAIL blindness tore the composite down")
		failed = TRUE
	body.death(FALSE, TRUE)
	var/atom/movable/screen/plane_master/color_sample = body.hud_used.plane_masters["[SUMIARI_INK_PLANE]"]
	var/colour_reaches = color_sample && !(color_sample.appearance_flags & NO_CLIENT_COLOR)
	if(body.stat != DEAD || !istype(body.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/sumiari) || !eyes.vision_on)
		log_world("SUMIARI TEST FAIL death stat=[body.stat] eyes=[body.getorganslot(ORGAN_SLOT_EYES)?.type] vision_on=[eyes.vision_on]")
		failed = TRUE
	else if(!colour_reaches)
		log_world("SUMIARI TEST FAIL death monochrome cannot reach the wash")
		failed = TRUE
	else
		log_world("SUMIARI TEST death PASS eyes kept, composite kept, wash plane takes client colour")
	body.revive(TRUE, TRUE)
	var/still_mono = FALSE
	for(var/datum/client_colour/monochrome/mono in body.client_colours)
		still_mono = TRUE
	if(body.stat == DEAD || still_mono || !istype(body.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/sumiari))
		log_world("SUMIARI TEST FAIL revive stat=[body.stat] mono=[still_mono] eyes=[body.getorganslot(ORGAN_SLOT_EYES)?.type]")
		failed = TRUE
	else
		log_world("SUMIARI TEST revive PASS")
	eyes = body.getorganslot(ORGAN_SLOT_EYES)
	SEND_SIGNAL(body, COMSIG_MOB_LOGOUT)
	if(eyes.vision_on || sumiari_screen_live != 0 || !sumiari_sweep_planes_restored(body))
		log_world("SUMIARI TEST FAIL logout vision_on=[eyes.vision_on] live=[sumiari_screen_live]")
		failed = TRUE
	else
		log_world("SUMIARI TEST logout PASS planes restored live=0")
	SEND_SIGNAL(body, COMSIG_MOB_LOGIN)
	if(!eyes.vision_on || !sumiari_sweep_planes_captured(body))
		log_world("SUMIARI TEST FAIL reenter did not rebuild")
		failed = TRUE
	else
		log_world("SUMIARI TEST reenter PASS pieces=[sumiari_screen_live]")
	var/mob/living/carbon/human/vessel = new(origin)
	trash += vessel
	vessel.set_species(/datum/species/elf/dark)
	vessel.hud_used = new vessel.hud_type(vessel)
	var/datum/mind/mind = new
	mind.active = TRUE
	mind.transfer_to(body)
	mind.transfer_to(vessel, TRUE)
	if(istype(vessel.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/sumiari))
		log_world("SUMIARI TEST FAIL mind transfer gave the other body sumiari eyes")
		failed = TRUE
	SEND_SIGNAL(body, COMSIG_MOB_LOGOUT)
	SEND_SIGNAL(vessel, COMSIG_MOB_LOGIN)
	if(eyes.vision_on || sumiari_screen_live != 0)
		log_world("SUMIARI TEST FAIL mind leave kept the composite live=[sumiari_screen_live]")
		failed = TRUE
	else
		log_world("SUMIARI TEST mind transfer PASS donor released, recipient has [vessel.getorganslot(ORGAN_SLOT_EYES)?.type || "none"]")
	SEND_SIGNAL(body, COMSIG_MOB_LOGIN)
	if(!eyes.vision_on)
		log_world("SUMIARI TEST FAIL return to the sumiari body did not attach")
		failed = TRUE
	qdel(mind)
	var/mob/dead/observer/admin/ghost = new(origin)
	trash += ghost
	var/admin_ghost_sight = ghost.see_invisible
	if(iscarbon(ghost) || admin_ghost_sight < SEE_INVISIBLE_OBSERVER)
		log_world("SUMIARI TEST FAIL aghost sight=[admin_ghost_sight]")
		failed = TRUE
	else
		log_world("SUMIARI TEST aghost PASS ghost sight=[admin_ghost_sight] body releases on logout")
	var/removed_invisible = initial(body.see_invisible)
	eyes.Remove(body)
	if(body.getorganslot(ORGAN_SLOT_EYES) || sumiari_screen_live != 0 || !sumiari_sweep_planes_restored(body))
		log_world("SUMIARI TEST FAIL eye removal live=[sumiari_screen_live] eyes=[body.getorganslot(ORGAN_SLOT_EYES)?.type]")
		failed = TRUE
	else if(body.see_invisible != removed_invisible && body.see_invisible != initial(body.see_invisible))
		log_world("SUMIARI TEST FAIL eye removal see_invisible=[body.see_invisible]")
		failed = TRUE
	else
		log_world("SUMIARI TEST eye removal PASS see_invisible=[body.see_invisible]")
	var/obj/item/organ/eyes/sumiari/replaced = new
	replaced.Insert(body)
	if(!istype(body.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/sumiari) || !replaced.vision_on)
		log_world("SUMIARI TEST FAIL eye replacement vision_on=[replaced.vision_on]")
		failed = TRUE
	else
		log_world("SUMIARI TEST eye replacement PASS pieces=[sumiari_screen_live]")
	eyes = replaced
	var/before_species = sumiari_screen_live
	body.set_species(/datum/species/elf/dark)
	var/datum/organ_dna/after_elf = body.dna?.organ_dna?[ORGAN_SLOT_EYES]
	if(istype(body.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/sumiari) || after_elf?.organ_type == /obj/item/organ/eyes/sumiari || sumiari_screen_live != 0)
		log_world("SUMIARI TEST FAIL species leave eyes=[body.getorganslot(ORGAN_SLOT_EYES)?.type] dna=[after_elf?.organ_type] live=[sumiari_screen_live]")
		failed = TRUE
	else if(!sumiari_sweep_planes_restored(body))
		log_world("SUMIARI TEST FAIL species leave left planes captured")
		failed = TRUE
	else
		log_world("SUMIARI TEST species leave PASS eyes=[body.getorganslot(ORGAN_SLOT_EYES)?.type] was_pieces=[before_species]")
	body.set_species(/datum/species/human/northern)
	eyes = body.getorganslot(ORGAN_SLOT_EYES)
	var/datum/organ_dna/back = body.dna?.organ_dna?[ORGAN_SLOT_EYES]
	if(!istype(eyes, /obj/item/organ/eyes/sumiari) || back?.organ_type != /obj/item/organ/eyes/sumiari)
		log_world("SUMIARI TEST FAIL species return eyes=[eyes?.type] dna=[back?.organ_type]")
		failed = TRUE
	else
		log_world("SUMIARI TEST species return PASS")
	var/crowd_before = sumiari_screen_live
	var/start = world.timeofday
	for(var/i in 1 to 8)
		var/mob/living/carbon/human/extra = new(origin)
		extra.set_species(/datum/species/human/northern)
		extra.hud_used = new extra.hud_type(extra)
		var/obj/item/organ/eyes/sumiari/extra_eyes = extra.getorganslot(ORGAN_SLOT_EYES)
		extra_eyes.attach_client_vision()
		extra_eyes.release_client_vision(extra)
		var/datum/hud/extra_hud = extra.hud_used
		extra.hud_used = null
		qdel(extra_hud)
		qdel(extra)
	var/elapsed = world.timeofday - start
	if(elapsed < 0)
		elapsed += 864000
	if(sumiari_screen_live != crowd_before)
		log_world("SUMIARI TEST FAIL crowd leaked live=[sumiari_screen_live] before=[crowd_before] time=[elapsed]")
		failed = TRUE
	else
		log_world("SUMIARI TEST crowd PASS bodies=8 time_ds=[elapsed] live=[sumiari_screen_live]")
	sumiari_sweep_dispose(trash)
	if(sumiari_screen_live != 0 || length(sumiari_active_eyes))
		log_world("SUMIARI TEST FAIL sweep leftover live=[sumiari_screen_live] active=[length(sumiari_active_eyes)]")
		failed = TRUE
	if(failed)
		log_world("SUMIARI TEST sweep FAIL")
	else
		log_world("SUMIARI TEST sweep PASS")

/proc/sumiari_sweep_planes_captured(mob/living/carbon/body)
	var/obj/item/organ/eyes/sumiari/eyes = body?.getorganslot(ORGAN_SLOT_EYES)
	var/problems = sumiari_composite_problems(body, eyes)
	if(problems)
		log_world("SUMIARI TEST FAIL composite [problems]")
		return FALSE
	var/atom/movable/screen/plane_master/lighting/lighting = body.hud_used.plane_masters["[LIGHTING_PLANE]"]
	var/atom/movable/screen/plane_master/cookie = body.hud_used.plane_masters["[O_LIGHTING_VISUAL_PLANE]"]
	log_world("SUMIARI TEST darkness PASS plane_alpha=[lighting.alpha] target=[lighting.render_target] olight=[cookie?.render_target] world_hidden=0 pieces=[length(eyes.screen_pieces)] mask=[SUMIARI_LIGHTING_SOURCE] canvas=[eyes.mask_pixels_x]x[eyes.mask_pixels_y] dyn_not_used=1")
	return TRUE

// Null when the lighting capture is full and hidden, the world is still drawn, and the color cookies are not.
// Alpha 0 blanks *lighting. A target without an asterisk draws the darkness or the color tint.
/proc/sumiari_composite_problems(mob/living/carbon/body, obj/item/organ/eyes/sumiari/eyes)
	if(!istype(eyes) || !eyes.vision_on)
		return "vision off"
	if(!body?.hud_used)
		return "no hud"
	var/list/bad = list()
	if(eyes.lighting_alpha != LIGHTING_PLANE_ALPHA_VISIBLE)
		bad += "organ_lighting_alpha=[eyes.lighting_alpha] capture not full"
	if(body.lighting_alpha != LIGHTING_PLANE_ALPHA_VISIBLE)
		bad += "mob_lighting_alpha=[body.lighting_alpha] capture not full"
	var/atom/movable/screen/plane_master/lighting/lighting = body.hud_used.plane_masters["[LIGHTING_PLANE]"]
	if(!lighting)
		bad += "no lighting plane"
	else
		if(lighting.alpha != LIGHTING_PLANE_ALPHA_VISIBLE)
			bad += "lighting_plane_alpha=[lighting.alpha] capture scaled"
		if(lighting.render_target != SUMIARI_LIGHTING_SOURCE)
			bad += "lighting_target=[lighting.render_target || "null"]"
		if(!sumiari_target_hidden(lighting.render_target))
			bad += "lighting drawn"
		var/punch = sumiari_filter_field(lighting.filters, 3, "render_source")
		if(punch != SUMIARI_OLIGHT_SOURCE)
			bad += "lighting punch=[punch || "none"]"
	var/atom/movable/screen/plane_master/cookie = body.hud_used.plane_masters["[O_LIGHTING_VISUAL_PLANE]"]
	if(!cookie || cookie.render_target != SUMIARI_OLIGHT_SOURCE || cookie.alpha != LIGHTING_PLANE_ALPHA_VISIBLE)
		bad += "o_light target=[cookie?.render_target || "none"] alpha=[cookie?.alpha] color cast drawn"
	var/hidden_world = 0
	for(var/plane in GLOB.sumiari_vision_plane_order)
		var/atom/movable/screen/plane_master/master = body.hud_used.plane_masters["[plane]"]
		if(!master)
			bad += "plane [plane] missing"
			continue
		if(sumiari_target_hidden(master.render_target))
			hidden_world++
			bad += "plane [plane] hidden"
		else if(master.render_target != sumiari_world_render_target(plane))
			bad += "plane [plane] uncaptured ([master.render_target || "null"])"
	if(hidden_world)
		bad += "world missing"
	if(length(eyes.screen_pieces) > SUMIARI_PIECE_CAP)
		bad += "pieces=[length(eyes.screen_pieces)] over cap [SUMIARI_PIECE_CAP]"
	var/atom/movable/screen/sumiari_plate/red = sumiari_find_piece(eyes, SUMIARI_TARGET_RED)
	var/atom/movable/screen/sumiari_sampler/red_sample = sumiari_find_piece(eyes, "[SUMIARI_TARGET_RED] sample")
	if(!red || red.render_target != sumiari_offscreen(SUMIARI_TARGET_RED))
		bad += "mask plate=[red?.render_target || "none"]"
	else if(red.plane >= OPENSPACE_PLANE)
		bad += "mask plate plane [red.plane] can cover the map"
	if(length(red?.filters))
		bad += "mask filters on the plate master"
	if(!red_sample || (red_sample.appearance_flags & PLANE_MASTER))
		bad += "mask sampler missing"
	// The lighting plane is the atom's render_source. A layer filter here would resample it onto the icon.
	if(red_sample && red_sample.render_source != SUMIARI_LIGHTING_SOURCE)
		bad += "mask_source=[red_sample.render_source || "none"]"
	if(red_sample && red_sample.screen_loc != "SCREEN_SOUTHWEST")
		bad += "mask anchor=[red_sample.screen_loc || "none"]"
	var/list/span = sumiari_mask_span(body?.client?.view)
	if(!red_sample || red_sample.sumiari_pixels_x != span[1] || red_sample.sumiari_pixels_y != span[2])
		bad += "mask canvas=[red_sample?.sumiari_pixels_x]x[red_sample?.sumiari_pixels_y] view=[span[1]]x[span[2]]"
	if(red_sample && length(red_sample.filters))
		if(sumiari_filter_kind(red_sample.filters[1]) == "layer")
			bad += "mask resamples through a layer filter"
	var/atom/movable/screen/plane_master/ink_master = body.hud_used.plane_masters["[SUMIARI_INK_PLANE]"]
	if(!ink_master)
		bad += "no ink plane"
	else if(ink_master.appearance_flags & NO_CLIENT_COLOR)
		bad += "ink plane blocks client colour"
	var/matrix_planes = 0
	var/present = 0
	var/stacked = 0
	for(var/plane in GLOB.sumiari_vision_plane_order)
		var/atom/movable/screen/plane_master/master = body.hud_used.plane_masters["[plane]"]
		if(!master)
			continue
		present++
		var/has_matrix = sumiari_master_has_ink_matrix(master)
		var/has_layer = sumiari_master_layer_source(master)
		if(has_matrix)
			matrix_planes++
		if(has_layer)
			stacked++
		if(eyes.wash_mode == SUMIARI_WASH_LIVE && plane != SUMIARI_INK_PLANE && (has_matrix || has_layer))
			bad += "live wash leaked onto plane [plane]"
		if(eyes.wash_mode == SUMIARI_WASH_INK && has_layer)
			bad += "force ink still stacks plane [plane]"
		if(eyes.wash_mode == SUMIARI_WASH_COLOR && (has_matrix || has_layer))
			bad += "force color still filters plane [plane]"
	var/atom/movable/screen/sumiari_relay/glare = sumiari_find_piece(eyes, "sumiari glare")
	if(eyes.wash_mode == SUMIARI_WASH_INK)
		if(matrix_planes != present)
			bad += "matrices=[matrix_planes]/[present]"
		if(stacked)
			bad += "force ink stacked=[stacked]"
		if(glare?.alpha)
			bad += "force ink glare alpha=[glare.alpha]"
	else if(eyes.wash_mode == SUMIARI_WASH_COLOR)
		if(matrix_planes || stacked)
			bad += "force color matrices=[matrix_planes] stacked=[stacked]"
		if(glare?.alpha)
			bad += "force color glare alpha=[glare.alpha]"
	else
		if(!sumiari_master_layer_source(ink_master))
			bad += "live stack missing"
		var/live_mask = null
		for(var/sample in ink_master?.filters)
			if(sumiari_filter_field(list(sample), 1, "render_source") == sumiari_offscreen(SUMIARI_TARGET_MASK))
				live_mask = sumiari_offscreen(SUMIARI_TARGET_MASK)
		if(live_mask != sumiari_offscreen(SUMIARI_TARGET_MASK))
			bad += "live mask missing"
#if SUMIARI_NIGHT_GLARE
		if(!glare || glare.alpha != 255)
			bad += "glare alpha=[glare?.alpha]"
		else if(glare.appearance_flags & NO_CLIENT_COLOR)
			bad += "glare blocks client colour"
		else if(glare.plane <= LIGHTING_PLANE)
			bad += "glare under the lighting plane"
		else if(sumiari_filter_field(glare.filters, length(glare.filters), "render_source") != sumiari_offscreen(SUMIARI_TARGET_GLARE))
			bad += "glare mask missing"
#endif
	if(!length(bad))
		return null
	return bad.Join("; ")

/proc/sumiari_target_hidden(target)
	return copytext("[target]", 1, 2) == "*"

/proc/sumiari_filter_field(list/plate_filters, index, field)
	if(!islist(plate_filters) || length(plate_filters) < index)
		return
	var/sample = plate_filters[index]
	var/kind = sumiari_filter_kind(sample)
	if(field == "render_source")
		if(kind != "layer" && kind != "alpha")
			return
		return sample:render_source
	if(field == "blend_mode")
		if(kind != "layer")
			return
		return sample:blend_mode

/proc/sumiari_find_piece(obj/item/organ/eyes/sumiari/eyes, piece_name)
	for(var/atom/movable/screen/piece as anything in eyes?.screen_pieces)
		if(piece.name == piece_name)
			return piece

/proc/sumiari_scene_blend(obj/item/organ/eyes/sumiari/eyes, plane)
	var/atom/movable/screen/plane_master/scene = eyes?.owner?.hud_used?.plane_masters["[SUMIARI_INK_PLANE]"]
	if(!length(scene?.filters))
		return "missing"
	var/wanted = sumiari_world_render_source(plane)
	for(var/sample in scene.filters)
		if(sumiari_filter_field(list(sample), 1, "render_source") == wanted)
			return sumiari_filter_field(list(sample), 1, "blend_mode")
	return "missing"

/proc/sumiari_sweep_planes_restored(mob/living/carbon/body)
	if(!body?.hud_used)
		return FALSE
	for(var/plane in GLOB.sumiari_vision_plane_order)
		var/atom/movable/screen/plane_master/master = body.hud_used.plane_masters["[plane]"]
		if(!master)
			continue
		if(master.render_target == sumiari_world_render_target(plane))
			log_world("SUMIARI TEST FAIL plane [plane] still captured")
			return FALSE
		if(sumiari_master_has_ink_matrix(master) || sumiari_master_layer_source(master))
			log_world("SUMIARI TEST FAIL plane [plane] still washed")
			return FALSE
	var/atom/movable/screen/plane_master/lighting/lighting = body.hud_used.plane_masters["[LIGHTING_PLANE]"]
	if(lighting && lighting.render_target != "lighting")
		log_world("SUMIARI TEST FAIL lighting target=[lighting.render_target]")
		return FALSE
	var/punch = sumiari_filter_field(lighting?.filters, 3, "render_source")
	if(punch != O_LIGHTING_VISUAL_RENDER_TARGET)
		log_world("SUMIARI TEST FAIL lighting punch=[punch || "none"]")
		return FALSE
	var/atom/movable/screen/plane_master/cookie = body.hud_used.plane_masters["[O_LIGHTING_VISUAL_PLANE]"]
	if(cookie && cookie.render_target != O_LIGHTING_VISUAL_RENDER_TARGET)
		log_world("SUMIARI TEST FAIL o_light still [cookie.render_target]")
		return FALSE
	return TRUE

/proc/sumiari_sweep_wash(obj/item/organ/eyes/sumiari/eyes)
	eyes.wash_mode = SUMIARI_WASH_INK
	eyes.apply_wash_filters()
	var/ink_problems = sumiari_composite_problems(eyes.owner, eyes)
	if(ink_problems)
		log_world("SUMIARI TEST FAIL wash ink [ink_problems]")
		eyes.wash_mode = SUMIARI_WASH_LIVE
		eyes.apply_wash_filters()
		return FALSE
	eyes.wash_mode = SUMIARI_WASH_COLOR
	eyes.apply_wash_filters()
	var/color_problems = sumiari_composite_problems(eyes.owner, eyes)
	if(color_problems)
		log_world("SUMIARI TEST FAIL wash color [color_problems]")
		eyes.wash_mode = SUMIARI_WASH_LIVE
		eyes.apply_wash_filters()
		return FALSE
	eyes.wash_mode = SUMIARI_WASH_LIVE
	eyes.apply_wash_filters()
	var/live_problems = sumiari_composite_problems(eyes.owner, eyes)
	if(live_problems)
		log_world("SUMIARI TEST FAIL wash live [live_problems]")
		return FALSE
	log_world("SUMIARI TEST wash PASS ink color live")
	return TRUE

/proc/sumiari_sweep_other_z(turf/here)
	if(!isturf(here))
		return
	for(var/z in 1 to world.maxz)
		if(z == here.z)
			continue
		var/turf/there = locate(here.x, here.y, z)
		if(isturf(there))
			return there

/proc/sumiari_sweep_blindness(mob/living/carbon/human/body, obj/item/organ/eyes/sumiari/eyes)
	body.become_blind("sumiari_sweep")
	var/atom/movable/screen/fullscreen/blind_overlay = body.screens["blind"]
	if(!blind_overlay || blind_overlay.plane <= SUMIARI_RELAY_PLANE || sumiari_plane_is_world(blind_overlay.plane))
		log_world("SUMIARI TEST FAIL blind overlay plane=[blind_overlay?.plane]")
		body.cure_blind("sumiari_sweep")
		return FALSE
	body.cure_blind("sumiari_sweep")
	if(body.screens["blind"])
		log_world("SUMIARI TEST FAIL blind overlay stayed after cure")
		return FALSE
	body.stat = UNCONSCIOUS
	body.update_blindness()
	var/atom/movable/screen/fullscreen/blackout = body.screens["blind"]
	if(!istype(blackout, /atom/movable/screen/fullscreen/blackimageoverlay) || blackout.plane != FULLSCREEN_PLANE)
		log_world("SUMIARI TEST FAIL unconscious overlay=[blackout?.type] plane=[blackout?.plane]")
		body.stat = CONSCIOUS
		body.update_blindness()
		return FALSE
	body.stat = CONSCIOUS
	body.update_blindness()
	var/obj/item/clothing/mask/rogue/blindfold/cloth = new
	body.equip_to_slot(cloth, SLOT_WEAR_MASK)
	if(!HAS_TRAIT_FROM(body, TRAIT_BLIND, EYES_COVERED))
		log_world("SUMIARI TEST FAIL cloth blindfold did not blind")
		body.dropItemToGround(cloth)
		return FALSE
	body.dropItemToGround(cloth)
	if(HAS_TRAIT_FROM(body, TRAIT_BLIND, EYES_COVERED))
		log_world("SUMIARI TEST FAIL cloth blindfold stayed")
		return FALSE
	var/obj/item/clothing/glasses/blindfold/lenses = new
	body.equip_to_slot(lenses, SLOT_GLASSES)
	if(!HAS_TRAIT(body, TRAIT_BLIND))
		log_world("SUMIARI TEST FAIL glasses blindfold did not blind")
		body.dropItemToGround(lenses)
		return FALSE
	body.dropItemToGround(lenses)
	var/obj/item/clothing/mask/rogue/duelmask/mask = new
	body.equip_to_slot(mask, SLOT_WEAR_MASK)
	if(HAS_TRAIT(body, TRAIT_BLIND))
		log_world("SUMIARI TEST FAIL duelmask blinded")
		body.dropItemToGround(mask)
		return FALSE
	body.dropItemToGround(mask)
	if(!eyes.vision_on)
		log_world("SUMIARI TEST FAIL coverings released vision")
		return FALSE
	log_world("SUMIARI TEST coverings PASS blind plane=[FULLSCREEN_PLANE] relay=[SUMIARI_RELAY_PLANE]")
	return TRUE

/proc/sumiari_sweep_dispose(list/trash)
	for(var/atom/thing as anything in trash)
		if(QDELETED(thing))
			continue
		if(ishuman(thing))
			var/mob/living/carbon/human/body = thing
			var/obj/item/organ/eyes/held = body.getorganslot(ORGAN_SLOT_EYES)
			if(istype(held, /obj/item/organ/eyes/sumiari))
				var/obj/item/organ/eyes/sumiari/eyes = held
				eyes.release_client_vision(body)
			var/datum/hud/hud = body.hud_used
			body.hud_used = null
			if(hud)
				qdel(hud)
		qdel(thing)

// Temporary: humen use these eyes so the vision can be played. Swap keeps eye color from character setup.
/datum/species/human/northern/on_species_gain(mob/living/carbon/C, datum/species/old_species, datum/preferences/pref_load)
	. = ..()
	sumiari_grant_eyes(C)

// Leaving humen drops the temporary eyes. Organ DNA would otherwise rebuild them on the next species.
/datum/species/human/northern/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	sumiari_release_borrowed_eyes(C, new_species)
	return ..()

/proc/sumiari_grant_eyes(mob/living/carbon/C)
	if(!istype(C))
		return
	var/obj/item/organ/eyes/current = C.getorganslot(ORGAN_SLOT_EYES)
	if(!current)
		return
	if(istype(current, /obj/item/organ/eyes/sumiari))
		sumiari_imprint_eye_dna(C, current)
		return
	var/obj/item/organ/eyes/sumiari/replacement = new
	replacement.eye_color = current.eye_color
	replacement.heterochromia = current.heterochromia
	replacement.second_color = current.second_color
	replacement.update_accessory_colors()
	replacement.Insert(C, special = TRUE, drop_if_replaced = FALSE)
	if(replacement.owner == C)
		sumiari_imprint_eye_dna(C, replacement)

/proc/sumiari_imprint_eye_dna(mob/living/carbon/C, obj/item/organ/eyes/eyes)
	if(!C?.dna || !eyes)
		return
	if(!C.dna.organ_dna)
		C.dna.organ_dna = list()
	C.dna.organ_dna[ORGAN_SLOT_EYES] = eyes.create_organ_dna()

// new_species lists its own eyes: drop our DNA so that list wins.
// It lists none: write ordinary eyes, so the slot is not left empty and these eyes do not ride along.
/proc/sumiari_release_borrowed_eyes(mob/living/carbon/C, datum/species/new_species)
	if(!istype(C))
		return
	var/new_type = new_species?.organs?[ORGAN_SLOT_EYES]
	if(new_type == /obj/item/organ/eyes/sumiari)
		return
	var/obj/item/organ/eyes/current = C.getorganslot(ORGAN_SLOT_EYES)
	var/datum/organ_dna/eyes_dna = C.dna?.organ_dna?[ORGAN_SLOT_EYES]
	var/borrowed = istype(current, /obj/item/organ/eyes/sumiari) || eyes_dna?.organ_type == /obj/item/organ/eyes/sumiari
	if(!borrowed || !C.dna)
		return
	if(!C.dna.organ_dna)
		C.dna.organ_dna = list()
	if(new_type)
		C.dna.organ_dna -= ORGAN_SLOT_EYES
		return
	if(eyes_dna)
		eyes_dna.organ_type = /obj/item/organ/eyes
		return
	var/obj/item/organ/eyes/plain = new
	C.dna.organ_dna[ORGAN_SLOT_EYES] = plain.create_organ_dna()
	qdel(plain)
