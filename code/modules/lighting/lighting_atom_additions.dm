
/turf
	///Lumcount added by sources other than lighting datum objects, such as the overlay lighting component.
	var/dynamic_lumcount = 0

/atom
	var/light_power = 1 // Intensity of the light.
	///Range of the maximum brightness of light in tiles. Zero means no light.
	var/light_inner_range = 0
	///Range where light begins to taper into darkness in tiles.
	var/light_outer_range = 0
	///Adjusts curve for falloff gradient
	var/light_falloff_curve = LIGHTING_DEFAULT_FALLOFF_CURVE
	var/light_color     // Hexadecimal RGB string representing the colour of the light.
	///Boolean variable for toggleable lights. Has no effect without the proper light_system, light_range and light_power values.
	var/light_on = TRUE

	var/tmp/datum/light_source/light // Our light source. Don't fuck with this directly unless you have a good reason!
	var/tmp/list/light_sources       // Any light sources that are "inside" of us, for example, if src here was a mob that's carrying a flashlight, that flashlight's light source would be part of this list.

	var/light_system = STATIC_LIGHT
	///Bitflags to determine lighting-related atom properties.
	var/light_flags = NONE

/atom/movable
	///Lazylist to keep track on the sources of illumination.
	var/list/affected_dynamic_lights
	///Highest-intensity light affecting us, which determines our visibility.
	var/affecting_dynamic_lumi = 0

/atom/movable/Initialize(mapload, ...)
	. = ..()
	if(light_system == MOVABLE_LIGHT)
		AddComponent(/datum/component/overlay_lighting)

///Keeps track of the sources of dynamic luminosity and updates our visibility with the highest.
/atom/movable/proc/update_dynamic_luminosity()
	var/highest = 0
	for(var/i in affected_dynamic_lights)
		if(affected_dynamic_lights[i] <= highest)
			continue
		highest = affected_dynamic_lights[i]
	if(highest == affecting_dynamic_lumi)
		return
	luminosity -= affecting_dynamic_lumi
	affecting_dynamic_lumi = highest
	luminosity += affecting_dynamic_lumi


///Helper to change several lighting overlay settings.
/atom/movable/proc/set_light_range_power_color(range, power, color)
	set_light_range(range)
	set_light_power(power)
	set_light_color(color)

/obj/effect/overlay/light_visible
	name = ""
	icon = 'icons/effects/light_overlays/light_32.dmi'
	icon_state = "light"
	layer = O_LIGHTING_VISUAL_LAYER
	plane = O_LIGHTING_VISUAL_PLANE
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	vis_flags = NONE

/**
 * Invisible stand-in that draws a movable light's visible_mask on the map.
 *
 * BYOND only draws an atom (and its vis_contents) for a viewer who can see the turf that atom covers.
 * The light mask used to sit in the vis_contents of whatever carried the light, so any opaque thing
 * between the viewer and the light source (a tree, reeds, a closed door) hid the source turf and
 * took the whole light pool with it, even though the lit ground around it was still in plain view.
 *
 * The carrier sits on the source's turf with bounds that cover the full light radius. BYOND draws an
 * atom when ANY turf it covers is visible, so the pool now shows whenever the viewer can see lit
 * ground, whether or not the source itself is hidden. The mask itself is unchanged, so the
 * brightness, size and colour of every light stay exactly what they were.
 *
 * Because big bounds put the carrier in the contents of every covered turf, it is made inert:
 * not an obj or mob, no density, no mouse interaction, anchored, flying, and it ignores
 * forced moves, throws, conveyors, explosions, fire and non-forced deletion. Only the
 * overlay_lighting component moves it, by setting loc directly so no Entered/Crossed procs run.
 */
/atom/movable/light_carrier
	name = ""
	icon = null
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	movement_type = FLYING
	move_resist = INFINITY
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	vis_flags = NONE

/atom/movable/light_carrier/Destroy(force)
	if(!force)
		return QDEL_HINT_LETMELIVE
	vis_contents.Cut()
	loc = null
	return ..()

/atom/movable/light_carrier/Cross(atom/movable/AM)
	return TRUE

/atom/movable/light_carrier/Crossed(atom/movable/AM, oldloc)
	return

/atom/movable/light_carrier/Uncross(atom/movable/AM, atom/newloc)
	return TRUE

/atom/movable/light_carrier/Uncrossed(atom/movable/AM)
	return

/atom/movable/light_carrier/Move(atom/newloc, direct, glide_size_override)
	return FALSE

/atom/movable/light_carrier/forceMove(atom/destination)
	return FALSE

/atom/movable/light_carrier/throw_at(atom/target, range, speed, mob/thrower, spin, diagonals_first, datum/callback/callback, force, extra)
	return FALSE

/atom/movable/light_carrier/ConveyorMove(movedir)
	return

/atom/movable/light_carrier/can_zFall(turf/source, levels, turf/target, direction)
	return FALSE

/atom/movable/light_carrier/ex_act(severity, target, epicenter, devastation_range, heavy_impact_range, light_impact_range, flame_range)
	return

/atom/movable/light_carrier/fire_act(added, maxstacks)
	return

/atom/movable/light_carrier/acid_act(acidpwr, acid_volume)
	return FALSE
