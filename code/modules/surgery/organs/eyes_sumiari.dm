// Sumiari vision.
// Pitch black is full color. Wherever a normal human sees light, that same image is an ink wash.
// The wash keeps the sprite's brightness: Rec.709 luma, then a gentle slope that does not threshold.
// A contrast crush turned dither into white specks on black. The paper lift is not on that curve.
// It is a second relay, and only in direct midday sun. The sunlight plane is white at dawn too.
// The wash is not a second light model. It is the vanilla lighting plane, used as a mask,
// plus the alpha of the movable-light plane. Static lights keep their corner-smoothed gradient.
// A held torch, a dropped torch, a sconce, and anyone else's lantern keep the radial cookie.
// Sunlight stays in the capture, and fire flicker updates the mask on the same frame.
// dynamic_lumcount is a flat stamp and is not this mask.
//
// The camera-static relay of *sumiari_scene drew nothing on 516.1688. That plate had no atoms.
// An asterisk render_target stores the plane's atoms, not the filters hung on its master, and the
// asterisk keeps the filtered draw off the screen. Sampling it stays blank even when the mask is forced.
// Color matrices on the world plane masters do desaturate on that client. That is the force-ink path.
// Live ink is a screen relay of those same captures. A filter list on the plane master drew nothing.
//
// Composite, bottom to top:
// 1. World planes draw themselves, in color, with no light tint. Their render targets have no asterisk.
// 2. Lighting plane 17 stays at alpha 255 and render_target "*lighting". The asterisk is the only hide.
//    Alpha 0 blanks that capture. Movable-light plane 20 is "*O_LIGHT_VISUAL_PLANE" at alpha 255.
//    That plane stays hidden, so a torch cookie does not tint the world. Its alpha is still a mask input.
// 3. Offscreen plates turn *lighting and that cookie plane into *sumiari_mask. Each plate is a plane master
//    that only stores the asterisk target, plus a child that draws the source. The child uses render_source,
//    not a layer filter on a 32×32 icon: that filter resampled the whole view down to about one pixel per tile,
//    and the alpha mask scaled it back up as hard tile steps. The child is the size of the view and sits
//    at SCREEN_SOUTHWEST, so the corner gradient and the cookie falloff stay per pixel, and they flicker
//    with the lighting plane. The cookie child copies alpha, which is the white cookie's soft falloff.
//    The mask is the max of the static light and that alpha. Color matrices and the max blend run on that full image.
// 4. Live ink is a screen relay on the camera-static plane, under the HUD. It stacks every world
//    capture, runs the ink matrix, then masks with *sumiari_mask. Mask 0 leaves the relay transparent,
//    so the color world shows through. Mask 1 covers it with ink. Filters on the above-lighting plane
//    master did not cover the view on 516.1688: with the old glare relay gone, campfires stayed in color.
//    Force ink still desaturates, because that path is a color matrix on the world masters themselves.
// 5. Force ink does not use the relay. Each world plane master gets the ink color matrix directly.
//    Force color takes those filters back off and hides both relays.
// 6. Sun haze is a second relay, same stack, masked by *SUNLIGHT_PLANE. That plane is white for any
//    open or border tile, including dawn, so the mask is also gated by the sun's own strength and the
//    time of day. Dawn, dusk, night, and a border sky contribute none. Midday mixes in a small lift.
//    A cave and a campfire are black on that plane. The lift is not part of the ink matrix.
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
// Moonlight layer (SUMIARI_MOON_VIVID below picks vivid color, the default; 0 is the older silver tint).
// Moonlight tint. At night, open sky reads as a faint cool silver, so moonlight looks different from
// firelight. Firelight stays neutral ink gray. Vanilla night has no moon in the lighting model (the
// midnight sun color is #000000), so "moonlit" means a pixel the sky plane calls open or border sky.
// The silver is the ink luma times a cool tint, laid over the world at a low alpha:
// alpha = strength * (sky - LAMP_GAIN * lamp wash). A lamp-washed pixel gets none and keeps its firelit look.
// A cave or roof has no sky, so it gets none. Day, dawn, and dusk get none.
#define SUMIARI_MOON_TINT 1
// Peak alpha of the silver layer on open sky with no lamp light. Under half, so the colors still show through.
#define SUMIARI_MOON_TINT_STRENGTH 0.45
// Silver: each channel of the ink gray is scaled by these. Blue a little up and red a little down.
// The average stays about 1, so brightness stays with the sprite.
#define SUMIARI_MOON_SILVER_R 0.88
#define SUMIARI_MOON_SILVER_G 0.97
#define SUMIARI_MOON_SILVER_B 1.15
// A little moon glow added to the silver (before the tint), so open dark sky reads as moonlit, not only as cooler.
#define SUMIARI_MOON_SILVER_LIFT 0.06
// How fast lamp and fire light push the silver out. At 3, a pixel at a third of full lamp wash or more gets none,
// so the edge of a campfire's glow fades to plain night instead of silvering the warm light.
#define SUMIARI_MOON_LAMP_GAIN 3
// Vivid moonlight. Moonlight is not light to these eyes: a moonlit pixel is not grayed at all. Instead the open
// night sky is painted richer than a human ever sees it by day: deep saturated hues shifted toward crimson,
// emerald, sapphire, and warm umber at the same brightness, with a faint silver sheen on top. 0 falls back to the plain silver tint.
// The vivid relay sits UNDER the ink relay, so lamps, fires, candles, magic lights, and light-source sprites still
// gray their pixels in proportion to their own wash, over the vivid color, exactly as they gray plain color.
// The mask is only sky * strength: a roofed room or cave is black on the sky plane and keeps plain color.
#define SUMIARI_MOON_VIVID 1
// Saturation around Rec.709 luma. 1 is normal color. Above about 1.9 strong reds and greens clip into neon.
// 1.75: punchy jewel color with headroom under the neon line. The highlight knee below keeps it from clipping.
#define SUMIARI_MOON_SATURATION 1.75
// Faint silver sheen: this fraction of the pixel is the cool silver ink (SILVER_R/G/B above). It is a tint,
// not a lift: the moonlit layer keeps the plain image's brightness, only the colors are richer.
#define SUMIARI_MOON_SHEEN 0.3
// The sheen's own tint: silver-lilac, cooler than the ink silver, so moonlit highlights read luminous blue-white.
#define SUMIARI_MOON_SHEEN_R 0.95
#define SUMIARI_MOON_SHEEN_G 1
#define SUMIARI_MOON_SHEEN_B 1.1
// Moonlit luminance: the whole vivid matrix (not the shadow violet) is scaled by this. A modest midtone lift, so
// moonlit ground reads as lit by the moon rather than as dark art. Bright pixels clip softly into the moon glow.
// 1 = the plain image's brightness.
#define SUMIARI_MOON_LUMINANCE 1.5
// Soft highlight knee on the moonlit layer. A color matrix is linear, so luminance 1.5 and saturation 1.75 pushed
// bright greens, blues and whites past 1, where they clipped flat. With the knee each world plane is graded at
// 1 / LUMINANCE (nothing clips there), a second copy subtracts SLOPE * (graded - START / LUMINANCE) (the subtract
// clamps at 0, so it only touches highlights), and the gain is put back once on the whole stack. Output rises
// 1:1 up to KNEE_START, then at (1 - SLOPE) of the rate, so highlights roll into the glow instead of clipping.
// Mobs are not kneed (their look never reaches 1). 0 turns the knee off and grades exactly as before.
#define SUMIARI_MOON_KNEE 1
#define SUMIARI_MOON_KNEE_START 0.72
#define SUMIARI_MOON_KNEE_SLOPE 0.55
// Hue shifts. Colors pop by moving hue, not by brightening. Each push below is a raw nudge on one input channel's
// row of the color matrix. The sum is projected (sumiari_moon_hue_matrix) so every row keeps its Rec.709 luma
// (a pushed channel is paid for by the others) and every column sums to 0 (gray stays gray). A linear matrix
// moves opposite hues the opposite way, so red-to-crimson and teal-to-sapphire pull against each other: reds
// mostly lose their orange cast and deepen, rather than turning pink.
// Master strength, 0 turns all hue shifts off.
#define SUMIARI_MOON_HUE_SHIFT 1
// Reds lean crimson: red input pushes a little blue.
#define SUMIARI_MOON_HUE_CRIMSON 0
// Browns, wood, orange, and reds lean warm umber: red input pushes more red (less yellow).
#define SUMIARI_MOON_HUE_UMBER 0.5
// Greens lean emerald: green input pushes blue.
#define SUMIARI_MOON_HUE_EMERALD 0.7
// Reds and brick lean ember-umber: red input pushes green, so reddish-gray brick warms toward tan, not pink.
#define SUMIARI_MOON_HUE_EMBER 1
// Blues and teals lean sapphire: blue input pushes green (violet-blue toward sapphire's 216 degrees).
#define SUMIARI_MOON_HUE_SAPPHIRE 0.35
// Mobs (GAME_PLANE_FOV_HIDDEN) under the moon: no hue push, no violet shadow. The moon relay shows sprites unlit, so
// skin came out at full daytime chroma and read salmon against the night. Mobs get moonlight instead: chroma eased to
// MOB_SATURATION, a MOB_SILVER share of the silver tint (luma kept), and MOB_GAIN so whites never clip.
// 0 = same look as the world.
#define SUMIARI_MOON_MOB_NEUTRAL 1
#define SUMIARI_MOON_MOB_SATURATION 0.7
#define SUMIARI_MOON_MOB_SILVER 0.15
#define SUMIARI_MOON_MOB_GAIN 0.95

// ---------------------------------------------------------------------------------------------
// Night beauty. Midnight only. Everything below draws only on open moonlit sky that no lamp, fire, or sun lights,
// and only for these eyes (screen pieces, filters on the moon relay, and client images), so the HUD and every
// other viewer are untouched. Night-bloom flora (6) is the one exception to the open-sky rule: it shows in caves too.
// Every feature has its own 0/1 switch.
// 1) Starlight glints: a tiny slow four-point twinkle on open-sky water, wet ground, or a metal item. One beauty
//    tick samples a few random tiles in view (no full scan) and keeps at most GLINT_MAX glints alive.
#define SUMIARI_NIGHT_GLINTS 1
#define SUMIARI_GLINT_MAX 8
#define SUMIARI_GLINT_TRIES 8
// Percent chance per beauty tick to start a new glint when below the cap.
#define SUMIARI_GLINT_CHANCE 80
// Each glint stays SUMIARI_GLINT_LIFE and twinkles every SUMIARI_GLINT_CYCLE. A glint that lived for one short
// twinkle never showed: the client drew a brand-new image's first moments of animation as nothing.
#define SUMIARI_GLINT_LIFE (6 SECONDS)
#define SUMIARI_GLINT_CYCLE (2 SECONDS)
#define SUMIARI_GLINT_SCALE 1.6
// Between twinkles a glint only dims to this alpha and this scale, so it never vanishes and stays easy to spot.
#define SUMIARI_GLINT_LOW_ALPHA 50
#define SUMIARI_GLINT_LOW_SCALE 1
// The game glint is a 3-7px cross, too small to read at full-frame zoom, so a soft moonlit core (the light_32 lamp
// sprite, scaled down and tinted) sits under it and swells with it. It is the twinkle's halo.
#define SUMIARI_GLINT_CORE_SCALE 0.4
// 0: no soft core under the twinkle (the core read as a purple blob).
#define SUMIARI_GLINT_CORE 0
#define SUMIARI_GLINT_CORE_COLOR "#d4c8ff"
#define SUMIARI_GLINT_CORE_ALPHA 230
#define SUMIARI_GLINT_COLOR "#eef2ff"
#define SUMIARI_GLINT_ALPHA 255
// Dew: moonlit grass (and moss) may twinkle too, not only water and metal. 0 = shiny tiles only.
// Off while the moon-effect dew (SUMIARI_MOON_DEW) runs: that one is finer and lives on the ground.
#define SUMIARI_GLINT_DEW (1 - SUMIARI_MOON_DEW)
// 5) Moon-cast shadows: the moon matrix adds a cool indigo that is strongest on black and gone at white
//    (k * indigo * (1 - luma)). Only a trace of red (blue >> green > red): a larger red share on top of the cool
//    sheen turned dim brown brick pink.
#define SUMIARI_NIGHT_SHADOWS 1
#define SUMIARI_SHADOW_VIOLET 0.12
#define SUMIARI_SHADOW_R 0.1
#define SUMIARI_SHADOW_G 0.45
#define SUMIARI_SHADOW_B 1
// 6) Night-bloom flora: kneestingers (glowshrooms) and glowing mushroom clusters wear a slow Noc halo that only
//    these eyes see at night, breathing between Noc's violet and the moon's silver-teal. The plant's own sprite
//    stays as it is (gray, when it is itself a light); the halo is cut around it, never on top of it.
#define SUMIARI_NIGHT_FLORA 1
#define SUMIARI_FLORA_RANGE 8
#define SUMIARI_FLORA_MAX 16
#define SUMIARI_FLORA_ALPHA 170
#define SUMIARI_FLORA_BLUR 3
#define SUMIARI_FLORA_PERIOD (12 SECONDS)
#define SUMIARI_FLORA_COLOR_A "#9a7bff"
#define SUMIARI_FLORA_COLOR_B "#8fe8da"
#define SUMIARI_FLORA_LAYER 1.5
#define SUMIARI_GLINT_RADIUS 7
#define SUMIARI_GLINT_RESCAN 5
#define SUMIARI_GLINT_SPOT_MAX 40
#define SUMIARI_GLINT_LAYER 2
// Glints and halos draw on the fullscreen plane, under every fullscreen overlay (flash is layer 23) and
// under the HUD. On the relay plane they came out dimmed and tinted by the composite above them. Both are client
// images on a turf or a plant, so they move with the world. There is no screen-space night effect at all: the
// moon look is only color on the world (the moon relay), cut by the moon mask.
#define SUMIARI_BEAUTY_PLANE FULLSCREEN_PLANE
// Moon fade: the whole moon look fades in across the dusk step and out across the first half hour of dawn,
// next to the sky's own color fade, instead of snapping at 16:00 and 8:00 station time. Station time.
// Feather on the moon mask's open-sky edge, in pixels (a blur on the sky copy): no hard line at a ledge or roof.
// 4, not 8: the sky plate is already a per-corner gradient and the wall faces carry the ledges, so 8 only smeared
// the grade across the view down through open space, which read as a blurred lower level.
#define SUMIARI_MOON_EDGE_BLUR 4
#define SUMIARI_MOON_FADE_IN_START (15.5 HOURS)
#define SUMIARI_MOON_FADE_IN_END (16 HOURS)
#define SUMIARI_MOON_FADE_OUT_START (8 HOURS)
#define SUMIARI_MOON_FADE_OUT_END (8.5 HOURS)
// While a fade runs, the moon mask and the halos are animated toward the next sample every tick.
// Real time. Only ticks inside a fade window.
#define SUMIARI_MOON_FADE_TICK (2 SECONDS)
// How often the client-image features (1 and 6) refresh.
#define SUMIARI_BEAUTY_INTERVAL (1 SECONDS)
// Peak alpha of the vivid layer on open sky at night. 1 means a moonlit pixel is fully the vivid color.
#define SUMIARI_MOON_VIVID_STRENGTH 1
// Lamp fade for the vivid layer: vivid alpha is strength * (sky - fade * lamp wash), and an emitter's own sprite
// takes it to 0. So a flame, and the rim right around a lamp, under the ink gray is plain color, not boosted
// (the gain would otherwise turn a half-washed flame edge orange). 1 fades vivid exactly as the gray rises.
#define SUMIARI_MOON_VIVID_LAMP_FADE 2

// Moon spares non-fire light. At night, on open moonlit sky, a light that is not a flame (glowshroom, glowing moss,
// wisp, condensed-light orb, spell light) and the tiles it lights show the vivid moon instead of the lamp gray.
// Flames (sumiari_light_is_fire) stay gray under the moon or not, and away from the moon every light stays gray.
// How: a Sumiari-only client image of plain white tiles on the hidden SUMIARI_SPARE_PLANE covers each non-fire
// emitter's open-sky tiles that no flame reaches. The ink mask subtracts it (no gray there) and the moon mask adds
// it (full vivid there). No screen piece: the plane master is a stock HUD plane master with an asterisk target.
#define SUMIARI_MOON_SPARES_NONFIRE 1
#define SUMIARI_SPARE_PLANE -46
#define SUMIARI_SPARE_RENDER_TARGET "*sumiari_moon_spare"
// Emitters looked for within this many tiles of the Sumiari, at most this many spared, each out to this radius.
// The nearest are spared first. A kneestinger patch is dozens of small lights: at 16, picked in scan order, half a
// courtyard of them stayed gray. Each spared emitter is one cached image, rebuilt only when its tiles change.
#define SUMIARI_SPARE_SCAN 11
#define SUMIARI_SPARE_MAX_EMITTERS 64
#define SUMIARI_SPARE_RANGE_MAX 9
// Each spared tile's strength (sumiari_spare_strength) follows the light's own reach: full out to its range plus
// SPARE_MARGIN tiles, then a SPARE_FEATHER-tile fade, and never under its falloff (distance, inner range, curve,
// power, color) times SPARE_COVER, so the spare always outruns the lamp wash it cancels. A tile weaker than
// SPARE_MIN is skipped. The image is blurred by SPARE_BLUR pixels, so the edge is a smooth fade, not tile steps.
#define SUMIARI_SPARE_MARGIN 1
#define SUMIARI_SPARE_FEATHER 2
#define SUMIARI_SPARE_COVER 1.6
#define SUMIARI_SPARE_MIN 0.04
#define SUMIARI_SPARE_BLUR 4

// Moonlit wall faces. The moon mask reads the sky plane: every open or roofed tile draws its four lighting corners'
// sunFalloff there (the vanilla per-corner sky light), but a closed turf (cliff, wall) draws nothing, so the moon
// stopped dead on the top edge of every cliff face and wall. For these eyes only, each closed turf near the owner
// gets a client image of exactly what an open tile would have drawn there: the lighting gradient icon tinted by its
// own four corners' sunFalloff, the corners it already shares with the sky tiles next to it. A face beside open sky
// is moonlit at the top and fades down its height like the ground under a roof edge; rock with no sky near stays 0.
// The images sit on the hidden SUMIARI_CLIFF_PLANE, which the moon mask adds to the sky copy before anything else,
// so lamps, fires, the feather blur and the fade treat a lit face exactly like lit ground. Read only: the corners
// are not touched, nor is anything another viewer sees.
#define SUMIARI_MOON_CLIFFS 1
#define SUMIARI_CLIFF_PLANE -47
#define SUMIARI_CLIFF_RENDER_TARGET "*sumiari_moon_cliff"
// Tiles from the owner scanned each step (the 15x15 view is 7, plus a margin for the glide and the blur).
#define SUMIARI_CLIFF_RANGE 9
// A face whose brightest corner is under this draws nothing.
#define SUMIARI_CLIFF_MIN 0.02

// Moon effects. Night-only touches for these eyes: client images on tiles and plants (so each one moves with the
// map), drawn on four hidden planes that only the moon relay shows. Each hidden plane is layered into the relay's
// world stack right after the world plane it belongs with: ground after the floor, structures after the low game
// plane, water after the game plane, canopy after the upper plane. Walls, mobs and canopies cover an effect as they
// would cover the real thing. The relay is cut by the moon mask (open-sky corner light, minus lamp and fire light,
// times the dusk/dawn fade, feathered), so an effect is exactly as strong as the moon look on its own pixel: none in
// caves, indoors, by day or by a fire, and a soft fade at every edge. Nothing here is screen-sized: no overlay, wash
// or grain. The tiles are scanned only near the owner (FX_RANGE), on each step and every FX_RESCAN beauty ticks,
// and an image is only rebuilt when its tile's state changes. Each effect has a define (compiled in or not) and a
// global (View Variables can flip it live); sumiari_night_beauty_enabled turns all of them off at once.
#define SUMIARI_MOON_FX 1
#define SUMIARI_FX_RANGE 8
#define SUMIARI_FX_RESCAN 5
#define SUMIARI_FX_FLOOR_PLANE -61
#define SUMIARI_FX_LOWER_PLANE -62
#define SUMIARI_FX_GAME_PLANE -63
#define SUMIARI_FX_UPPER_PLANE -64
#define SUMIARI_FX_FLOOR_TARGET "*sumiari_fx_floor"
#define SUMIARI_FX_LOWER_TARGET "*sumiari_fx_lower"
#define SUMIARI_FX_GAME_TARGET "*sumiari_fx_game"
#define SUMIARI_FX_UPPER_TARGET "*sumiari_fx_upper"
// Pale moon silver, the color of every highlight (water, rims, dew).
#define SUMIARI_FX_SILVER_R 214
#define SUMIARI_FX_SILVER_G 226
#define SUMIARI_FX_SILVER_B 255
// 1) Moonlit water: a few thin silver ripple dashes on each open-sky water tile, drifting a pixel or two and
// breathing between two alphas. Neighbouring tiles use different dash layouts and periods, so the surface shimmers
// instead of pulsing in step. Above the water overlays, under any mob in the water.
#define SUMIARI_MOON_WATER 1
#define SUMIARI_WATER_VARIANTS 3
#define SUMIARI_WATER_ALPHA_LOW 70
#define SUMIARI_WATER_ALPHA_HIGH 190
// Ripple cycle (deciseconds); each tile adds 0-16 more.
#define SUMIARI_WATER_PERIOD 34
#define SUMIARI_WATER_CORE_ALPHA 150
#define SUMIARI_WATER_END_ALPHA 60
// 2) Moon-edge highlights. A wall or cliff tile gets a two-pixel pale rim (bright outer pixel, faint inner one) along
// each north, west and east side that meets open sky; trees, rocks, big mushrooms and bushes on open sky get a
// one-pixel rim on the edges of their own sprite that face the moon (up and left): the sprite, solid silver, minus
// itself shifted one pixel away from the moon. The moon mask decides how bright each rim ends up.
#define SUMIARI_MOON_RIMS 1
#define SUMIARI_RIM_OUTER_ALPHA 170
#define SUMIARI_RIM_INNER_ALPHA 55
#define SUMIARI_RIM_SPRITE_ALPHA 150
// 3) Dew sparkle: now and then a tiny point of light (one bright pixel, four faint ones around it) fades in and out
// somewhere on open-sky grass or snow, at a random spot inside the tile. At most DEW_MAX at once and a DEW_CHANCE
// percent chance of a new one per beauty tick, so it reads as the odd glint, never as noise. On the ground plane,
// so grass tufts sit under it and anyone standing there covers it.
#define SUMIARI_MOON_DEW 1
#define SUMIARI_DEW_MAX 4
#define SUMIARI_DEW_CHANCE 35
#define SUMIARI_DEW_SPOTS_MAX 60
#define SUMIARI_DEW_ALPHA 230
#define SUMIARI_DEW_RISE (1.2 SECONDS)
#define SUMIARI_DEW_FALL (1.8 SECONDS)
// 4) Night-flower blooming: herbs and flowers, small and large mushrooms and glowshrooms on open sky slowly open
// through the night. A copy of the plant's sprite in deeper, richer color (saturation BLOOM_SATURATION, a little
// gain, a faint violet-blue bias) lies over it, its alpha following the night: closed at dusk, opening from 16:00 to
// 22:00 (eased), fully open until 5:00, closing again by 8:00. Updated a step at a time as the night goes on.
#define SUMIARI_MOON_BLOOM 1
#define SUMIARI_BLOOM_ALPHA 190
#define SUMIARI_BLOOM_SATURATION 1.8
#define SUMIARI_BLOOM_GAIN 1.15
#define SUMIARI_BLOOM_BIAS_R 0.02
#define SUMIARI_BLOOM_BIAS_G 0
#define SUMIARI_BLOOM_BIAS_B 0.05
#define SUMIARI_BLOOM_OPEN_START (16 HOURS)
#define SUMIARI_BLOOM_OPEN_END (22 HOURS)
#define SUMIARI_BLOOM_CLOSE_START (5 HOURS)
#define SUMIARI_BLOOM_CLOSE_END (8 HOURS)
// Least change in the bloom (0..1) worth re-animating the plants for, and how long that easing takes.
#define SUMIARI_BLOOM_STEP 0.02
#define SUMIARI_BLOOM_EASE (2 SECONDS)
// 5) Soft moon shadows: open ground beside a wall, cliff, tree or rock takes a gentle deep blue-violet shade. Each
// lighting-grid corner of a tile gets a shade from the four tiles that meet there: mostly from the two on its north
// side (the moon stands to the north, so shade falls south of what blocks it), a little from any of the four (soft
// contact shade). The tile is drawn with the vanilla lighting gradient, tinted by those four corners, the same way
// the sky light is drawn, so the shade is smooth across tiles and fades out within about a tile, with no edges.
#define SUMIARI_MOON_SHADE 1
#define SUMIARI_SHADE_NORTH 0.85
#define SUMIARI_SHADE_CONTACT 0.25
#define SUMIARI_SHADE_ALPHA 0.5
#define SUMIARI_SHADE_COLOR "#1c1838"
// A tile whose darkest corner is under this draws nothing.
#define SUMIARI_SHADE_MIN 0.03

// Night senses. In true darkness the eyes catch a faint ink-wash silhouette of a living body close by
// that they cannot otherwise see: behind a wall, door, or other obstacle, inside a closet or crate,
// or a sneaker faded into the dark. It is a client image, so only the Sumiari sees it.
// It never shows: the dead, the undead, magic invisibility (the invisibility spells and veils),
// anything above the Sumiari see_invisible (ghosts, jaunts), a body standing in light, or a body
// the Sumiari already sees plainly. A body hidden by the field-of-view cone is not shown either.
#define SUMIARI_NIGHT_SENSES 1
// Tiles from the Sumiari (square range, like view). 2 means the 5x5 block around them.
#define SUMIARI_SENSE_RANGE 2
// A body is sensed only when its tile wash (the same 0-1 brightness the ink mask uses, gain included)
// is below this. 0.25 means a tile still drawn at least three-quarters in color for the Sumiari.
#define SUMIARI_SENSE_DARK_MAX 0.25
// How often the senses rescan. A step by the Sumiari also rescans at once.
#define SUMIARI_SENSE_INTERVAL (0.5 SECONDS)
// Silhouette alpha pulses slowly between these two (0-255).
#define SUMIARI_SENSE_ALPHA_LOW 30
#define SUMIARI_SENSE_ALPHA_HIGH 70
#define SUMIARI_SENSE_PULSE (3 SECONDS)
// Soft edge on the silhouette, in pixels.
#define SUMIARI_SENSE_BLUR 1.5
// Pale ink-wash fill (0-1 per channel).
#define SUMIARI_SENSE_TONE_R 0.80
#define SUMIARI_SENSE_TONE_G 0.82
#define SUMIARI_SENSE_TONE_B 0.88
// A sneaker in plain line of sight, faded on a dark tile, also gets the silhouette. 0 limits the senses to hidden bodies.
#define SUMIARI_SENSE_SNEAKERS 1
// Most silhouettes at once.
#define SUMIARI_SENSE_MAX 8
// Layer above the relays so the wash cannot gray it.
#define SUMIARI_SENSE_LAYER (SUMIARI_RELAY_LAYER_BASE + 40)
// Subtle paper lift. Same slope as the ink, so it does not flatten a dim scene. The bias sits a little
// above the ink lift. The ink matrix does not use these. A campfire is black on the sunlight plane.
#define SUMIARI_SUN_HAZE_SLOPE 0.96
#define SUMIARI_SUN_HAZE_BIAS 0.08
// No haze below this sun-color strength. Dawn #394579 is about 0.47. Dusk peaks around 0.76.
#define SUMIARI_SUN_HAZE_MIN 0.80
// Even a white midday sun only mixes in this much of the lift. The rest stays the ink brightness.
#define SUMIARI_SUN_HAZE_CAP 0.35

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
// Static lights. The movable-light plane is the other mask input. dynamic_lumcount is not an input.
#define SUMIARI_LIGHTING_SOURCE "*lighting"
// Asterisk plus O_LIGHTING_VISUAL_RENDER_TARGET. The define already includes quotes, so it cannot be nested in another string.
#define SUMIARI_OLIGHT_SOURCE "*O_LIGHT_VISUAL_PLANE"
#define SUMIARI_WASH_LIVE "live"
#define SUMIARI_WASH_INK "ink"
#define SUMIARI_WASH_COLOR "color"
// 11 plates (the 10 mask plates plus the moon mask), each a master plus the child that draws the capture,
// plus the ink, sun, and moon relays.
#define SUMIARI_PIECE_CAP 32
// Covers a 15x15 view (radius 7). Opaque walls and trees still block sight. This is not x-ray.
#define SUMIARI_SEE_IN_DARK 8
// Darkness-sneak raises invisibility to SEE_INVISIBLE_LIVING + skill*0.55 + 1 (about 29 at legendary).
// 35 sees that concealment and stays under SEE_INVISIBLE_OBSERVER (60), so ghosts stay hidden.
#define SUMIARI_SEE_INVISIBLE (SEE_INVISIBLE_LIVING + 10)

// Glow sprites live here, so the relay can capture them. The wash filter is not hung on this master.
#define SUMIARI_INK_PLANE ABOVE_LIGHTING_PLANE
// Ink and sun relays. Above the map and the hidden lighting planes, under fullscreen and the HUD.
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
#define SUMIARI_PLANE_COOKIE -52
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
#define SUMIARI_TARGET_COOKIE "sumiari_cookie"
#define SUMIARI_TARGET_DARK "sumiari_dark"
#define SUMIARI_TARGET_MOON "sumiari_moon"
// The movable-light cookie split into its R, G and B brightness (color times falloff, flattened on black).
#define SUMIARI_PLANE_COOKIE_RED -65
#define SUMIARI_PLANE_COOKIE_GREEN -66
#define SUMIARI_PLANE_COOKIE_BLUE -67
#define SUMIARI_TARGET_COOKIE_RED "sumiari_cookie_r"
#define SUMIARI_TARGET_COOKIE_GREEN "sumiari_cookie_g"
#define SUMIARI_TARGET_COOKIE_BLUE "sumiari_cookie_b"

// Stored in place of a null render_target. BYOND drops a list entry whose value is null.
#define SUMIARI_NO_TARGET ""

// Static lights barely reach full on the lighting plane. set_light leaves inner range 0 and the falloff
// curve is cubed, so a range-5 campfire peaks at about 0.43 of its color even on its own tile, and
// #da5e21 puts that at 0.37 on the brightest channel. That read as 63% color right beside the fire.
// The static part of the mask is divided by this, then clamped. 0.37 is the brightest a lone campfire
// draws, so its own tile is fully gray and everything below is proportional to vanilla brightness:
// half as bright as the fire is half color, true dark is full color. A lower value (0.3 before) clamped
// most of a lit room to one flat gray plateau and pushed the half-gray line out past vanilla's half-light.
#define SUMIARI_LIGHT_FULL 0.37
#define SUMIARI_LIGHT_GAIN (1 / SUMIARI_LIGHT_FULL)
// Every lit emitter on a turf draws its own sprite here through one shared vis_contents marker.
// The plane master stores it under an asterisk target, so no one sees it. Sumiari read it into the mask
// at full strength, so a flame, a brazier, a wall candle, or a wisp is never in color.
#define SUMIARI_SOURCE_PLANE -45
#define SUMIARI_SOURCE_RENDER_TARGET "*sumiari_light_source"
#define SUMIARI_PLANE_SOURCE -49
#define SUMIARI_TARGET_SOURCE "sumiari_source"

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
	// The moon mask sampler. Its alpha matrix is rebuilt on a time-of-day change, so night silver turns on and off.
	var/atom/movable/screen/sumiari_sampler/moon_plate
	// Night senses: body -> image shown to sense_client, and body -> the dir/lying the image was copied at.
	var/list/sensed_images
	var/list/sensed_shapes
	var/client/sense_client
	var/sense_timer
	// Night beauty: the client the images were shown to, live glints (image -> expiry), and flora halos (plant -> image).
	var/client/beauty_client
	// Moon spares non-fire light: the client the spare images were shown to, emitter -> image, emitter -> tile key.
	var/client/spare_client
	var/list/spare_images
	var/list/spare_keys
	// Moonlit wall faces: the client the images were shown to, turf -> image, turf -> corner key.
	var/client/cliff_client
	var/list/cliff_images
	var/list/cliff_keys
	// Moon effects: the client the images were shown to, key -> image, key -> state, and the scan bookkeeping.
	var/client/fx_client
	var/list/fx_images
	var/list/fx_states
	var/turf/fx_center
	var/fx_age = 0
	// Dew: grass tiles found by the last scan, and the live sparkles (image -> expiry).
	var/list/fx_dew_spots
	var/list/fx_dew_images
	// Bloom: how open the night flowers are drawn right now (null until the first scan).
	var/fx_bloom
	var/beauty_timer
	var/list/glint_images
	var/list/glint_spots
	// image -> list(anchor atom, pixel x, pixel y). Beauty images live on their anchor (a glint on its tile, a
	// halo on its plant), so they move with the map while the owner walks.
	var/list/beauty_anchors
	var/turf/glint_center
	var/glint_age = 0
	var/list/flora_images
	// Pixel size of the mask canvas. A view change rebuilds it so the sample stays one pixel per screen pixel.
	var/mask_pixels_x = 0
	var/mask_pixels_y = 0
	// live uses the lighting mask. ink forces that mask to 1. color forces it to 0.
	var/wash_mode = SUMIARI_WASH_LIVE

var/global/list/sumiari_active_eyes = list()
var/global/sumiari_screen_live = 0
// Headless sweep builds the composite with a hud and no client. Live play still requires a client.
var/global/sumiari_test_without_client = FALSE
// Darkest open gnoll turf from the map probe. The carried-light check stands a torch here.
var/global/turf/sumiari_test_dark_turf

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
		start_night_senses()
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
	start_night_senses()

/obj/item/organ/eyes/sumiari/proc/release_client_vision(mob/living/carbon/M)
	stop_night_senses(M)
	sumiari_active_eyes -= src
	vision_on = FALSE
	wash_mode = SUMIARI_WASH_LIVE
	glare_plate = null
	moon_plate = null
	clear_master_wash(M)
	clear_screen_pieces(M)
	restore_render_targets(M)
	saved_render_targets = null
	var/mob/living/carbon/who = M || owner
	var/atom/movable/screen/plane_master/lighting/lighting = who?.hud_used?.plane_masters["[LIGHTING_PLANE]"]
	if(lighting)
		lighting.filters = sumiari_lighting_punch_filters(O_LIGHTING_VISUAL_RENDER_TARGET)
		lighting.alpha = who.lighting_alpha
	var/atom/movable/screen/fullscreen/glow = who?.screens?["see_through_darkness"]
	if(glow)
		glow.alpha = initial(glow.alpha)

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
	// The human hud adds a faint glow around the wearer to the lighting plane (up to 30/255).
	// The lighting plane is hidden for these eyes, so that glow only fed the mask, and the gain
	// would have washed the wearer's own tiles in true darkness.
	var/atom/movable/screen/fullscreen/glow = owner.screens?["see_through_darkness"]
	if(glow)
		glow.alpha = 0

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
	moon_plate = null
	if(screen_pieces)
		QDEL_LIST(screen_pieces)
	screen_pieces = list()
	build_mask_plates()
	build_wash_relays()
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
	if(target_name == SUMIARI_TARGET_MOON)
		moon_plate = sampler
	screen_pieces += plate
	screen_pieces += sampler
	return sampler

/obj/item/organ/eyes/sumiari/proc/mask_canvas_matches()
	var/list/span = sumiari_mask_span(owner?.client?.view)
	return mask_pixels_x == span[1] && mask_pixels_y == span[2] && mask_pixels_x > 0

/obj/item/organ/eyes/sumiari/proc/build_mask_plates()
	// Static part is 1 - A * (1 - max(R, G, B)), from the lighting-plane render. Not from dynamic_lumcount.
	// The mask then takes the brighter of that and the movable-light cookie.
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
		filter(type = "color", color = sumiari_matrix_light_gain()),
	))
	// Cookie RGB is the light color, the icon alpha is the falloff, and set_power keeps that alpha at 255 whatever the
	// power. A human sees a movable light as its color times that falloff: the cookie punches the darkness out and
	// then multiplies the world by the light's color. Copying the alpha alone counted a dim red or violet light as
	// full brightness over its whole radius, so a room a human sees near black went fully gray for these eyes.
	// Brightness is max(R, G, B) of the color times the falloff (each channel flattened on black), the same
	// max-channel reading the static lighting gets. A white-ish light (a kneestinger, a torch) is unchanged.
	add_plate(SUMIARI_PLANE_COOKIE_RED, SUMIARI_TARGET_COOKIE_RED, SUMIARI_OLIGHT_SOURCE, sumiari_cookie_channel_filters(1))
	add_plate(SUMIARI_PLANE_COOKIE_GREEN, SUMIARI_TARGET_COOKIE_GREEN, SUMIARI_OLIGHT_SOURCE, sumiari_cookie_channel_filters(2))
	add_plate(SUMIARI_PLANE_COOKIE_BLUE, SUMIARI_TARGET_COOKIE_BLUE, SUMIARI_OLIGHT_SOURCE, sumiari_cookie_channel_filters(3))
	add_plate(SUMIARI_PLANE_COOKIE, SUMIARI_TARGET_COOKIE, sumiari_offscreen(SUMIARI_TARGET_COOKIE_GREEN), list(
		filter(type = "color", color = sumiari_matrix_force_alpha()),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_COOKIE_RED), blend_mode = BLEND_SUBTRACT),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_COOKIE_RED), blend_mode = BLEND_ADD),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_COOKIE_BLUE), blend_mode = BLEND_SUBTRACT),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_COOKIE_BLUE), blend_mode = BLEND_ADD),
	))
	// The emitters' own sprites. Alpha into gray, so a sprite pixel is a full wash whatever its tile reads.
	add_plate(SUMIARI_PLANE_SOURCE, SUMIARI_TARGET_SOURCE, SUMIARI_SOURCE_RENDER_TARGET, sumiari_lighting_channel_filters(4))
	// Max with the cookie. Add alone would wash a sconce twice, once for the fixture and once for its torch.
	add_plate(SUMIARI_PLANE_MASK, SUMIARI_TARGET_MASK, sumiari_offscreen(SUMIARI_TARGET_LIGHT), list(
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_COOKIE), blend_mode = BLEND_SUBTRACT),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_COOKIE), blend_mode = BLEND_ADD),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_SOURCE), blend_mode = BLEND_SUBTRACT),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_SOURCE), blend_mode = BLEND_ADD),
#if SUMIARI_MOON_SPARES_NONFIRE
		// No lamp gray where the moon spares a non-fire light.
		filter(type = "layer", render_source = SUMIARI_SPARE_RENDER_TARGET, blend_mode = BLEND_SUBTRACT),
#endif
		filter(type = "color", color = sumiari_matrix_gray_to_alpha()),
	))
	// *SUNLIGHT_PLANE, not the lighting-plane light image. A campfire is full-bright on *lighting and black here.
	add_plate(SUMIARI_PLANE_GLARE, SUMIARI_TARGET_GLARE, SUNLIGHTING_RENDER_TARGET, list(
		filter(type = "color", color = sumiari_matrix_glare_to_alpha()),
	))

// Both relays stay in the screen list. Live mode fills their filters. Force ink and force color hide them.
/obj/item/organ/eyes/sumiari/proc/build_wash_relays()
	var/atom/movable/screen/sumiari_relay/ink = new
	ink.name = "sumiari ink"
	ink.plane = SUMIARI_RELAY_PLANE
	ink.layer = SUMIARI_RELAY_LAYER_BASE
	ink.alpha = 0
	ink.blockscharging = FALSE
	var/atom/movable/screen/sumiari_relay/sun = new
	sun.name = "sumiari sun"
	sun.plane = SUMIARI_RELAY_PLANE
	sun.layer = SUMIARI_RELAY_LAYER_BASE + 1
	sun.alpha = 0
	sun.blockscharging = FALSE
	screen_pieces += ink
	screen_pieces += sun

// Drop wash filters from the world plane masters. Backdrop filters (occlusion, blur, sight blockers) stay.
/obj/item/organ/eyes/sumiari/proc/clear_master_wash(mob/living/carbon/M)
	var/mob/living/carbon/who = M || owner
	if(!who?.hud_used)
		return
	for(var/plane in GLOB.sumiari_vision_plane_order)
		sumiari_strip_master_wash(who.hud_used.plane_masters["[plane]"])

// One layer per world plane, in draw order. Assigned onto the relay in one write.
/obj/item/organ/eyes/sumiari/proc/world_stack_filters()
	var/list/stacked = list()
	if(!owner?.hud_used)
		return stacked
	for(var/plane in GLOB.sumiari_vision_plane_order)
		var/atom/movable/screen/plane_master/source = owner.hud_used.plane_masters["[plane]"]
		if(!source)
			continue
		stacked += filter(type = "layer", render_source = sumiari_world_render_source(plane), blend_mode = source.blend_mode)
	return stacked

// The moon relay's world stack. Each plane carries its own color: the moon look for the world, and for the mob
// planes a gentler matrix. GAME_PLANE_FOV_HIDDEN holds other mobs, and its plane master layers in the owner's own
// sprite (update_cone() in vision_cone.dm draws it on the hidden GAME_PLANE_OWNER), so that plane takes the mob
// look. GAME_PLANE_UPPER is flora and tree canopies, which take the full moon hue.
// The mob look has no hue push and no violet, so skin and pale sprites keep
// their own tones instead of turning salmon under the crimson/umber push.
/obj/item/organ/eyes/sumiari/proc/moon_stack_filters()
	var/list/stacked = list()
	if(!owner?.hud_used)
		return stacked
	var/list/world_look = sumiari_moon_layer_matrix()
#if SUMIARI_MOON_MOB_NEUTRAL && SUMIARI_MOON_VIVID
	var/list/mob_look = sumiari_moon_mob_matrix()
#else
	var/list/mob_look = world_look
#endif
	var/gain = 1
#if SUMIARI_MOON_KNEE && SUMIARI_MOON_VIVID
	gain = SUMIARI_MOON_LUMINANCE
	// A multiply plane (the open-space backdrop) scales what is under it, so it keeps the full look: the stack under
	// it is already at 1 / gain and the gain comes back once at the end.
	var/list/multiply_look = world_look
	world_look = sumiari_scale_matrix_rgb(world_look, 1 / gain)
	mob_look = sumiari_scale_matrix_rgb(mob_look, 1 / gain)
	var/list/knee_look = sumiari_moon_knee_matrix(world_look, gain)
	var/list/fx_look = sumiari_scale_matrix_rgb(color_matrix_identity(), 1 / gain)
#endif
	for(var/plane in GLOB.sumiari_vision_plane_order)
		var/atom/movable/screen/plane_master/source = owner.hud_used.plane_masters["[plane]"]
		if(!source)
			continue
#if SUMIARI_MOON_KNEE && SUMIARI_MOON_VIVID
		var/list/plane_look = (plane == GAME_PLANE_FOV_HIDDEN) ? mob_look : world_look
		if(source.blend_mode == BLEND_MULTIPLY)
			plane_look = multiply_look
		stacked += filter(type = "layer", render_source = sumiari_world_render_source(plane), blend_mode = source.blend_mode, color = plane_look)
#else
		stacked += filter(type = "layer", render_source = sumiari_world_render_source(plane), blend_mode = source.blend_mode, color = (plane == GAME_PLANE_FOV_HIDDEN) ? mob_look : world_look)
#endif
#if SUMIARI_MOON_KNEE && SUMIARI_MOON_VIVID
		if(plane in GLOB.sumiari_moon_knee_planes)
			stacked += filter(type = "layer", render_source = sumiari_world_render_source(plane), blend_mode = BLEND_SUBTRACT, color = knee_look)
#endif
#if SUMIARI_MOON_FX
		// The moon effects that belong with this plane, right on top of it, in their own colors (no moon grade).
		var/fx_plane = sumiari_fx_plane_for(plane)
		if(fx_plane)
#if SUMIARI_MOON_KNEE && SUMIARI_MOON_VIVID
			stacked += filter(type = "layer", render_source = sumiari_fx_target(fx_plane), blend_mode = BLEND_OVERLAY, color = fx_look)
#else
			stacked += filter(type = "layer", render_source = sumiari_fx_target(fx_plane), blend_mode = BLEND_OVERLAY)
#endif
#endif
	if(gain != 1)
		stacked += filter(type = "color", color = sumiari_scale_matrix_rgb(color_matrix_identity(), gain))
	return stacked

// Planes whose highlights get the knee: ground, walls, objects. Not mobs (neutral, never near 1) or open space.
GLOBAL_LIST_INIT(sumiari_moon_knee_planes, list(FLOOR_PLANE, WALL_PLANE, GAME_PLANE_LOWER, GAME_PLANE, GAME_PLANE_UPPER))

// Every RGB output of a color matrix (rows R, G, B, A and the constants) times scale. Alpha output untouched.
/proc/sumiari_scale_matrix_rgb(list/look, scale)
	var/list/scaled = look.Copy()
	for(var/row in 0 to 4)
		for(var/output in 1 to 3)
			scaled[row * 4 + output] = look[row * 4 + output] * scale
	return scaled

// SLOPE * (look - START / gain): the part of a graded pixel above the knee, for a subtract layer. Alpha kept.
/proc/sumiari_moon_knee_matrix(list/look, gain)
	var/list/knee = sumiari_scale_matrix_rgb(look, SUMIARI_MOON_KNEE_SLOPE)
	for(var/output in 1 to 3)
		knee[16 + output] -= SUMIARI_MOON_KNEE_SLOPE * SUMIARI_MOON_KNEE_START / gain
	return knee

// Moonlight on a mob: out = gain * tint * (luma + saturation * (color - luma)). Tint is the silver ratio pulled
// MOB_SILVER of the way from white and divided by its own luma, so a gray sprite keeps its brightness.
/proc/sumiari_moon_mob_matrix()
	var/list/luma = list(SUMIARI_LUMA_R, SUMIARI_LUMA_G, SUMIARI_LUMA_B)
	var/list/silver = list(SUMIARI_MOON_SILVER_R, SUMIARI_MOON_SILVER_G, SUMIARI_MOON_SILVER_B)
	var/silver_luma = silver[1] * luma[1] + silver[2] * luma[2] + silver[3] * luma[3]
	var/list/look = color_matrix_identity()
	look = look.Copy()
	for(var/output in 1 to 3)
		var/tint = SUMIARI_MOON_MOB_GAIN * (1 + SUMIARI_MOON_MOB_SILVER * (silver[output] / silver_luma - 1))
		for(var/input in 1 to 3)
			look[(input - 1) * 4 + output] = tint * (luma[input] * (1 - SUMIARI_MOON_MOB_SATURATION) + (input == output ? SUMIARI_MOON_MOB_SATURATION : 0))
		look[16 + output] = 0
	return look

// live draws that stack on the ink relay and masks it with *sumiari_mask.
// ink paints the ink matrix onto every world plane master and does not consult the mask.
// color leaves the masters as the backdrop built them. Both relays are hidden in those two modes.
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
	var/atom/movable/screen/sumiari_relay/ink = sumiari_find_piece(src, "sumiari ink")
	var/atom/movable/screen/sumiari_relay/sun = sumiari_find_piece(src, "sumiari sun")
	var/atom/movable/screen/sumiari_relay/moon = sumiari_find_piece(src, "sumiari moon")
	if(wash_mode != SUMIARI_WASH_LIVE)
		if(ink)
			ink.alpha = 0
			ink.filters = null
		if(sun)
			sun.alpha = 0
			sun.filters = null
		if(moon)
			moon.alpha = 0
			moon.filters = null
		return
	if(ink)
		var/list/ink_filters = world_stack_filters()
		ink_filters += filter(type = "color", color = sumiari_color_matrix(SUMIARI_MONO_FULL, 0))
		ink_filters += filter(type = "alpha", render_source = sumiari_offscreen(SUMIARI_TARGET_MASK))
		ink.filters = ink_filters
		ink.alpha = 255
	if(sun)
		var/list/sun_filters = world_stack_filters()
		sun_filters += filter(type = "color", color = sumiari_sun_haze_matrix())
		sun_filters += filter(type = "alpha", render_source = sumiari_offscreen(SUMIARI_TARGET_GLARE))
		sun.filters = sun_filters
		sun.alpha = 255
	if(moon)
		var/list/moon_filters = moon_stack_filters()
		moon_filters += filter(type = "alpha", render_source = sumiari_offscreen(SUMIARI_TARGET_MOON))
		moon.filters = moon_filters
		moon.alpha = 255

// Fades the moon look to a moon fade value over time_ds (0 snaps). The fade rides the moon plate's last color step
// (the mask every moon effect is cut by: vivid color, sheen, shadows and the
// non-fire spares), plus the alpha of the flora halos, which sit outside the plate. Glints take the fade when made.
/obj/item/organ/eyes/sumiari/proc/apply_moon_fade(fade, time_ds)
	if(!vision_on || wash_mode != SUMIARI_WASH_LIVE)
		return
	var/halo_target = round(SUMIARI_FLORA_ALPHA * fade)
	if(time_ds <= 0)
		if(moon_plate)
			animate(moon_plate)
			moon_plate.filters = sumiari_moon_mask_filters(null, fade)
		for(var/plant in flora_images)
			var/image/halo = flora_images[plant]
			halo.alpha = halo_target
		return
	if(moon_plate && length(moon_plate.filters))
		var/peak = sumiari_moon_strength()
#if SUMIARI_MOON_VIVID
		peak *= SUMIARI_MOON_VIVID_LAMP_FADE
#else
		peak *= SUMIARI_MOON_LAMP_GAIN
#endif
		animate(moon_plate.filters[length(moon_plate.filters)], color = sumiari_matrix_moon_alpha(peak * fade), time = time_ds)
	for(var/plant in flora_images)
		var/image/halo = flora_images[plant]
		animate(halo, alpha = halo_target, time = time_ds, flags = ANIMATION_PARALLEL)

// Ink edge (limited to pixels the lighting plane still calls dark) and the night moon silver.
/obj/item/organ/eyes/sumiari/proc/build_flourishes()
#if SUMIARI_INK_VIGNETTE
	add_plate(SUMIARI_PLANE_DARK, SUMIARI_TARGET_DARK, sumiari_offscreen(SUMIARI_TARGET_LIGHT), list(
		filter(type = "color", color = sumiari_matrix_invert_gray()),
		filter(type = "color", color = sumiari_matrix_gray_to_alpha()),
	))
#endif
#if SUMIARI_MOON_TINT
	// Sky plane gray (open sky 1, border partial, roof and cave 0), minus the lamp wash, into alpha.
	// The wash plate already carries the gain, so a fully firelit pixel subtracts to 0 and stays neutral.
	add_plate(SUMIARI_PLANE_MOON, SUMIARI_TARGET_MOON, SUNLIGHTING_RENDER_TARGET, sumiari_moon_mask_filters())
	var/atom/movable/screen/sumiari_relay/moon = new
	moon.name = "sumiari moon"
	moon.plane = SUMIARI_RELAY_PLANE
#if SUMIARI_MOON_VIVID
	// Under the ink relay: artificial light still grays a moonlit pixel by its own wash.
	moon.layer = SUMIARI_RELAY_LAYER_BASE - 1
#else
	moon.layer = SUMIARI_RELAY_LAYER_BASE + 2
#endif
	moon.alpha = 0
	moon.blockscharging = FALSE
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
	if(!vision_on)
		return
	if(glare_plate)
		glare_plate.filters = list(
			filter(type = "color", color = sumiari_matrix_glare_to_alpha()),
		)
	if(moon_plate)
		moon_plate.filters = sumiari_moon_mask_filters()

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

// One cookie channel as brightness: that channel into gray with the falloff alpha kept, then laid over opaque
// black (the static alpha plate with every color zeroed), so the plate holds channel * falloff at alpha 1.
/proc/sumiari_cookie_channel_filters(channel)
	var/list/keep = list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0)
	for(var/output in 1 to 3)
		keep[(channel - 1) * 4 + output] = 1
	return list(
		filter(type = "color", color = keep),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_ALPHA), flags = FILTER_UNDERLAY, color = list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
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

// Gray times SUMIARI_LIGHT_GAIN, alpha kept. The plate clamps at 1, which is the fully lit wash.
/proc/sumiari_matrix_light_gain()
	var/gain = SUMIARI_LIGHT_GAIN
	return list(gain, 0, 0, 0, 0, gain, 0, 0, 0, 0, gain, 0, 0, 0, 0, 1, 0, 0, 0, 0)

// White RGB, alpha = R. The alpha mask filter reads that alpha.
/proc/sumiari_matrix_gray_to_alpha()
	return list(0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0)

// Alpha is 0 below the glare threshold. At a white sun pixel it is the haze scale, which is 0 at
// dawn and at most SUMIARI_SUN_HAZE_CAP at midday. The renderer clamps.
// This reads the sunlight plane, which is grayscale. sun_override forces the sun strength. Null uses the live sun.
// sky_state forces the turf's sky. Border, blocked, and none stay at 0 even when the plane is white.
// A black pixel (cave, lamp, campfire) stays at alpha 0 even at noon, because the bias is negative.
/proc/sumiari_matrix_glare_to_alpha(sun_override, sky_state)
	var/span = SUMIARI_GLARE_FULL - SUMIARI_GLARE_START
	var/day = sumiari_sun_haze_scale(sun_override, sky_state)
	var/scale = day / span
	var/bias = day * (-SUMIARI_GLARE_START / span)
	return list(0, 0, 0, scale, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, bias)

// Moon fade, 0..1, at a station time (null: now). 1 through the night, 0 by day, a smoothstep ramp across
// SUMIARI_MOON_FADE_IN_* (dusk) and SUMIARI_MOON_FADE_OUT_* (early dawn).
/proc/sumiari_moon_phase(time)
	if(isnull(time))
		time = station_time()
	var/ramp
	if(time >= SUMIARI_MOON_FADE_IN_END || time < SUMIARI_MOON_FADE_OUT_START)
		return 1
	if(time >= SUMIARI_MOON_FADE_IN_START)
		ramp = (time - SUMIARI_MOON_FADE_IN_START) / (SUMIARI_MOON_FADE_IN_END - SUMIARI_MOON_FADE_IN_START)
	else if(time < SUMIARI_MOON_FADE_OUT_END)
		ramp = 1 - (time - SUMIARI_MOON_FADE_OUT_START) / (SUMIARI_MOON_FADE_OUT_END - SUMIARI_MOON_FADE_OUT_START)
	else
		return 0
	ramp = clamp(ramp, 0, 1)
	return ramp * ramp * (3 - 2 * ramp)

// Moon fade with the same override as sumiari_moon_strength (TRUE night, FALSE day, null live).
/proc/sumiari_moon_fade(night_override)
	if(!isnull(night_override))
		return night_override ? 1 : 0
	return sumiari_moon_phase()

// TRUE while station time is inside a fade window (the fade ticker runs only then).
/proc/sumiari_moon_fading(time)
	if(isnull(time))
		time = station_time()
	return (time >= SUMIARI_MOON_FADE_IN_START && time < SUMIARI_MOON_FADE_IN_END) || (time >= SUMIARI_MOON_FADE_OUT_START && time < SUMIARI_MOON_FADE_OUT_END)

// Peak moon strength for the silver layer's mask. On through the night and the whole of both fade windows; the
// fade itself rides the mask's last color step (see apply_moon_fade and sumiari_moon_mask_filters).
// night_override forces night (TRUE) or day (FALSE). Null reads the live station time.
/proc/sumiari_moon_strength(night_override)
	if(sumiari_moon_fade(night_override) <= 0 && (!isnull(night_override) || !sumiari_moon_fading()))
		return 0
#if SUMIARI_MOON_VIVID
	return SUMIARI_MOON_VIVID_STRENGTH
#else
	return SUMIARI_MOON_TINT_STRENGTH
#endif

// Sky gray (R of the sky plane, alpha forced 1) over the lamp gain, minus the lamp wash, then strength times gain into alpha.
// Vivid: the ink relay above already grays lamp light, so the subtract only keeps the gain off flames and lamp rims
// (fade is SUMIARI_MOON_VIVID_LAMP_FADE, and the emitter sprites are subtracted at full strength).
// fade (0..1, null = live sumiari_moon_fade) scales the mask's last color step: that is the dusk/dawn fade.
/proc/sumiari_moon_mask_filters(night_override, fade)
	if(isnull(fade))
		fade = sumiari_moon_fade(night_override)
#if SUMIARI_MOON_VIVID
	. = list()
#if SUMIARI_MOON_CLIFFS
	// Wall faces join the sky copy first, in sky units, so everything after treats them like lit ground.
	. += filter(type = "layer", render_source = SUMIARI_CLIFF_RENDER_TARGET, blend_mode = BLEND_ADD)
#endif
	. += list(
		filter(type = "color", color = sumiari_matrix_sky_scaled(1 / SUMIARI_MOON_VIVID_LAMP_FADE)),
		// Feather the open-sky edge (ledges, roofs, cliff tops) so the moon grade fades across it instead of
		// stopping on a tile line. Before the lamp subtract, so firelit pixels stay exactly gray.
		filter(type = "blur", size = SUMIARI_MOON_EDGE_BLUR),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_LIGHT), blend_mode = BLEND_SUBTRACT),
		// Movable lights too (a held torch, a lantern): their pool is gray for these eyes, so the moon stays off it.
		// The cookie is the same brightness the gray mask reads, so the moon never decides what is lit.
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_COOKIE), blend_mode = BLEND_SUBTRACT),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_SOURCE), blend_mode = BLEND_SUBTRACT),
	)
#if SUMIARI_MOON_SPARES_NONFIRE
	// Spared tiles (non-fire light on open moonlit sky) go back to full vivid.
	. += filter(type = "layer", render_source = SUMIARI_SPARE_RENDER_TARGET, blend_mode = BLEND_ADD)
#endif
	. += filter(type = "color", color = sumiari_matrix_moon_alpha(sumiari_moon_strength(night_override) * SUMIARI_MOON_VIVID_LAMP_FADE * fade))
#else
	. = list()
#if SUMIARI_MOON_CLIFFS
	. += filter(type = "layer", render_source = SUMIARI_CLIFF_RENDER_TARGET, blend_mode = BLEND_ADD)
#endif
	. += list(
		filter(type = "color", color = sumiari_matrix_sky_scaled(1 / SUMIARI_MOON_LAMP_GAIN)),
		filter(type = "layer", render_source = sumiari_offscreen(SUMIARI_TARGET_LIGHT), blend_mode = BLEND_SUBTRACT),
		filter(type = "color", color = sumiari_matrix_moon_alpha(sumiari_moon_strength(night_override) * SUMIARI_MOON_LAMP_GAIN * fade)),
	)
#endif

// Sky R copied to gray and scaled, alpha forced to 1. Scaling the sky down before the lamp subtract and the
// strength back up after it gives strength * (sky - gain * lamp) without a second lamp copy.
/proc/sumiari_matrix_sky_scaled(scale)
	return list(scale, scale, scale, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)

// White RGB, alpha = strength * gray. At strength 0 the whole plate is transparent and the relay draws nothing.
/proc/sumiari_matrix_moon_alpha(strength)
	return list(0, 0, 0, strength, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0)

/proc/sumiari_moon_layer_matrix()
#if SUMIARI_MOON_VIVID
	return sumiari_moon_vivid_matrix()
#else
	return sumiari_moon_silver_matrix()
#endif

// Vivid moonlit color: (1 - sheen) * (luma + saturation * (color - luma) + hue shifts) + sheen * cool silver ink.
// Saturation around luma and the projected hue shifts both keep luma, so brightness stays near the plain image.
// Column-major like color_matrix_identity(): input channel rows, then constants.
/proc/sumiari_moon_vivid_matrix(saturation = SUMIARI_MOON_SATURATION, sheen = SUMIARI_MOON_SHEEN, hue_shift = SUMIARI_MOON_HUE_SHIFT)
	var/list/luma = list(SUMIARI_LUMA_R, SUMIARI_LUMA_G, SUMIARI_LUMA_B)
	var/list/tint = list(SUMIARI_MOON_SHEEN_R, SUMIARI_MOON_SHEEN_G, SUMIARI_MOON_SHEEN_B)
	var/list/hue = sumiari_moon_hue_matrix(hue_shift)
	var/list/vivid = color_matrix_identity()
	vivid = vivid.Copy()
	for(var/input in 1 to 3)
		for(var/output in 1 to 3)
			var/boosted = luma[input] * (1 - saturation) + (input == output ? saturation : 0)
			boosted += hue[(input - 1) * 3 + output]
			var/silver = SUMIARI_INK_SLOPE * luma[input] * tint[output]
			vivid[(input - 1) * 4 + output] = SUMIARI_MOON_LUMINANCE * ((1 - sheen) * boosted + sheen * silver)
	for(var/output in 1 to 3)
		vivid[16 + output] = 0
#if SUMIARI_NIGHT_SHADOWS
	// k * violet * (1 - luma): a constant violet, taken back in proportion to the pixel's luma.
	var/list/violet = sumiari_shadow_violet()
	for(var/output in 1 to 3)
		if(!sumiari_night_beauty_enabled)
			break
		vivid[16 + output] += SUMIARI_SHADOW_VIOLET * violet[output]
		for(var/input in 1 to 3)
			vivid[(input - 1) * 4 + output] -= SUMIARI_MOON_LUMINANCE * SUMIARI_SHADOW_VIOLET * luma[input] * violet[output]
#endif
	return vivid

// The blue-violet the shadows lean toward. Mostly blue, so the lift it gives black stays tiny in luma.
/proc/sumiari_shadow_violet()
	return list(SUMIARI_SHADOW_R, SUMIARI_SHADOW_G, SUMIARI_SHADOW_B)

// The hue pushes as a 3x3 offset (row = input channel, flat index (input - 1) * 3 + output), projected onto
// matrices whose rows have zero luma and whose columns sum to zero. Alternating the two projections converges
// to the projection onto both. Built once per filter rebuild, never per tile.
/proc/sumiari_moon_hue_matrix(strength = SUMIARI_MOON_HUE_SHIFT)
	var/list/hue = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	if(!strength)
		return hue
	hue[3] += SUMIARI_MOON_HUE_CRIMSON * strength
	hue[1] += SUMIARI_MOON_HUE_UMBER * strength
	hue[6] += SUMIARI_MOON_HUE_EMERALD * strength
	hue[8] += SUMIARI_MOON_HUE_SAPPHIRE * strength
	hue[2] += SUMIARI_MOON_HUE_EMBER * strength
	var/list/luma = list(SUMIARI_LUMA_R, SUMIARI_LUMA_G, SUMIARI_LUMA_B)
	var/luma_sq = luma[1] * luma[1] + luma[2] * luma[2] + luma[3] * luma[3]
	for(var/pass in 1 to 60)
		for(var/output in 1 to 3)
			var/mean = (hue[output] + hue[3 + output] + hue[6 + output]) / 3
			for(var/input in 1 to 3)
				hue[(input - 1) * 3 + output] -= mean
		for(var/input in 1 to 3)
			var/base = (input - 1) * 3
			var/row_luma = (hue[base + 1] * luma[1] + hue[base + 2] * luma[2] + hue[base + 3] * luma[3]) / luma_sq
			for(var/output in 1 to 3)
				hue[base + output] -= row_luma * luma[output]
	return hue

// The ink curve, with each output channel scaled toward cool silver. A gray sprite turns faintly blue-white.
/proc/sumiari_moon_silver_matrix()
	var/list/ink = sumiari_color_matrix(SUMIARI_MONO_FULL, 0)
	var/list/tint = list(SUMIARI_MOON_SILVER_R, SUMIARI_MOON_SILVER_G, SUMIARI_MOON_SILVER_B)
	var/list/silver = ink.Copy()
	for(var/row in 0 to 4)
		if(row == 3)
			continue
		for(var/channel in 1 to 3)
			var/value = ink[row * 4 + channel]
			if(row == 4)
				value += SUMIARI_MOON_SILVER_LIFT
			silver[row * 4 + channel] = value * tint[channel]
	return silver

// 0 at night, dawn, dusk, sunrise, sunset, and on a border sky. Caps at SUMIARI_SUN_HAZE_CAP in direct midday.
// A number passed in is the sun strength. Null reads the live sun, and then only daytime counts.
// sky_state null skips the turf test. Border does not count as direct sun: the plane is white there anyway.
/proc/sumiari_sun_haze_scale(sun_override, sky_state)
	if(isnum(sky_state) && sky_state != SKY_VISIBLE)
		return 0
	var/sun = sun_override
	if(isnull(sun))
		if(!istype(SSoutdoor_effects?.current_step_datum, /datum/time_of_day/daytime))
			return 0
		sun = sumiari_sun_strength()
	if(sun < SUMIARI_SUN_HAZE_MIN)
		return 0
	var/span = 1 - SUMIARI_SUN_HAZE_MIN
	var/ramp = (sun - SUMIARI_SUN_HAZE_MIN) / span
	if(ramp > 1)
		ramp = 1
	return ramp * SUMIARI_SUN_HAZE_CAP

// A small lift over the ink curve. Same slope, so a dim pixel stays dim. The ink relay does not call this.
/proc/sumiari_sun_haze_matrix()
	var/luma_r = SUMIARI_SUN_HAZE_SLOPE * SUMIARI_LUMA_R
	var/luma_g = SUMIARI_SUN_HAZE_SLOPE * SUMIARI_LUMA_G
	var/luma_b = SUMIARI_SUN_HAZE_SLOPE * SUMIARI_LUMA_B
	return list(
		luma_r, luma_r, luma_r, 0,
		luma_g, luma_g, luma_g, 0,
		luma_b, luma_b, luma_b, 0,
		0, 0, 0, 1,
		SUMIARI_SUN_HAZE_BIAS, SUMIARI_SUN_HAZE_BIAS, SUMIARI_SUN_HAZE_BIAS, 0)

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

// Called on every time-of-day step change and after an admin clock jump: every look snaps to the current
// time at once (no slow fade), then the fade ticker takes over if the clock is inside a fade window.
/proc/sumiari_on_sun_changed()
	var/fade = sumiari_moon_fade()
	for(var/obj/item/organ/eyes/sumiari/eyes as anything in sumiari_active_eyes)
		if(QDELETED(eyes))
			continue
		eyes.refresh_time_filters()
		eyes.apply_wash_filters()
		eyes.apply_moon_fade(fade, 0)
	sumiari_moon_fade_tick(TRUE)

var/global/sumiari_moon_fade_timer

// One fade step: animate every viewer toward the fade one tick from now, over that tick, so the ramp is a smooth
// line between samples. Reschedules itself only while the clock is inside a fade window.
/proc/sumiari_moon_fade_tick(from_sun_change = FALSE)
	if(from_sun_change && sumiari_moon_fade_timer)
		return
	var/was_running = !isnull(sumiari_moon_fade_timer)
	sumiari_moon_fade_timer = null
	var/now = station_time()
	var/later = station_time(FALSE, world.time + SUMIARI_MOON_FADE_TICK)
	if(!sumiari_moon_fading(now) && !sumiari_moon_fading(later))
		if(was_running || !from_sun_change)
			// Window over: settle the mask and the beauty to the plain night or day look.
			for(var/obj/item/organ/eyes/sumiari/eyes as anything in sumiari_active_eyes)
				if(QDELETED(eyes))
					continue
				eyes.refresh_time_filters()
				eyes.apply_wash_filters()
				eyes.apply_moon_fade(sumiari_moon_phase(now), 0)
		return
	var/fade = sumiari_moon_phase(later)
	for(var/obj/item/organ/eyes/sumiari/eyes as anything in sumiari_active_eyes)
		if(QDELETED(eyes))
			continue
		eyes.apply_moon_fade(fade, SUMIARI_MOON_FADE_TICK)
	sumiari_moon_fade_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(sumiari_moon_fade_tick)), SUMIARI_MOON_FADE_TICK, TIMER_STOPPABLE)

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
	var/list/emitters = sumiari_emitters_near(T, 6)
	var/movable = sumiari_movable_from(emitters, T)
	if(!T.has_dynamic_lighting())
		.["intensity"] = 1
		.["sun"] = sun
		.["sun_mask"] = sun_mask
		.["sun_strength"] = sun_strength
		.["dynamic"] = dynamic
		.["movable"] = movable
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
	// Same gain the mask plate applies to the lighting plane, which carries both lamps and sun.
	var/intensity = CLAMP01(((lamps + sun) * SUMIARI_LIGHT_GAIN) + movable)
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
	for(var/atom/source as anything in emitters)
		var/turf/origin = get_turf(source)
		var/ox = origin ? origin.x : 0
		var/oy = origin ? origin.y : 0
		var/kind = (source.light_system == MOVABLE_LIGHT) ? "movable" : "static"
		nearby += "[source.name]@[ox],[oy] power=[source.light_power] range=[source.light_outer_range] [kind]"
		if(length(nearby) >= 8)
			break
	var/hands = sumiari_hands_near(T)
	.["intensity"] = intensity
	.["lamps"] = lamps
	.["raw_peak"] = raw_peak
	.["sun"] = sun
	.["sun_mask"] = sun_mask
	.["sun_strength"] = sun_strength
	.["dynamic"] = dynamic
	.["movable"] = movable
	.["text"] = "sumiari light: [T.x],[T.y],[T.z] area=[T.loc] intensity=[intensity] gain=[SUMIARI_LIGHT_GAIN] source_marked=[sumiari_turf_has_marked_source(T) ? 1 : 0] lamps=[lamps] raw_peak=[raw_peak] sun=[sun] sun_mask=[sun_mask] sun_strength=[sun_strength] sun_state=[sky] sun_overlay_lum=[sun_overlay_lum] falloff=[falloff] movable=[movable] dyn=[dynamic] get_lumcount=[T.get_lumcount()] luminosity=[T.luminosity] overlay=[overlay] softly_lit=[T.is_softly_lit() ? 1 : 0] sun_color=[SSoutdoor_effects?.picked_color] tod=[SSoutdoor_effects?.current_step_datum?.type] corners=\[[corner_text.Join(" | ")]\] lights=\[[nearby.Join(" ; ")]\] hands=\[[hands]\]"

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

// An emitter counts once. Hands, a mob's contents, and one level inside an object (a torch in a sconce).
// range() only sees atoms sitting on the turf, so a torch in a hand was missing from lights= and from intensity.
/proc/sumiari_note_emitter(list/found, list/seen, atom/source)
	if(!source || seen[source])
		return
	seen[source] = TRUE
	if(source.light_power <= 0 || source.light_outer_range <= 0 || !source.light_on)
		return
	found += source

/proc/sumiari_emitters_near(turf/T, span = 6)
	var/list/found = list()
	var/list/seen = list()
	if(!isturf(T))
		return found
	for(var/atom/movable/source in range(span, T))
		sumiari_note_emitter(found, seen, source)
		if(ismob(source))
			var/mob/holder = source
			for(var/obj/item/held in holder.held_items)
				sumiari_note_emitter(found, seen, held)
			for(var/atom/movable/carried in holder.contents)
				sumiari_note_emitter(found, seen, carried)
			continue
		if(!isobj(source))
			continue
		for(var/atom/movable/nested in source.contents)
			sumiari_note_emitter(found, seen, nested)
	return found

/proc/sumiari_movable_from(list/emitters, turf/T)
	var/total = 0
	for(var/atom/source as anything in emitters)
		if(source.light_system != MOVABLE_LIGHT)
			continue
		total += sumiari_point_falloff(T, source)
	return total

/proc/sumiari_movable_brightness(turf/T)
	if(!isturf(T))
		return 0
	return sumiari_movable_from(sumiari_emitters_near(T, 6), T)

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
	var/sun_now = sumiari_sun_haze_scale()
	if(abs(glare_start) > 0.02 || abs(glare_full - sun_now) > 0.02)
		log_world("SUMIARI TEST glare matrix start=[glare_start] full=[glare_full] sun=[sun_now]")
		return FALSE
	var/list/day_matrix = sumiari_matrix_glare_to_alpha(1)
	var/list/night_matrix = sumiari_matrix_glare_to_alpha(0)
	var/day_full = day_matrix[4] + day_matrix[20]
	var/night_full = night_matrix[4] + night_matrix[20]
	var/cave_noon = day_matrix[20]
	var/dawn_strength = 121 / 255
	var/list/dawn_matrix = sumiari_matrix_glare_to_alpha(dawn_strength)
	var/dawn_open = dawn_matrix[4] + dawn_matrix[20]
	var/list/dusk_matrix = sumiari_matrix_glare_to_alpha(0.76)
	var/dusk_open = dusk_matrix[4] + dusk_matrix[20]
	var/border_noon = sumiari_sun_haze_scale(1, SKY_VISIBLE_BORDER)
	if(abs(day_full - SUMIARI_SUN_HAZE_CAP) > 0.02 || day_full > SUMIARI_SUN_HAZE_CAP + 0.001)
		log_world("SUMIARI TEST sun haze noon=[day_full] cap=[SUMIARI_SUN_HAZE_CAP]")
		return FALSE
	if(abs(night_full) > 0.02 || cave_noon > 0.02 || dawn_open > 0.02 || dusk_open > 0.02 || border_noon > 0.02)
		log_world("SUMIARI TEST sun haze night=[night_full] cave=[cave_noon] dawn=[dawn_open] dusk=[dusk_open] border=[border_noon]")
		return FALSE
	if(abs(sumiari_sun_haze_scale(0)) > 0.001 || abs(sumiari_sun_haze_scale(1) - SUMIARI_SUN_HAZE_CAP) > 0.001 || abs(sumiari_sun_haze_scale(dawn_strength)) > 0.001)
		return FALSE
	var/list/ink_untouched = sumiari_color_matrix(SUMIARI_MONO_FULL, 1)
	var/list/haze = sumiari_sun_haze_matrix()
	if(abs(ink_untouched[17] - SUMIARI_INK_LIFT) > 0.001 || abs(haze[17] - SUMIARI_SUN_HAZE_BIAS) > 0.001)
		log_world("SUMIARI TEST ink lift=[ink_untouched[17]] haze bias=[haze[17]]")
		return FALSE
	if(abs(haze[1] - ink_untouched[1]) > 0.001)
		log_world("SUMIARI TEST sun haze slope drifted from the ink curve")
		return FALSE
	var/list/mid_ink = sumiari_apply_matrix(ink_untouched, 0.5, 0.5, 0.5)
	var/list/mid_haze = sumiari_apply_matrix(haze, 0.5, 0.5, 0.5)
	var/noon_lift = (mid_haze[1] - mid_ink[1]) * SUMIARI_SUN_HAZE_CAP
	if(noon_lift < 0 || noon_lift > 0.05)
		log_world("SUMIARI TEST sun haze lift=[noon_lift] is not a subtle midday mix")
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
	sumiari_test_dark_turf = darkest
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

// A lit torch in a hand, on the floor, and in a sconce must raise intensity and show up in lights=.
// This checks the debug numbers. The picture is the cookie plate, which the composite check wires up.
/proc/sumiari_probe_carried_lights(turf/origin)
	if(!isturf(origin))
		log_world("SUMIARI TEST FAIL carried lights had no dark turf")
		return FALSE
	var/before = sumiari_turf_intensity(origin)
	if(!sumiari_probe_held_torch(origin, before))
		return FALSE
	if(!sumiari_probe_dropped_torch(origin, before))
		return FALSE
	if(!sumiari_probe_sconce(origin, before))
		return FALSE
	log_world("SUMIARI TEST carried lights PASS before=[before]")
	return TRUE

/proc/sumiari_emitter_entry(list/sample, name)
	var/text = sample ? sample["text"] : ""
	var/at = findtext(text, "[name]@")
	if(!at)
		return
	return copytext(text, at, min(length(text) + 1, at + 96))

/proc/sumiari_probe_torch_counts(turf/origin, atom/torch, label, before)
	var/near = sumiari_point_falloff(origin, torch)
	var/turf/edge = locate(origin.x + 4, origin.y, origin.z)
	var/far = isturf(edge) ? sumiari_point_falloff(edge, torch) : 0
	var/list/sample = sumiari_light_sample(origin)
	var/entry = sumiari_emitter_entry(sample, torch.name)
	if(near < 0.35 || far >= near)
		log_world("SUMIARI TEST FAIL [label] torch falloff near=[near] far=[far]")
		return FALSE
	if(sample["movable"] < near - 0.02)
		log_world("SUMIARI TEST FAIL [label] torch movable=[sample["movable"]] near=[near] before=[before] [sample["text"]]")
		return FALSE
	if(!entry || !findtext(entry, "movable"))
		log_world("SUMIARI TEST FAIL [label] torch missing from lights= [sample["text"]]")
		return FALSE
	log_world("SUMIARI TEST [label] torch PASS movable=[sample["movable"]] near=[near] far=[far] before=[before]")
	return TRUE

/proc/sumiari_probe_held_torch(turf/origin, before)
	var/mob/living/carbon/human/holder = new(origin)
	var/obj/item/flashlight/flare/torch/torch = new(origin)
	torch.on = TRUE
	torch.update_brightness()
	if(!holder.put_in_hands(torch, FALSE, TRUE, TRUE))
		holder.put_in_hand(torch, 1, TRUE)
	var/held = (torch.loc == holder) && (torch in holder.held_items) && torch.light_on
	var/ok = FALSE
	if(!held)
		log_world("SUMIARI TEST FAIL held torch loc=[torch.loc] light_on=[torch.light_on] on=[torch.on]")
	else
		ok = sumiari_probe_torch_counts(origin, torch, "held", before)
	qdel(holder)
	if(!QDELETED(torch))
		qdel(torch)
	return ok

/proc/sumiari_probe_dropped_torch(turf/origin, before)
	var/obj/item/flashlight/flare/torch/torch = new(origin)
	torch.on = TRUE
	torch.update_brightness()
	var/ok = FALSE
	if(torch.loc != origin || !torch.light_on)
		log_world("SUMIARI TEST FAIL dropped torch loc=[torch.loc] light_on=[torch.light_on]")
	else
		ok = sumiari_probe_torch_counts(origin, torch, "dropped", before)
	qdel(torch)
	return ok

/proc/sumiari_probe_sconce(turf/origin, before)
	var/obj/machinery/light/rogue/torchholder/sconce = new(origin)
	var/obj/item/flashlight/flare/torch/inner = sconce.torchy
	var/ok = FALSE
	if(!inner || inner.loc != sconce || !inner.light_on)
		log_world("SUMIARI TEST FAIL sconce torch loc=[inner?.loc] light_on=[inner?.light_on]")
	else if(!sumiari_probe_torch_counts(origin, inner, "sconce", before))
		ok = FALSE
	else
		var/list/sample = sumiari_light_sample(origin)
		var/entry = sumiari_emitter_entry(sample, sconce.name)
		if(!entry || !findtext(entry, "static"))
			log_world("SUMIARI TEST FAIL sconce missing from lights= [sample["text"]]")
		else
			log_world("SUMIARI TEST sconce fixture PASS [entry]")
			ok = TRUE
	qdel(sconce)
	return ok

// Held items that are off never reach lights=. The live client logged on=1 at fire_act and then a turf with no torch.
/proc/sumiari_hands_near(turf/T)
	var/list/lines = list()
	if(!isturf(T))
		return "none"
	for(var/mob/living/holder in range(6, T))
		for(var/obj/item/I in holder.held_items)
			var/lit = "na"
			if(istype(I, /obj/item/flashlight))
				var/obj/item/flashlight/flare_item = I
				lit = "[flare_item.on]"
			var/datum/component/overlay_lighting/light = I.GetComponent(/datum/component/overlay_lighting)
			var/obj/effect/overlay/light_visible/mask = light?.visible_mask
			var/cookie = "none"
			if(light?.current_holder && mask && (mask in light.current_holder.vis_contents))
				cookie = "[mask.plane]"
			lines += "[I.name] on=[lit] light_on=[I.light_on] power=[I.light_power] range=[I.light_outer_range] cookie=[cookie]"
			if(length(lines) >= 6)
				return lines.Join(" ; ")
	if(!length(lines))
		return "empty"
	return lines.Join(" ; ")

// The local autospawn hook does new(mob), put_in_hands, then fire_act, before the mind transfer.
/proc/sumiari_hook_torch_line(obj/item/flashlight/flare/torch/torch, mob/living/holder, label)
	var/datum/component/overlay_lighting/light = torch?.GetComponent(/datum/component/overlay_lighting)
	var/atom/movable/owner = light?.current_holder
	var/obj/effect/overlay/light_visible/mask = light?.visible_mask
	var/in_vis = FALSE
	if(owner && mask && (mask in owner.vis_contents))
		in_vis = TRUE
	var/in_hands = FALSE
	if(holder && torch && (torch in holder.held_items))
		in_hands = TRUE
	var/in_contents = FALSE
	if(holder && torch && (torch in holder.contents))
		in_contents = TRUE
	var/turf/T = get_turf(torch)
	var/movable = "none"
	var/listed = "none"
	if(isturf(T))
		var/list/sample = sumiari_light_sample(T)
		movable = sample["movable"]
		listed = sumiari_emitter_entry(sample, torch?.name) || "missing"
	log_world("SUMIARI HOOK [label]: on=[torch?.on] light_on=[torch?.light_on] power=[torch?.light_power] range=[torch?.light_outer_range] system=[torch?.light_system] loc=[torch?.loc] in_hands=[in_hands] in_contents=[in_contents] light_owner=[owner] ([owner?.type]) cookie_plane=[mask?.plane] cookie_alpha=[mask?.alpha] cookie_in_vis=[in_vis] dyn=[T?.dynamic_lumcount] movable=[movable] lights=[listed]")

/proc/sumiari_hook_place_line(turf/T, label)
	var/outdoor = "none"
	var/proof = "none"
	var/sky = "none"
	if(T?.outdoor_effect)
		outdoor = "yes"
		proof = "[T.outdoor_effect.weatherproof]"
		sky = sumiari_sky_name(T.outdoor_effect.state)
	var/rain = (SSParticleWeather?.runningWeather?.target_trait == PARTICLEWEATHER_RAIN)
	log_world("SUMIARI HOOK [label] place: [T?.x],[T?.y],[T?.z] type=[T?.type] water=[istype(T, /turf/open/water)] turf_proof=[T?.weatherproof] outdoor=[outdoor] outdoor_proof=[proof] sky=[sky] rain=[rain] weather=[SSParticleWeather?.runningWeather?.type || "none"]")

// Same sequence as the local hook, minus the client. Clothes, an unlit satchel torch, an unlit floor torch, then new(mob) / put_in_hands / fire_act / after_creation.
/proc/sumiari_hook_spawn(turf/spot)
	var/mob/living/carbon/human/species/human/northern/holder = new(spot)
	holder.real_name = "Sumiari Tester"
	holder.name = holder.real_name
	holder.equip_to_slot_or_del(new /obj/item/clothing/suit/roguetown/shirt/undershirt(holder), SLOT_SHIRT, TRUE)
	holder.equip_to_slot_or_del(new /obj/item/clothing/under/roguetown/tights(holder), SLOT_PANTS, TRUE)
	holder.equip_to_slot_or_del(new /obj/item/clothing/shoes/roguetown/simpleshoes(holder), SLOT_SHOES, TRUE)
	var/obj/item/storage/backpack/rogue/satchel/bag = new(holder)
	if(holder.equip_to_slot_or_del(bag, SLOT_BACK_L, TRUE))
		new /obj/item/flashlight/flare/torch(bag)
	var/turf/floor_spot = locate(spot.x, spot.y + 1, spot.z)
	new /obj/item/flashlight/flare/torch(isturf(floor_spot) ? floor_spot : spot)
	var/obj/item/flashlight/flare/torch/held = new(holder)
	sumiari_hook_torch_line(held, holder, "after_new")
	var/placed = holder.put_in_hands(held)
	sumiari_hook_torch_line(held, holder, "after_hands placed=[placed]")
	var/lit = held.fire_act()
	log_world("SUMIARI HOOK fire_act returned [lit] on=[held.on] loc=[held.loc]")
	sumiari_hook_torch_line(held, holder, "after_fire_act")
	holder.after_creation()
	sumiari_hook_torch_line(held, holder, "after_creation")
	return held

/proc/sumiari_hook_torch_ok(obj/item/flashlight/held, mob/living/holder)
	if(QDELETED(held) || QDELETED(holder))
		return FALSE
	if(!held.on || !held.light_on || held.light_power <= 0 || held.light_outer_range <= 0)
		return FALSE
	if(!(held in holder.held_items))
		return FALSE
	var/datum/component/overlay_lighting/light = held.GetComponent(/datum/component/overlay_lighting)
	var/atom/movable/owner = light?.current_holder
	var/obj/effect/overlay/light_visible/mask = light?.visible_mask
	if(owner != holder || !mask || mask.plane != O_LIGHTING_VISUAL_PLANE || !(mask in holder.vis_contents))
		return FALSE
	var/turf/T = get_turf(held)
	if(!isturf(T))
		return FALSE
	var/list/sample = sumiari_light_sample(T)
	var/entry = sumiari_emitter_entry(sample, held.name)
	if(!entry || !findtext(entry, "movable") || sample["movable"] < 0.35)
		return FALSE
	return TRUE

// 71,42,9 is bloody water. Life calls check_drowning, which extinguishes a normal torch. A lamptern is not extinguishable, so it keeps emitting.
/proc/sumiari_probe_hook_torch(turf/origin)
	var/turf/spot = locate(71, 42, 9)
	if(!isturf(spot))
		spot = origin
	if(!isturf(spot))
		log_world("SUMIARI HOOK FAIL no turf")
		return FALSE
	sumiari_hook_place_line(spot, "sync")
	var/obj/item/flashlight/flare/torch/held = sumiari_hook_spawn(spot)
	var/mob/living/holder = held?.loc
	if(!isliving(holder) || !sumiari_hook_torch_ok(held, holder))
		log_world("SUMIARI TEST FAIL hook fire_act torch was not emitting in hand")
		if(isliving(holder))
			qdel(holder)
		if(!QDELETED(held))
			qdel(held)
		return FALSE
	log_world("SUMIARI TEST hook fire_act PASS owner=mob cookie_plane=[O_LIGHTING_VISUAL_PLANE]")
	holder.check_drowning()
	sumiari_hook_torch_line(held, holder, "after_drowning")
	if(held.on || held.light_on)
		log_world("SUMIARI TEST FAIL water left the regular torch lit on=[held.on] light_on=[held.light_on]")
		qdel(holder)
		return FALSE
	log_world("SUMIARI TEST hook water PASS regular torch snuffed, same as a Life tick on this tile")
	qdel(held)
	var/obj/item/flashlight/flare/torch/lantern/lamp = new(holder)
	var/placed = holder.put_in_hands(lamp)
	var/lit = lamp.fire_act()
	log_world("SUMIARI HOOK lantern fire_act returned [lit] placed=[placed] on=[lamp.on] loc=[lamp.loc]")
	holder.check_drowning()
	for(var/tick in 1 to 15)
		if(QDELETED(lamp))
			break
		lamp.process()
	sumiari_hook_torch_line(lamp, holder, "lantern_after_drowning")
	var/lamp_ok = sumiari_hook_torch_ok(lamp, holder)
	qdel(holder)
	if(!QDELETED(lamp))
		qdel(lamp)
	if(!lamp_ok)
		log_world("SUMIARI TEST FAIL lantern did not keep emitting after drowning")
		return FALSE
	log_world("SUMIARI TEST hook lantern PASS still emitting after drowning and 15 process ticks")
	return TRUE

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
	var/expect = "Lit sprites, including the thing that is glowing, turn gray at about their own brightness. A campfire, wisp, held torch, dropped torch, or wall sconce pool is that gray, not full color, and not a white fog. The light itself goes gray. Darkness keeps the sprite color. Dawn, dusk, night, and a border sky stay at that same brightness. Direct midday sun adds only a slight lift. The HUD stays in color. No green or orange cast."
	if(eyes.wash_mode == SUMIARI_WASH_INK)
		expect = "Every world sprite is a gray of its own brightness: grass stays as light as it was, shading stays shading, and textures do not turn into white specks on black. Darkness is that same gray, not a black void and not the sprite color. The HUD, chat, and stat panel stay in color."
	else if(eyes.wash_mode == SUMIARI_WASH_COLOR)
		expect = "Every world sprite keeps its own color, lit or not. No ink, and no green or orange light cast. The HUD stays in color."
	var/line = "sumiari wash test: mode=[eyes.wash_mode] [expect] [sumiari_ink_debug(who, eyes)] [sumiari_plane_legend()]"
	log_world(line)
	to_chat(src, line)

// Which object carries which picture. The wash test prints this so it can be checked against the screen.
/proc/sumiari_plane_legend()
	return "planes: world color is the map planes themselves (sumiari_w*, no asterisk, drawn). Lighting plane [LIGHTING_PLANE] is [SUMIARI_LIGHTING_SOURCE] alpha 255, not drawn. Movable-light plane [O_LIGHTING_VISUAL_PLANE] is [SUMIARI_OLIGHT_SOURCE] alpha 255, not drawn, so a torch cookie does not tint the world. The mask is the max of the lighting capture and that cookie's brightness, max(R, G, B) of its color times its falloff ([sumiari_offscreen(SUMIARI_TARGET_COOKIE)]), copied at view resolution (render_source, SCREEN_SOUTHWEST, no 32×32 resample) into [sumiari_offscreen(SUMIARI_TARGET_MASK)]. [sumiari_offscreen(SUMIARI_TARGET_GLARE)] copies [SUNLIGHTING_RENDER_TARGET], not the lighting plane. Live ink is the sumiari ink relay on plane [SUMIARI_RELAY_PLANE]: every world capture, the ink matrix, then [sumiari_offscreen(SUMIARI_TARGET_MASK)]. Sun haze is the sumiari sun relay above it, masked by [sumiari_offscreen(SUMIARI_TARGET_GLARE)]. Force ink is the ink matrix on every world plane master and hides both relays. HUD is plane [HUD_PLANE]."

// in_screen, plane, every world layer, and the mask. world_matrices counts ink matrices on the plane masters.
// Live mode keeps that count at 0: the matrix sits on the relay, and the layer list is the thing to read.
/proc/sumiari_ink_debug(mob/living/carbon/C, obj/item/organ/eyes/sumiari/eyes)
	var/floor_plane = C?.hud_used?.plane_masters?["[FLOOR_PLANE]"]
	var/matrices = 0
	var/planes = 0
	for(var/plane in GLOB.sumiari_vision_plane_order)
		planes++
		if(sumiari_master_has_ink_matrix(C?.hud_used?.plane_masters?["[plane]"]))
			matrices++
	return "ink_filter live=[sumiari_carrier_debug(C, sumiari_find_piece(eyes, "sumiari ink"), "ink")] sun=[sumiari_carrier_debug(C, sumiari_find_piece(eyes, "sumiari sun"), "sun")] force=[sumiari_carrier_debug(C, floor_plane, "floor")] world_matrices=[matrices]/[planes]"

/proc/sumiari_carrier_debug(mob/living/carbon/C, atom/movable/screen/thing, label)
	var/in_screen = "no"
	if(C?.client && thing && (thing in C.client.screen))
		in_screen = "yes"
	var/mask = "none"
	var/kind = "none"
	var/matrix = "no"
	var/list/sources = sumiari_world_layer_sources(thing)
	if(thing?.filters)
		for(var/sample in thing.filters)
			if(sumiari_filter_is_full_ink(sample) || sumiari_filter_is_sun_haze(sample))
				matrix = "yes"
				kind = length(sources) ? "layer+color" : "color"
			var/render_source = sumiari_filter_field(list(sample), 1, "render_source")
			if(render_source == sumiari_offscreen(SUMIARI_TARGET_MASK) || render_source == sumiari_offscreen(SUMIARI_TARGET_GLARE))
				mask = render_source
	if(length(sources))
		kind = (matrix == "yes") ? "layer+color" : "layer"
	else if(matrix == "yes")
		kind = "color"
	var/expected = length(GLOB.sumiari_vision_plane_order)
	var/listed = length(sources) ? sources.Join(",") : "none"
	var/master = C?.hud_used?.plane_masters?["[thing?.plane]"]
	return "[label]{in_screen=[in_screen] plane=[isnull(thing?.plane) ? "none" : thing.plane] alpha=[isnull(thing?.alpha) ? "none" : thing.alpha] master=[master ? "yes" : "no"] kind=[kind] matrix=[matrix] layers=[length(sources)]/[expected] sources=[listed] mask=[mask]}"

/proc/sumiari_master_has_ink_matrix(atom/movable/screen/plane_master/master)
	if(!master?.filters)
		return FALSE
	for(var/sample in master.filters)
		if(sumiari_filter_is_full_ink(sample))
			return TRUE
	return FALSE

/proc/sumiari_filter_is_sun_haze(sample)
	if(sumiari_filter_kind(sample) != "color")
		return FALSE
	var/color = sample:color
	if(!islist(color) || length(color) < 17)
		return FALSE
	var/list/haze = sumiari_sun_haze_matrix()
	return abs(color[1] - haze[1]) < 0.001 && abs(color[17] - haze[17]) < 0.001

/proc/sumiari_master_layer_source(atom/movable/screen/plane_master/master)
	var/list/sources = sumiari_world_layer_sources(master)
	if(length(sources))
		return sources[1]

// Every world-plane layer on this atom, in filter order. Empty when the atom or the filters are missing.
/proc/sumiari_world_layer_sources(atom/movable/thing)
	var/list/found = list()
	if(!thing?.filters)
		return found
	for(var/sample in thing.filters)
		var/render_source = sumiari_filter_field(list(sample), 1, "render_source")
		if(sumiari_filter_field(list(sample), 1, "blend_mode") == BLEND_SUBTRACT)
			continue
		for(var/plane in GLOB.sumiari_vision_plane_order)
			if(render_source == sumiari_world_render_source(plane))
				found += render_source
				break
	return found

// World captures that are not a layer on thing. The live relays fail the sweep when this is not empty.
/proc/sumiari_missing_world_layers(atom/movable/thing)
	var/list/found = sumiari_world_layer_sources(thing)
	var/list/missing = list()
	for(var/plane in GLOB.sumiari_vision_plane_order)
		var/source = sumiari_world_render_source(plane)
		if(!(source in found))
			missing += source
	return missing

// see_in_dark against the client view. A 15x15 view has radius 7, so 8 covers every tile. Walls still block.
/proc/sumiari_view_coverage(mob/living/carbon/C)
	var/view = C?.client?.view || world.view
	var/list/size = getviewsize(view)
	var/radius = (max(size[1], size[2]) - 1) / 2
	var/covers = C?.see_in_dark >= radius
	return "view=[view] radius=[radius] see_in_dark=[C?.see_in_dark] covers_view=[covers ? "yes" : "NO"]"

// Builds and tears down the composite without a client. The picture itself still needs a player to look at.
/proc/sumiari_runtime_sweep()
	log_world("SUMIARI TEST sweep begin live=[sumiari_screen_live] sun=[sumiari_sun_strength()] sun_haze_scale=[sumiari_sun_haze_scale()]")
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
	if(!sumiari_sweep_moon(eyes))
		failed = TRUE
	if(!sumiari_sweep_beauty(eyes))
		failed = TRUE
	if(!sumiari_sweep_nonfire(eyes))
		failed = TRUE
	if(!sumiari_sweep_moon_fx(eyes))
		failed = TRUE
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
	if(!sumiari_probe_carried_lights(sumiari_test_dark_turf))
		failed = TRUE
	if(!sumiari_probe_hook_torch(sumiari_test_dark_turf))
		failed = TRUE
#if SUMIARI_NIGHT_SENSES
	if(!sumiari_sweep_senses(body, trash))
		failed = TRUE
#endif
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
	var/atom/movable/screen/sumiari_plate/cookie_plate = sumiari_find_piece(eyes, SUMIARI_TARGET_COOKIE)
	var/atom/movable/screen/sumiari_sampler/cookie_sample = sumiari_find_piece(eyes, "[SUMIARI_TARGET_COOKIE] sample")
	if(!cookie_plate || cookie_plate.render_target != sumiari_offscreen(SUMIARI_TARGET_COOKIE))
		bad += "cookie plate=[cookie_plate?.render_target || "none"]"
	else if(cookie_plate.plane >= OPENSPACE_PLANE)
		bad += "cookie plate plane [cookie_plate.plane] can cover the map"
	if(!cookie_sample || cookie_sample.render_source != sumiari_offscreen(SUMIARI_TARGET_COOKIE_GREEN))
		bad += "cookie source=[cookie_sample?.render_source || "none"]"
	for(var/channel_target in list(SUMIARI_TARGET_COOKIE_RED, SUMIARI_TARGET_COOKIE_GREEN, SUMIARI_TARGET_COOKIE_BLUE))
		var/atom/movable/screen/sumiari_sampler/channel_sample = sumiari_find_piece(eyes, "[channel_target] sample")
		if(!channel_sample || channel_sample.render_source != SUMIARI_OLIGHT_SOURCE)
			bad += "cookie channel [channel_target] source=[channel_sample?.render_source || "none"]"
		else if(length(channel_sample.filters) < 2 || sumiari_filter_field(channel_sample.filters, 2, "render_source") != sumiari_offscreen(SUMIARI_TARGET_ALPHA))
			bad += "cookie channel [channel_target] not flattened on black"
	if(cookie_sample && cookie_sample.screen_loc != "SCREEN_SOUTHWEST")
		bad += "cookie anchor=[cookie_sample.screen_loc || "none"]"
	if(!cookie_sample || cookie_sample.sumiari_pixels_x != span[1] || cookie_sample.sumiari_pixels_y != span[2])
		bad += "cookie canvas=[cookie_sample?.sumiari_pixels_x]x[cookie_sample?.sumiari_pixels_y]"
	if(cookie_sample && length(cookie_sample.filters))
		if(sumiari_filter_kind(cookie_sample.filters[1]) == "layer")
			bad += "cookie resamples through a layer filter"
	var/atom/movable/screen/sumiari_sampler/mask_sample = sumiari_find_piece(eyes, "[SUMIARI_TARGET_MASK] sample")
	var/cookie_sub = FALSE
	var/cookie_add = FALSE
	if(mask_sample?.filters)
		for(var/sample in mask_sample.filters)
			if(sumiari_filter_field(list(sample), 1, "render_source") != sumiari_offscreen(SUMIARI_TARGET_COOKIE))
				continue
			var/mode = sumiari_filter_field(list(sample), 1, "blend_mode")
			if(mode == BLEND_SUBTRACT)
				cookie_sub = TRUE
			else if(mode == BLEND_ADD)
				cookie_add = TRUE
	if(!cookie_sub || !cookie_add)
		bad += "mask ignores movable lights"
	var/atom/movable/screen/sumiari_sampler/sun_sample = sumiari_find_piece(eyes, "[SUMIARI_TARGET_GLARE] sample")
	if(!sun_sample || sun_sample.render_source != SUNLIGHTING_RENDER_TARGET)
		bad += "sun mask source=[sun_sample?.render_source || "none"]"
	if(sun_sample && (sun_sample.render_source == SUMIARI_LIGHTING_SOURCE || sun_sample.render_source == sumiari_offscreen(SUMIARI_TARGET_LIGHT)))
		bad += "sun mask reads the lighting plane"
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
		if(eyes.wash_mode == SUMIARI_WASH_LIVE && (has_matrix || has_layer))
			bad += "live wash leaked onto plane [plane]"
		if(eyes.wash_mode == SUMIARI_WASH_INK && has_layer)
			bad += "force ink still stacks plane [plane]"
		if(eyes.wash_mode == SUMIARI_WASH_COLOR && (has_matrix || has_layer))
			bad += "force color still filters plane [plane]"
	var/atom/movable/screen/sumiari_relay/ink_relay = sumiari_find_piece(eyes, "sumiari ink")
	var/atom/movable/screen/sumiari_relay/sun_relay = sumiari_find_piece(eyes, "sumiari sun")
	if(eyes.wash_mode == SUMIARI_WASH_INK)
		if(matrix_planes != present)
			bad += "matrices=[matrix_planes]/[present]"
		if(stacked)
			bad += "force ink stacked=[stacked]"
		if(ink_relay?.alpha || sun_relay?.alpha || length(sumiari_world_layer_sources(ink_relay)) || length(sumiari_world_layer_sources(sun_relay)))
			bad += "force ink relays still drawing"
	else if(eyes.wash_mode == SUMIARI_WASH_COLOR)
		if(matrix_planes || stacked)
			bad += "force color matrices=[matrix_planes] stacked=[stacked]"
		if(ink_relay?.alpha || sun_relay?.alpha || length(sumiari_world_layer_sources(ink_relay)) || length(sumiari_world_layer_sources(sun_relay)))
			bad += "force color relays still drawing"
	else
		var/live_layers = sumiari_relay_layer_problem(ink_relay, "live")
		if(live_layers)
			bad += live_layers
		if(!sumiari_master_has_ink_matrix(ink_relay))
			bad += "live ink matrix missing"
		if(!ink_relay || !length(ink_relay.filters))
			bad += "live mask missing"
		else if(sumiari_filter_field(ink_relay.filters, length(ink_relay.filters), "render_source") != sumiari_offscreen(SUMIARI_TARGET_MASK))
			bad += "live mask missing"
		if(!ink_relay)
			bad += "live ink relay missing"
		else if(ink_relay.alpha != 255 || ink_relay.plane != SUMIARI_RELAY_PLANE || (ink_relay.appearance_flags & NO_CLIENT_COLOR))
			bad += "live ink relay plane=[ink_relay.plane] alpha=[ink_relay.alpha]"
		var/sun_layers = sumiari_relay_layer_problem(sun_relay, "sun")
		if(sun_layers)
			bad += sun_layers
		var/sun_haze = FALSE
		if(sun_relay?.filters)
			for(var/sample in sun_relay.filters)
				if(sumiari_filter_is_sun_haze(sample))
					sun_haze = TRUE
				if(sumiari_filter_is_full_ink(sample))
					bad += "sun relay uses the ink curve"
		if(!sun_haze)
			bad += "sun haze matrix missing"
		if(!sun_relay || !length(sun_relay.filters))
			bad += "sun mask missing"
		else if(sumiari_filter_field(sun_relay.filters, length(sun_relay.filters), "render_source") != sumiari_offscreen(SUMIARI_TARGET_GLARE))
			bad += "sun mask missing"
		if(!sun_relay)
			bad += "sun relay missing"
		else if(sun_relay.alpha != 255 || sun_relay.plane != SUMIARI_RELAY_PLANE || sun_relay.plane >= HUD_PLANE)
			bad += "sun relay plane=[sun_relay.plane] alpha=[sun_relay.alpha]"
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

/proc/sumiari_relay_layer_problem(atom/movable/relay, label)
	var/expected = length(GLOB.sumiari_vision_plane_order)
	var/list/missing = sumiari_missing_world_layers(relay)
	var/found = length(sumiari_world_layer_sources(relay))
	if(!relay || length(missing) || found != expected)
		return "[label] layers=[found]/[expected] missing=[length(missing) ? missing.Join(",") : "relay"]"

/proc/sumiari_scene_blend(obj/item/organ/eyes/sumiari/eyes, plane)
	var/atom/movable/screen/scene = sumiari_find_piece(eyes, "sumiari ink")
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
	var/list/live_sources = sumiari_world_layer_sources(sumiari_find_piece(eyes, "sumiari ink"))
	log_world("SUMIARI TEST wash PASS ink color live layers=[length(live_sources)]/[length(GLOB.sumiari_vision_plane_order)] [live_sources.Join(",")]")
	return TRUE

// Moon relay drawn in live mode, masked by the moon plate. The plate is transparent by day and strength-scaled at night.
/proc/sumiari_sweep_moon(obj/item/organ/eyes/sumiari/eyes)
	var/atom/movable/screen/sumiari_relay/moon = sumiari_find_piece(eyes, "sumiari moon")
	if(!moon || !eyes.moon_plate)
		log_world("SUMIARI TEST FAIL moon tint relay=[moon ? "yes" : "no"] plate=[eyes.moon_plate ? "yes" : "no"]")
		return FALSE
#if SUMIARI_MOON_VIVID
	var/atom/movable/screen/sumiari_relay/ink_relay = sumiari_find_piece(eyes, "sumiari ink")
	if(moon.plane != SUMIARI_RELAY_PLANE || moon.plane >= HUD_PLANE || !ink_relay || moon.layer >= ink_relay.layer)
		log_world("SUMIARI TEST FAIL moon vivid relay plane=[moon.plane] layer=[moon.layer] ink=[ink_relay?.layer]")
		return FALSE
	// A muted green has to come out more saturated (wider channel spread) and a gray has to stay a cool gray.
	var/list/vivid = sumiari_apply_matrix(sumiari_moon_vivid_matrix(), 0.3, 0.5, 0.3)
	var/list/vivid_gray = sumiari_apply_matrix(sumiari_moon_vivid_matrix(), 0.5, 0.5, 0.5)
	// Luma in * LUMINANCE == luma out (within the sheen's slope) for a color and for gray. Orange stays warm, and a dim
	// brown brick stays a low-chroma stone (no pink cast from the cool shadow).
	var/vivid_luma = (vivid[1] * SUMIARI_LUMA_R + vivid[2] * SUMIARI_LUMA_G + vivid[3] * SUMIARI_LUMA_B) / SUMIARI_MOON_LUMINANCE
	var/list/orange = sumiari_apply_matrix(sumiari_moon_vivid_matrix(), 0.6, 0.3, 0.1)
	var/list/brick = sumiari_apply_matrix(sumiari_moon_vivid_matrix(), 0.175, 0.149, 0.116)
	var/brick_chroma = max(brick[1], brick[2], brick[3]) - min(brick[1], brick[2], brick[3])
	if(!(vivid[2] - vivid[1] > 0.2) || !(vivid_gray[3] > vivid_gray[1]) || abs(vivid_gray[2] / SUMIARI_MOON_LUMINANCE - 0.5) > 0.03 || abs(vivid_luma - 0.4431) > 0.03 || !(orange[1] > orange[2] && orange[2] > orange[3]) || brick_chroma > 0.08)
		log_world("SUMIARI TEST FAIL moon vivid matrix green=[vivid[1]],[vivid[2]],[vivid[3]] gray=[vivid_gray[1]],[vivid_gray[2]],[vivid_gray[3]]")
		return FALSE
	if(length(eyes.moon_plate.filters) != 6 + SUMIARI_MOON_SPARES_NONFIRE + SUMIARI_MOON_CLIFFS || sumiari_filter_field(eyes.moon_plate.filters, 5 + SUMIARI_MOON_CLIFFS, "render_source") != sumiari_offscreen(SUMIARI_TARGET_SOURCE) || sumiari_filter_field(eyes.moon_plate.filters, 4 + SUMIARI_MOON_CLIFFS, "render_source") != sumiari_offscreen(SUMIARI_TARGET_COOKIE))
		log_world("SUMIARI TEST FAIL moon vivid mask filters=[length(eyes.moon_plate.filters)]")
		return FALSE
#else
	if(moon.plane != SUMIARI_RELAY_PLANE || moon.plane >= HUD_PLANE || moon.layer <= SUMIARI_RELAY_LAYER_BASE)
		log_world("SUMIARI TEST FAIL moon relay plane=[moon.plane] layer=[moon.layer]")
		return FALSE
#endif
	if(eyes.wash_mode == SUMIARI_WASH_LIVE && sumiari_filter_field(moon.filters, length(moon.filters), "render_source") != sumiari_offscreen(SUMIARI_TARGET_MOON))
		log_world("SUMIARI TEST FAIL moon relay mask missing")
		return FALSE
	var/list/silver = sumiari_moon_silver_matrix()
	var/list/gray = sumiari_apply_matrix(silver, 0.5, 0.5, 0.5)
	if(!(gray[3] > gray[2] && gray[2] > gray[1]))
		log_world("SUMIARI TEST FAIL moon silver is not cool [gray[1]],[gray[2]],[gray[3]]")
		return FALSE
	var/night_strength = SUMIARI_MOON_VIVID ? SUMIARI_MOON_VIVID_STRENGTH : SUMIARI_MOON_TINT_STRENGTH
	if(sumiari_moon_strength(FALSE) != 0 || sumiari_moon_strength(TRUE) != night_strength)
		log_world("SUMIARI TEST FAIL moon strength day=[sumiari_moon_strength(FALSE)] night=[sumiari_moon_strength(TRUE)]")
		return FALSE
	// Moon fade: hours -> expected phase (smoothstep, so the midpoints are exactly 0.5).
	var/list/fade_cases = list("12" = 0, "22" = 1, "3" = 1, "15.5" = 0, "15.75" = 0.5, "16" = 1, "8" = 1, "8.25" = 0.5, "8.5" = 0, "9.5" = 0)
	for(var/hours in fade_cases)
		var/phase = sumiari_moon_phase(text2num(hours) HOURS)
		if(abs(phase - fade_cases[hours]) > 0.001)
			log_world("SUMIARI TEST FAIL moon fade at [hours]h = [phase], expected [fade_cases[hours]]")
			return FALSE
	if(!sumiari_moon_fading(15.6 HOURS) || !sumiari_moon_fading(8.1 HOURS) || sumiari_moon_fading(20 HOURS) || sumiari_moon_fading(12 HOURS))
		log_world("SUMIARI TEST FAIL moon fade windows")
		return FALSE
	log_world("SUMIARI TEST moon PASS silver=[gray[1]],[gray[2]],[gray[3]] strength=[night_strength] vivid=[SUMIARI_MOON_VIVID] saturation=[SUMIARI_MOON_SATURATION] sheen=[SUMIARI_MOON_SHEEN] hue=[SUMIARI_MOON_HUE_SHIFT] luma=[vivid_luma] live=[sumiari_moon_strength()] fade=[sumiari_moon_fade()]")
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

// One shared marker. Each parent draws it with the parent's own icon, state, and dir, on the hidden source plane.
/obj/effect/sumiari_light_marker
	name = ""
	icon = null
	plane = SUMIARI_SOURCE_PLANE
	layer = 0
	appearance_flags = RESET_COLOR | RESET_ALPHA | KEEP_APART
	vis_flags = VIS_INHERIT_ICON | VIS_INHERIT_ICON_STATE | VIS_INHERIT_DIR
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

// Made on first use, not at GLOB init, so it is never an atom created before the atoms subsystem.
GLOBAL_DATUM(sumiari_light_marker, /obj/effect/sumiari_light_marker)

/atom/movable/screen/plane_master/sumiari_light_source
	name = "sumiari light source plane master"
	plane = SUMIARI_SOURCE_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = SUMIARI_SOURCE_RENDER_TARGET

/atom/proc/sumiari_mark_light_source(lit)
	var/obj/effect/sumiari_light_marker/marker = GLOB.sumiari_light_marker
	if(!marker)
		if(!lit)
			return
		marker = new
		GLOB.sumiari_light_marker = marker
	// /atom has no vis_contents. Areas never emit, so only turfs and movables reach here.
	if(isturf(src))
		var/turf/T = src
		var/has = (marker in T.vis_contents)
		if(lit && !has)
			T.vis_contents += marker
		else if(!lit && has)
			T.vis_contents -= marker
		return
	if(ismovable(src))
		var/atom/movable/AM = src
		var/has = (marker in AM.vis_contents)
		if(lit && !has)
			AM.vis_contents += marker
		else if(!lit && has)
			AM.vis_contents -= marker

/proc/sumiari_turf_has_marked_source(turf/T)
	if(!isturf(T) || !GLOB.sumiari_light_marker)
		return FALSE
	if(GLOB.sumiari_light_marker in T.vis_contents)
		return TRUE
	for(var/atom/movable/thing as anything in T)
		if(GLOB.sumiari_light_marker in thing.vis_contents)
			return TRUE
	return FALSE


// ---------------------------------------------------------------------------------------------
// Night senses. See SUMIARI_NIGHT_SENSES at the top for what is and is not revealed.

/obj/item/organ/eyes/sumiari/proc/start_night_senses()
	start_night_beauty()
#if SUMIARI_NIGHT_SENSES
	if(!owner || sense_timer)
		if(owner)
			sense_tick()
		return
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved_senses), override = TRUE)
	sense_timer = addtimer(CALLBACK(src, PROC_REF(sense_tick)), SUMIARI_SENSE_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)
	sense_tick()
#endif

/obj/item/organ/eyes/sumiari/proc/stop_night_senses(mob/living/carbon/M)
	stop_night_beauty()
	var/mob/living/carbon/who = M || owner
	if(who)
		UnregisterSignal(who, COMSIG_MOVABLE_MOVED)
	if(sense_timer)
		deltimer(sense_timer)
		sense_timer = null
	clear_sensed()
	sense_client = null

/obj/item/organ/eyes/sumiari/proc/on_owner_moved_senses(datum/source)
	SIGNAL_HANDLER
	sense_tick()
	place_beauty()
	cliff_tick()
	fx_tick(TRUE)

/obj/item/organ/eyes/sumiari/proc/clear_sensed()
	for(var/mob/living/L as anything in sensed_images)
		var/image/shape = sensed_images[L]
		sense_client?.images -= shape
	sensed_images = null
	sensed_shapes = null

/obj/item/organ/eyes/sumiari/proc/drop_sensed(mob/living/L)
	var/image/shape = sensed_images?[L]
	if(shape)
		sense_client?.images -= shape
	sensed_images -= L
	sensed_shapes -= L

// Why the senses are off for this viewer right now, or null when they work.
/obj/item/organ/eyes/sumiari/proc/sense_blocked()
	if(!vision_on)
		return "vision off"
	var/mob/living/carbon/viewer = owner
	if(!viewer || QDELETED(viewer))
		return "no owner"
	if(!viewer.client)
		return "no client"
	if(viewer.getorganslot(ORGAN_SLOT_EYES) != src)
		return "not these eyes"
	if(viewer.stat >= UNCONSCIOUS)
		return "unconscious"
	if(is_blind(viewer))
		return "blind"
	if(organ_flags & ORGAN_FAILING)
		return "eyes failing"
	return null

/obj/item/organ/eyes/sumiari/proc/sense_tick()
	if(QDELETED(src) || !vision_on)
		stop_night_senses()
		return
	if(sense_client && sense_client != owner?.client)
		clear_sensed()
		sense_client = null
	if(sense_blocked())
		clear_sensed()
		return
	sense_client = owner.client
	var/list/found = sumiari_sense_targets(owner)
	for(var/mob/living/L as anything in sensed_images)
		if(!found[L])
			drop_sensed(L)
	for(var/mob/living/L as anything in found)
		show_sensed(L)

/obj/item/organ/eyes/sumiari/proc/show_sensed(mob/living/L)
	var/turf/here = get_turf(owner)
	var/turf/there = get_turf(L)
	if(!here || !there)
		return
	var/shape_key = "[L.dir]-[L.lying]-[L.icon_state]-[length(L.overlays)]"
	var/image/shape = sensed_images?[L]
	if(shape && sensed_shapes?[L] != shape_key)
		drop_sensed(L)
		shape = null
	if(!shape)
		shape = sumiari_sense_image(L, owner)
		LAZYSET(sensed_images, L, shape)
		LAZYSET(sensed_shapes, L, shape_key)
		sense_client.images += shape
	shape.pixel_x = ((there.x - here.x) * world.icon_size) + L.pixel_x - owner.pixel_x
	shape.pixel_y = ((there.y - here.y) * world.icon_size) + L.pixel_y - owner.pixel_y

// The flat pale silhouette, riding on the viewer so it draws even where the body's own tile does not.
/proc/sumiari_sense_image(mob/living/L, mob/living/viewer)
	var/image/shape = image(loc = viewer)
	shape.appearance = L.appearance
	shape.loc = viewer
	shape.name = ""
	shape.plane = SUMIARI_RELAY_PLANE
	shape.layer = SUMIARI_SENSE_LAYER
	shape.invisibility = 0
	shape.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	shape.appearance_flags = RESET_TRANSFORM | RESET_COLOR | RESET_ALPHA | KEEP_APART | KEEP_TOGETHER
	shape.color = sumiari_sense_tone_matrix()
	shape.filters = list(filter(type = "blur", size = SUMIARI_SENSE_BLUR))
	shape.alpha = SUMIARI_SENSE_ALPHA_LOW
	animate(shape, alpha = SUMIARI_SENSE_ALPHA_HIGH, time = SUMIARI_SENSE_PULSE / 2, loop = -1, easing = SINE_EASING)
	animate(alpha = SUMIARI_SENSE_ALPHA_LOW, time = SUMIARI_SENSE_PULSE / 2, easing = SINE_EASING)
	return shape

// Every pixel becomes the pale tone. Sprite alpha is kept, so the outline is the body's own shape.
/proc/sumiari_sense_tone_matrix()
	return list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, SUMIARI_SENSE_TONE_R, SUMIARI_SENSE_TONE_G, SUMIARI_SENSE_TONE_B, 0)

// Bodies the senses show now, as body -> reason. Scans the turfs in range and the containers on them.
/proc/sumiari_sense_targets(mob/living/carbon/viewer, list/report)
	. = list()
	var/turf/center = get_turf(viewer)
	if(!center)
		return
	var/list/visible = view(SUMIARI_SENSE_RANGE, viewer)
	var/count = 0
	for(var/turf/T in range(SUMIARI_SENSE_RANGE, center))
		for(var/atom/movable/thing as anything in T)
			var/list/bodies
			if(isliving(thing))
				bodies = list(thing)
			else if(istype(thing, /obj/structure))
				for(var/mob/living/inside in thing)
					LAZYADD(bodies, inside)
			for(var/mob/living/L as anything in bodies)
				var/reason = sumiari_sense_reason(viewer, L, visible)
				if(report && L != viewer)
					report += "[L]@[L.x],[L.y] [reason]"
				if(copytext(reason, 1, 7) != "sensed" || count >= SUMIARI_SENSE_MAX)
					continue
				.[L] = reason
				count++

// "sensed: why" when the body should show, otherwise why it does not.
/proc/sumiari_sense_reason(mob/living/carbon/viewer, mob/living/L, list/visible)
	if(!istype(L))
		return "not living"
	if(L == viewer)
		return "self"
	if(L.stat == DEAD)
		return "dead"
	if(L.mob_biotypes & MOB_UNDEAD)
		return "undead"
	if(L.mob_timers?[MT_INVISIBILITY] > world.time)
		return "magic invisibility"
	if(L.invisibility >= INVISIBILITY_OBSERVER || L.invisibility > viewer.see_invisible)
		return "invisible [L.invisibility]"
	var/turf/here = get_turf(viewer)
	var/turf/there = get_turf(L)
	if(!here || !there || here.z != there.z || get_dist(here, there) > SUMIARI_SENSE_RANGE)
		return "out of range"
	var/hidden_in = null
	if(!isturf(L.loc))
		if(!istype(L.loc, /obj/structure) || L.loc.loc != there)
			return "carried or held"
		hidden_in = "in [L.loc]"
	else if(isnull(visible))
		visible = view(SUMIARI_SENSE_RANGE, viewer)
	var/why = hidden_in
	if(!why)
		if(L in visible)
#if SUMIARI_SENSE_SNEAKERS
			if(!L.rogue_sneaking || !viewer.can_see_cone(L))
				return "seen"
			why = "sneaking"
#else
			return "seen"
#endif
		else
			why = "out of sight"
	var/wash = sumiari_turf_intensity(there)
	if(wash >= SUMIARI_SENSE_DARK_MAX)
		return "lit [round(wash, 0.01)]"
	return "sensed: [why] wash=[round(wash, 0.01)]"

/proc/sumiari_sense_report(mob/living/carbon/C)
	var/obj/item/organ/eyes/sumiari/eyes = C?.getorganslot(ORGAN_SLOT_EYES)
	if(!istype(eyes))
		return "sumiari senses: no sumiari eyes"
	var/list/report = list()
	sumiari_sense_targets(C, report)
	var/blocked = eyes.sense_blocked()
	return "sumiari senses: [C]@[C.x],[C.y] blocked=[blocked || "no"] shown=[length(eyes.sensed_images)] timer=[eyes.sense_timer ? "yes" : "no"] near=\[[report.Join(" ; ")]\]"

// Reason logic that does not depend on the map: dead, undead, magic, ghost-level invisibility.
/proc/sumiari_sweep_senses(mob/living/carbon/human/body, list/trash)
	var/turf/spot = get_turf(body)
	var/list/cases = list()
	var/mob/living/carbon/human/dead = new(spot)
	trash += dead
	dead.death()
	cases[dead] = "dead"
	var/mob/living/carbon/human/magic = new(spot)
	trash += magic
	magic.mob_timers[MT_INVISIBILITY] = world.time + 1 MINUTES
	cases[magic] = "magic invisibility"
	var/mob/living/carbon/human/jaunt = new(spot)
	trash += jaunt
	jaunt.invisibility = INVISIBILITY_OBSERVER
	cases[jaunt] = "invisible"
	cases[body] = "self"
	for(var/mob/living/L as anything in cases)
		var/reason = sumiari_sense_reason(body, L, list())
		if(copytext(reason, 1, length(cases[L]) + 1) != cases[L])
			log_world("SUMIARI TEST FAIL senses [cases[L]] gave [reason]")
			return FALSE
	var/list/tone = sumiari_apply_matrix(sumiari_sense_tone_matrix(), 0.1, 0.9, 0.3)
	if(abs(tone[1] - SUMIARI_SENSE_TONE_R) > 0.001 || abs(tone[3] - SUMIARI_SENSE_TONE_B) > 0.001)
		log_world("SUMIARI TEST FAIL senses tone [tone.Join(",")]")
		return FALSE
	log_world("SUMIARI TEST senses PASS range=[SUMIARI_SENSE_RANGE] dark_max=[SUMIARI_SENSE_DARK_MAX] interval=[SUMIARI_SENSE_INTERVAL]")
	return TRUE


// ---------------------------------------------------------------------------------------------
// Night beauty. See SUMIARI_NIGHT_* at the top. The moon shadows ride the moon relay's color (masked to open
// moonlit sky with no lamp); glints and night-bloom halos are client images on their turf or plant that only
// the owner's client holds. None of it runs by day, and none of it touches another viewer.

// Runtime switch for every night-beauty feature at once (the defines pick which exist). An admin can flip it
// with View Variables and the next filter rebuild or beauty tick follows.
var/global/sumiari_night_beauty_enabled = TRUE

/proc/sumiari_is_moon_night()
	return sumiari_moon_strength() > 0

// Night-bloom registry, by z. Plants never move, so only spawn and delete touch it.
var/global/list/sumiari_night_flora = list()

/proc/sumiari_register_flora(obj/plant, add)
	if(!plant)
		return
	var/turf/T = get_turf(plant)
	if(!T)
		return
	var/key = "[T.z]"
	if(add)
		if(!sumiari_night_flora[key])
			sumiari_night_flora[key] = list()
		sumiari_night_flora[key] |= plant
	else if(sumiari_night_flora[key])
		sumiari_night_flora[key] -= plant

/obj/structure/glowshroom/Initialize(mapload)
	. = ..()
	sumiari_register_flora(src, TRUE)

/obj/structure/glowshroom/Destroy()
	sumiari_register_flora(src, FALSE)
	return ..()

/obj/structure/flora/mushroomcluster/Initialize(mapload)
	. = ..()
	sumiari_register_flora(src, TRUE)

/obj/structure/flora/mushroomcluster/Destroy()
	sumiari_register_flora(src, FALSE)
	return ..()

/proc/sumiari_solid_matrix(color_text)
	var/list/rgb = rgb2num(color_text)
	return list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 0)

// A soft halo cut from the plant's own sprite: tinted solid, blurred, then the sprite itself masked back out.
/proc/sumiari_flora_image(obj/plant, mob/viewer)
	var/image/halo = image(plant.icon, viewer || plant, plant.icon_state)
	halo.name = ""
	halo.plane = SUMIARI_BEAUTY_PLANE
	halo.layer = SUMIARI_FLORA_LAYER
	halo.dir = plant.dir
	halo.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	halo.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART | KEEP_TOGETHER
	halo.color = sumiari_solid_matrix(SUMIARI_FLORA_COLOR_A)
	halo.filters = list(
		filter(type = "blur", size = SUMIARI_FLORA_BLUR),
		filter(type = "alpha", icon = sumiari_flora_cutout(plant), flags = MASK_INVERSE),
	)
	halo.alpha = round(SUMIARI_FLORA_ALPHA * sumiari_moon_fade())
	animate(halo, color = sumiari_solid_matrix(SUMIARI_FLORA_COLOR_B), time = SUMIARI_FLORA_PERIOD / 2, loop = -1, easing = SINE_EASING)
	animate(color = sumiari_solid_matrix(SUMIARI_FLORA_COLOR_A), time = SUMIARI_FLORA_PERIOD / 2, easing = SINE_EASING)
	return halo

// Turfs that hold dew under the moon (grass and snow), for SUMIARI_GLINT_DEW.
GLOBAL_LIST_INIT(sumiari_dew_turfs, typecacheof(list(
	/turf/open/floor/rogue/grass,
	/turf/open/floor/rogue/grasscold,
	/turf/open/floor/rogue/grasspurple,
	/turf/open/floor/rogue/grassgrey,
	/turf/open/floor/rogue/grassred,
	/turf/open/floor/rogue/grassyel,
	/turf/open/floor/rogue/snow,
	/turf/open/floor/rogue/snowrough,
	/turf/open/floor/rogue/snowpatchy,
)))

// A tile that may glint: open sky, not lit by any lamp, and water, a wet floor, or a metal item on it.
/proc/sumiari_glint_spot(turf/T)
	if(!isopenturf(T))
		return FALSE
	if(T.outdoor_effect?.state != SKY_VISIBLE)
		return FALSE
	var/shiny = istype(T, /turf/open/water) || IS_WET_OPEN_TURF(T)
#if SUMIARI_GLINT_DEW
	shiny ||= is_type_in_typecache(T, GLOB.sumiari_dew_turfs)
#endif
	if(!shiny)
		for(var/obj/item/thing in T)
			if(thing.smeltresult)
				shiny = TRUE
				break
	if(!shiny || (locate(/mob/living) in T))
		return FALSE
	return sumiari_turf_intensity(T) < SUMIARI_SENSE_DARK_MAX

/obj/item/organ/eyes/sumiari/proc/start_night_beauty()
#if SUMIARI_NIGHT_GLINTS || SUMIARI_NIGHT_FLORA
	if(!owner || beauty_timer)
		return
	beauty_timer = addtimer(CALLBACK(src, PROC_REF(beauty_tick)), SUMIARI_BEAUTY_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)
	beauty_tick()
#endif

/obj/item/organ/eyes/sumiari/proc/stop_night_beauty()
	if(beauty_timer)
		deltimer(beauty_timer)
		beauty_timer = null
	clear_beauty()
	clear_spare()
	clear_cliffs()
	clear_fx()

/obj/item/organ/eyes/sumiari/proc/clear_beauty()
	for(var/image/glint as anything in glint_images)
		beauty_client?.images -= glint
	for(var/plant in flora_images)
		beauty_client?.images -= flora_images[plant]
	glint_images = null
	flora_images = null
	glint_spots = null
	glint_center = null
	beauty_anchors = null
	beauty_client = null

/obj/item/organ/eyes/sumiari/proc/beauty_tick()
	if(QDELETED(src) || !vision_on)
		stop_night_beauty()
		return
	spare_tick()
	cliff_tick()
	fx_tick()
	if(beauty_client && beauty_client != owner?.client)
		clear_beauty()
	if(!sumiari_night_beauty_enabled || sense_blocked() || wash_mode != SUMIARI_WASH_LIVE || !sumiari_is_moon_night())
		clear_beauty()
		return
	beauty_client = owner.client
	var/turf/center = get_turf(owner)
	if(!center)
		clear_beauty()
		return
#if SUMIARI_NIGHT_GLINTS
	beauty_glints(center)
#endif
#if SUMIARI_NIGHT_FLORA
	beauty_flora(center)
#endif

/obj/item/organ/eyes/sumiari/proc/beauty_glints(turf/center)
	for(var/image/old as anything in glint_images)
		if(glint_images[old] <= world.time)
			beauty_client.images -= old
			glint_images -= old
			LAZYREMOVE(beauty_anchors, old)
	// Shiny tiles in view, rescanned only when the owner changes tile or every SUMIARI_GLINT_RESCAN ticks.
	if(glint_center != center || ++glint_age >= SUMIARI_GLINT_RESCAN)
		glint_center = center
		glint_age = 0
		glint_spots = list()
		// view(), not range(): the glints draw above the walls, so only tiles the owner sees may glint.
		for(var/turf/T in view(SUMIARI_GLINT_RADIUS, owner))
			if(sumiari_glint_spot(T))
				glint_spots += T
				if(length(glint_spots) >= SUMIARI_GLINT_SPOT_MAX)
					break
	if(!length(glint_spots) || length(glint_images) >= SUMIARI_GLINT_MAX || !prob(SUMIARI_GLINT_CHANCE))
		return
	for(var/attempt in 1 to SUMIARI_GLINT_TRIES)
		var/turf/T = pick(glint_spots)
		if(!sumiari_glint_spot(T))
			continue
		// The game's own item glint: a 13-frame four-point twinkle.
		// The glint lives on its own tile, so it moves with the map (no re-offset while the owner glides).
		var/image/glint = image('icons/roguetown/items/misc.dmi', T, "glint")
		glint.loc = T
		glint.plane = SUMIARI_BEAUTY_PLANE
		glint.layer = SUMIARI_GLINT_LAYER
		glint.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		glint.color = SUMIARI_GLINT_COLOR
		glint.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART
		// No filter here: a drop_shadow on this KEEP_APART image hid the whole twinkle in the client.
#if SUMIARI_GLINT_CORE
		var/image/core = image('icons/effects/light_overlays/light_32.dmi', "light")
		core.color = SUMIARI_GLINT_CORE_COLOR
		core.alpha = SUMIARI_GLINT_CORE_ALPHA
		core.transform = matrix() * SUMIARI_GLINT_CORE_SCALE
		glint.underlays += core
#endif
		LAZYSET(beauty_anchors, glint, list(T, rand(-10, 10), rand(-10, 10)))
		place_beauty_image(glint)
		glint.alpha = 0
		glint.transform = matrix() * SUMIARI_GLINT_LOW_SCALE
		var/half = SUMIARI_GLINT_CYCLE / 2
		var/fade = sumiari_moon_fade()
		// Looping twinkle; the image is dropped after SUMIARI_GLINT_LIFE. Its alphas follow the moon fade.
		animate(glint, alpha = round(SUMIARI_GLINT_ALPHA * fade), transform = matrix() * SUMIARI_GLINT_SCALE, time = half, loop = -1, easing = SINE_EASING)
		animate(alpha = round(SUMIARI_GLINT_LOW_ALPHA * fade), transform = matrix() * SUMIARI_GLINT_LOW_SCALE, time = half, easing = SINE_EASING)
		LAZYSET(glint_images, glint, world.time + SUMIARI_GLINT_LIFE)
		beauty_client.images += glint
		return

/obj/item/organ/eyes/sumiari/proc/beauty_flora(turf/center)
	var/list/near = list()
	var/list/seen
	for(var/obj/plant as anything in sumiari_night_flora["[center.z]"])
		if(QDELETED(plant) || get_dist(plant, center) > SUMIARI_FLORA_RANGE || !sumiari_flora_shows(plant))
			continue
		// The halos draw above the walls, so a plant behind one shows none. One view() per tick, only when needed.
		seen ||= view(SUMIARI_FLORA_RANGE, owner)
		if(!(plant in seen))
			continue
		near[plant] = TRUE
		if(length(near) >= SUMIARI_FLORA_MAX)
			break
	for(var/plant in flora_images)
		if(!near[plant])
			beauty_client.images -= flora_images[plant]
			LAZYREMOVE(beauty_anchors, flora_images[plant])
			flora_images -= plant
	for(var/obj/plant as anything in near)
		if(flora_images?[plant])
			continue
		// The halo lives on the plant itself, so it is locked to the plant's tile while the owner walks.
		var/image/halo = sumiari_flora_image(plant)
		LAZYSET(flora_images, plant, halo)
		LAZYSET(beauty_anchors, halo, list(plant, 0, 0))
		place_beauty_image(halo)
		beauty_client.images += halo

// Night beauty checks that do not depend on the map or the time of day.
/proc/sumiari_sweep_beauty(obj/item/organ/eyes/sumiari/eyes)
	var/list/bad = list()
	sumiari_night_beauty_enabled = FALSE
#if SUMIARI_NIGHT_SHADOWS
	var/list/plain = sumiari_apply_matrix(sumiari_moon_vivid_matrix(), 0, 0, 0)
#endif
	sumiari_night_beauty_enabled = TRUE
#if SUMIARI_NIGHT_SHADOWS
	var/list/shadow = sumiari_apply_matrix(sumiari_moon_vivid_matrix(), 0, 0, 0)
	var/list/white = sumiari_apply_matrix(sumiari_moon_vivid_matrix(), 1, 1, 1)
#endif
	var/list/violet = sumiari_shadow_violet()
	var/violet_luma = violet[1] * SUMIARI_LUMA_R + violet[2] * SUMIARI_LUMA_G + violet[3] * SUMIARI_LUMA_B
	if(SUMIARI_SHADOW_VIOLET * violet_luma > 0.06)
		bad += "violet lift=[SUMIARI_SHADOW_VIOLET * violet_luma]"
#if SUMIARI_NIGHT_SHADOWS
	// Black leans cool indigo (blue first, then green, at most a trace of red, so warm browns never go pink), white is untouched
	// by the shadow term (only the sheen tints it).
	if(!(shadow[3] > plain[3]) || !(shadow[3] > shadow[2] && shadow[2] >= shadow[1]) || abs(white[1] - white[2]) > 0.15)
		bad += "shadow black=[shadow[1]],[shadow[2]],[shadow[3]] white=[white[1]],[white[2]],[white[3]]"
#endif
	if(length(eyes.screen_pieces) > SUMIARI_PIECE_CAP)
		bad += "pieces=[length(eyes.screen_pieces)]"
	if(!("glint" in icon_states('icons/roguetown/items/misc.dmi')) || !("light" in icon_states('icons/effects/light_overlays/light_32.dmi')))
		bad += "icons"
	var/turf/spot = get_turf(eyes.owner)
	var/obj/structure/glowshroom/shroom = new(spot)
	var/key = "[spot.z]"
	var/registered = (shroom in sumiari_night_flora[key])
	var/image/halo = sumiari_flora_image(shroom, eyes.owner)
	if(!registered || halo.plane != SUMIARI_BEAUTY_PLANE || halo.layer >= FLASH_LAYER)
		bad += "flora registered=[registered] plane=[halo.plane] layer=[halo.layer]"
	qdel(shroom)
	if(shroom in sumiari_night_flora[key])
		bad += "flora not released"
#if SUMIARI_MOON_MOB_NEUTRAL && SUMIARI_MOON_VIVID
	// Pale skin (0.95, 0.69, 0.6, the humen sprite unlit) must not get redder, and must stay red > green > blue.
	// White (1, 1, 1) must stay near neutral (channels within 6%) and must not clip.
	var/list/mob_look = sumiari_moon_mob_matrix()
	var/list/skin = sumiari_apply_matrix(mob_look, 0.95, 0.69, 0.6)
	if(skin[1] / max(skin[2], 0.01) > 0.95 / 0.69 || !(skin[1] > skin[2] && skin[2] > skin[3]))
		bad += "mob skin cast=[skin[1]],[skin[2]],[skin[3]]"
	var/list/mob_white = sumiari_apply_matrix(mob_look, 1, 1, 1)
	if(max(mob_white[1], mob_white[2], mob_white[3]) > 1 || max(mob_white[1], mob_white[2], mob_white[3]) > min(mob_white[1], mob_white[2], mob_white[3]) * 1.06)
		bad += "mob white cast=[mob_white[1]],[mob_white[2]],[mob_white[3]]"
#endif
	if(length(bad))
		log_world("SUMIARI TEST FAIL beauty [bad.Join(" ")]")
		return FALSE
	log_world("SUMIARI TEST beauty PASS glints=[SUMIARI_NIGHT_GLINTS] shadows=[SUMIARI_NIGHT_SHADOWS] flora=[SUMIARI_NIGHT_FLORA] pieces=[length(eyes.screen_pieces)]")
	return TRUE

// Beauty images ride on the owner: offset each one to its anchor tile again.
/obj/item/organ/eyes/sumiari/proc/place_beauty()
	for(var/image/picture as anything in beauty_anchors)
		place_beauty_image(picture)

/obj/item/organ/eyes/sumiari/proc/place_beauty_image(image/picture)
	var/list/anchor = beauty_anchors?[picture]
	// Images that live on their anchor (glints on their tile, halos on their plant) only take the fixed offset;
	// they move with the map on their own, so walking never re-offsets them.
	if(anchor && picture.loc == anchor[1])
		picture.pixel_x = anchor[2]
		picture.pixel_y = anchor[3]
		return
	var/turf/here = get_turf(owner)
	var/turf/there = anchor ? get_turf(anchor[1]) : null
	if(!here || !there)
		return
	picture.pixel_x = ((there.x - here.x) * world.icon_size) + anchor[2] - owner.pixel_x
	picture.pixel_y = ((there.y - here.y) * world.icon_size) + anchor[3] - owner.pixel_y

// A halo never sits over a body, and only a glowshroom's own glow may light its tile: any other lamp keeps it gray.
/proc/sumiari_flora_shows(obj/plant)
	var/turf/T = get_turf(plant)
	if(!T || (locate(/mob/living) in T))
		return FALSE
	if(istype(plant, /obj/structure/glowshroom))
		return TRUE
	return sumiari_turf_intensity(T) < SUMIARI_SENSE_DARK_MAX

// The plant's sprite with every pixel that has any alpha made solid: the halo is cut out of the whole sprite,
// including a glowshroom's own faint glow square, so a light-source sprite keeps its gray look.
/proc/sumiari_flora_cutout(obj/plant)
	var/static/list/cutouts = list()
	var/key = "[plant.icon]|[plant.icon_state]|[plant.dir]"
	if(cutouts[key])
		return cutouts[key]
	var/icon/cutout = icon(plant.icon, plant.icon_state, plant.dir, 1)
	cutout.MapColors(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 255, 0, 0, 0, 0)
	cutouts[key] = cutout
	return cutout


// ---------------------------------------------------------------------------------------------
// Moon spares non-fire light. See SUMIARI_MOON_SPARES_NONFIRE at the top.

// Flames. Any subtype counts. Add a path here to keep a new flame gray under the moon.
GLOBAL_LIST_INIT(sumiari_fire_light_types, typecacheof(list(
	/obj/machinery/light/rogue,			// campfire, fireplace, brazier, standing fire, sconce, candles, wall/skull candles, hearth, oven, forge, smelter, chandelier, cauldron, lantern post
	/obj/machinery/light/roguestreet,	// oil street lamps
	/obj/item/flashlight/flare,			// torches, flares, lanterns, lampterns (bronze, void)
	/obj/item/candle,
	/obj/item/lighter,
	/obj/item/clothing/mask/cigarette,
	/obj/structure/fluff/statue/gargoyle/candles,
	/obj/structure/fluff/statue/gargoyle/moss/candles,
	/obj/structure/life_candle,
	/obj/effect/hotspot,
)))

// Checked first: subtypes of a flame path that are not flames.
GLOBAL_LIST_INIT(sumiari_nonfire_light_types, typecacheof(list(
	/obj/item/flashlight/flare/light,	// condensed light (the Light spell orb), a flare subtype
	/obj/structure/glowshroom,			// kneestingers
	/obj/structure/flora,				// glowing moss, glow flowers and shrooms (flammable, but not burning)
	/obj/structure/fluff/statue/gargoyle/moss,	// mossy gargoyles glow; the candle one is a flame and is listed above
	/obj/item/natural,					// glowing herbs and drops
	/obj/item/reagent_containers/food/snacks/grown,
)))
// Exceptions to the exceptions: these are flames even though a non-fire path above covers them.
GLOBAL_LIST_INIT(sumiari_fire_light_overrides, typecacheof(list(
	/obj/structure/fluff/statue/gargoyle/moss/candles,
)))

// Flame or not. Exceptions, then the flame paths, then anything actually burning. Everything else is not a flame.
/proc/sumiari_light_is_fire(atom/source)
	if(!source)
		return FALSE
	// Anything actually burning is a flame, whatever it is (a kneestinger set alight).
	if(isobj(source))
		var/obj/thing = source
		if(thing.resistance_flags & ON_FIRE)
			return TRUE
	if(is_type_in_typecache(source, GLOB.sumiari_fire_light_overrides))
		return TRUE
	if(is_type_in_typecache(source, GLOB.sumiari_nonfire_light_types))
		return FALSE
	if(is_type_in_typecache(source, GLOB.sumiari_fire_light_types))
		return TRUE
	if(isliving(source))
		var/mob/living/burning = source
		if(burning.on_fire)
			return TRUE
	return FALSE

// Open moonlit sky, the same tiles the moon mask calls sky (open or its border), never roofed or underground.
/proc/sumiari_spare_turf_open(turf/T)
	return T?.outdoor_effect && T.outdoor_effect.state != SKY_BLOCKED

// A tile the moon reaches: open sky, or a wall face beside open sky (the moon plate spills onto it). Without the wall
// faces, a calm light against a cliff carved a dark gray disc out of the moonlit rock.
/proc/sumiari_spare_moonlit(turf/T)
	if(!T)
		return FALSE
	if(sumiari_spare_turf_open(T))
		return TRUE
	if(!isclosedturf(T))
		return FALSE
	for(var/dir in GLOB.cardinals)
		if(sumiari_spare_turf_open(get_step(T, dir)))
			return TRUE
	return FALSE

// Really lighting right now: lighting_atom and overlay_lighting put the shared marker on an emitter only while it is lit.
// light_on alone is TRUE on an unlit condensed-light orb.
/proc/sumiari_spare_emits(atom/movable/source)
	return istype(source) && GLOB.sumiari_light_marker && (GLOB.sumiari_light_marker in source.vis_contents)

/atom/movable/screen/plane_master/sumiari_moon_spare
	name = "sumiari moon spare plane master"
	plane = SUMIARI_SPARE_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = SUMIARI_SPARE_RENDER_TARGET

// Runtime switch for the moon sparing non-fire light (the define decides whether it exists). View Variables can flip it.
var/global/sumiari_moon_spares_enabled = TRUE

/obj/item/organ/eyes/sumiari/proc/clear_spare()
	for(var/emitter in spare_images)
		spare_client?.images -= spare_images[emitter]
	spare_images = null
	spare_keys = null
	spare_client = null

// Once per beauty tick: which open-sky tiles around each nearby non-fire light no flame reaches.
/obj/item/organ/eyes/sumiari/proc/spare_tick()
#if SUMIARI_MOON_SPARES_NONFIRE
	if(spare_client && spare_client != owner?.client)
		clear_spare()
	var/turf/center = get_turf(owner)
	if(!sumiari_moon_spares_enabled || !owner?.client || !center || wash_mode != SUMIARI_WASH_LIVE || !sumiari_is_moon_night())
		clear_spare()
		return
	spare_client = owner.client
	var/list/fires = list()
	var/list/calm = list()
	for(var/atom/source as anything in sumiari_emitters_near(center, SUMIARI_SPARE_SCAN))
		if(!get_turf(source))
			continue
		if(sumiari_light_is_fire(source))
			fires += source
		else if(sumiari_spare_emits(source))
			calm += source
	var/list/fire_lit = sumiari_spare_fire_tiles(fires)
	// Open space shows the level below: a candle or forge down there must keep the tiles above it gray too, and a
	// kneestinger down there must keep its glow in moon color when seen from above (its gray cookie shows through).
	var/list/fire_lit_below
	var/list/calm_below = list()
	var/turf/below_center = GET_TURF_BELOW(center)
	if(below_center)
		var/list/fires_below = list()
		for(var/atom/source as anything in sumiari_emitters_near(below_center, SUMIARI_SPARE_SCAN))
			if(!get_turf(source))
				continue
			if(sumiari_light_is_fire(source))
				fires_below += source
			else if(sumiari_spare_emits(source))
				calm_below += source
		if(length(fires_below))
			fire_lit_below = sumiari_spare_fire_tiles(fires_below)
	calm = sumiari_nearest_first(calm + calm_below, center, SUMIARI_SPARE_MAX_EMITTERS)
	var/list/keep = list()
	for(var/atom/source as anything in calm)
		var/turf/lamp = get_turf(source)
		// A light on the level below is drawn on this level's tiles above it, where open space shows it.
		var/below = (lamp.z != center.z)
		var/turf/origin = below ? locate(lamp.x, lamp.y, center.z) : lamp
		if(!origin)
			continue
		var/range = clamp(CEILING(source.light_outer_range + SUMIARI_SPARE_MARGIN + SUMIARI_SPARE_FEATHER, 1), 1, SUMIARI_SPARE_RANGE_MAX)
		var/list/tiles = list()
		var/list/key_parts = list("[origin.x],[origin.y],[origin.z],[below]")
		for(var/dx in -range to range)
			for(var/dy in -range to range)
				if((dx * dx) + (dy * dy) > range * range)
					continue
				var/turf/T = locate(origin.x + dx, origin.y + dy, origin.z)
				if(!T || fire_lit[T])
					continue
				if(below)
					// Only through open space, onto moonlit ground down there that no flame down there reaches.
					var/turf/down = locate(lamp.x + dx, lamp.y + dy, lamp.z)
					if(!istransparentturf(T) || !down || (fire_lit_below && fire_lit_below[down]))
						continue
					if(!sumiari_spare_moonlit(down) && !sumiari_spare_moonlit(T))
						continue
				else
					if(!sumiari_spare_moonlit(T))
						continue
					if(fire_lit_below && istransparentturf(T) && fire_lit_below[GET_TURF_BELOW(T)])
						continue
				var/strength = sumiari_spare_strength(source, dx, dy)
				if(strength < SUMIARI_SPARE_MIN)
					continue
				tiles += list(list(dx, dy, strength))
				key_parts += "[dx]:[dy]:[strength]"
		if(!length(tiles))
			continue
		keep[source] = TRUE
		var/key = key_parts.Join(";")
		if(spare_keys?[source] == key)
			continue
		if(spare_images?[source])
			spare_client.images -= spare_images[source]
		var/image/spare = sumiari_spare_image(origin, tiles)
		LAZYSET(spare_images, source, spare)
		LAZYSET(spare_keys, source, key)
		spare_client.images += spare
	for(var/source in spare_images)
		if(!keep[source])
			spare_client.images -= spare_images[source]
			spare_images -= source
			spare_keys -= source
#endif

// The emitters sorted nearest first (a level below counts as one tile farther), at most cap of them.
/proc/sumiari_nearest_first(list/emitters, turf/center, cap)
	var/list/buckets = list()
	for(var/atom/source as anything in emitters)
		var/turf/T = get_turf(source)
		var/dist = max(abs(T.x - center.x), abs(T.y - center.y)) + abs(T.z - center.z) + 1
		while(length(buckets) < dist)
			buckets += list(list())
		var/list/bucket = buckets[dist]
		bucket += source
	var/list/sorted = list()
	for(var/list/bucket as anything in buckets)
		for(var/source in bucket)
			if(length(sorted) >= cap)
				return sorted
			sorted += source
	return sorted

// Tiles a flame can light: within its range (plus half a tile) and in its view, so a wall candle behind a wall
// does not keep the open sky outside gray. One view() per flame per tick.
/proc/sumiari_spare_fire_tiles(list/fires)
	var/list/lit = list()
	for(var/atom/fire as anything in fires)
		var/turf/F = get_turf(fire)
		if(!F)
			continue
		var/reach = fire.light_outer_range + 0.5
		for(var/turf/T in view(CEILING(reach, 1), F))
			var/dx = F.x - T.x
			var/dy = F.y - T.y
			if((dx * dx) + (dy * dy) <= reach * reach)
				lit[T] = TRUE
	return lit

// The light's own falloff at an offset from its tile, the same shape the lighting system draws: distance with the
// lighting height, inner range, falloff curve, power, and how bright its color is. Any light system.
/proc/sumiari_spare_falloff(atom/source, dx, dy)
	if(!source || source.light_power <= 0 || source.light_outer_range <= 0)
		return 0
	var/range = source.light_outer_range
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

// How strongly a tile is spared: full wherever the light reaches (its falloff plus a tile of margin, since the
// lighting corners carry a light about a tile past its nominal range), then a soft feather to nothing. A spare
// weaker than the light it cancels would leave a dim gray ring, so this never follows the falloff below 1 inside.
// Quantized to 1/16 so a flickering range does not rebuild the image every tick.
/proc/sumiari_spare_strength(atom/source, dx, dy)
	if(dx == 0 && dy == 0)
		return 1
	var/reach = source.light_outer_range + SUMIARI_SPARE_MARGIN
	var/dist = sqrt((dx * dx) + (dy * dy))
	var/strength = CLAMP01((reach - dist) / SUMIARI_SPARE_FEATHER)
	strength = max(strength, CLAMP01(sumiari_spare_falloff(source, dx, dy) * SUMIARI_LIGHT_GAIN * SUMIARI_SPARE_COVER))
	return round(strength * 16) / 16

// One image per emitter: white tiles on the hidden spare plane, each as strong as the light is there (offset[3],
// default full), blurred together so the edge is a soft fade.
/proc/sumiari_spare_image(turf/origin, list/tiles)
	var/image/spare = image(null, origin)
	spare.plane = SUMIARI_SPARE_PLANE
	spare.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART | KEEP_TOGETHER
	spare.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/list/squares = list()
	for(var/list/offset as anything in tiles)
		var/image/square = image('icons/effects/alphacolors.dmi', null, "white")
		square.color = "#ffffff"
		square.alpha = round(255 * (length(offset) >= 3 ? offset[3] : 1))
		square.pixel_x = offset[1] * world.icon_size
		square.pixel_y = offset[2] * world.icon_size
		squares += square
	spare.overlays = squares
#if SUMIARI_SPARE_BLUR
	spare.filters = filter(type = "blur", size = SUMIARI_SPARE_BLUR)
#endif
	return spare

// ---------------------------------------------------------------------------------------------
// Moonlit wall faces. See SUMIARI_MOON_CLIFFS at the top.

/atom/movable/screen/plane_master/sumiari_moon_cliff
	name = "sumiari moon cliff plane master"
	plane = SUMIARI_CLIFF_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = SUMIARI_CLIFF_RENDER_TARGET

/obj/item/organ/eyes/sumiari/proc/clear_cliffs()
	for(var/turf/T as anything in cliff_images)
		cliff_client?.images -= cliff_images[T]
	cliff_images = null
	cliff_keys = null
	cliff_client = null

// Every step and every beauty tick: closed turfs around the owner, each with its corners' sky light. Only a turf
// whose corners changed gets a new image, so a still night costs one pass over the square and no image churn.
/obj/item/organ/eyes/sumiari/proc/cliff_tick()
#if SUMIARI_MOON_CLIFFS
	if(cliff_client && cliff_client != owner?.client)
		clear_cliffs()
	var/turf/center = get_turf(owner)
	if(!vision_on || !owner?.client || !center || wash_mode != SUMIARI_WASH_LIVE || !sumiari_is_moon_night())
		clear_cliffs()
		return
	cliff_client = owner.client
	var/list/keep = list()
	var/turf/low = locate(max(center.x - SUMIARI_CLIFF_RANGE, 1), max(center.y - SUMIARI_CLIFF_RANGE, 1), center.z)
	var/turf/high = locate(min(center.x + SUMIARI_CLIFF_RANGE, world.maxx), min(center.y + SUMIARI_CLIFF_RANGE, world.maxy), center.z)
	for(var/turf/T as anything in block(low, high))
		if(!isclosedturf(T) || T.outdoor_effect)
			continue
		var/list/corners = T.corners
		if(!corners)
			continue
		// The same corner order the sky overlay uses (update_outdoor_effect_overlays).
		var/datum/lighting_corner/cr = corners[3]
		var/datum/lighting_corner/cg = corners[2]
		var/datum/lighting_corner/cb = corners[4]
		var/datum/lighting_corner/ca = corners[1]
		var/fr = cr ? cr.sunFalloff : 0
		var/fg = cg ? cg.sunFalloff : 0
		var/fb = cb ? cb.sunFalloff : 0
		var/fa = ca ? ca.sunFalloff : 0
		if(max(fr, fg, fb, fa) < SUMIARI_CLIFF_MIN)
			continue
		keep[T] = TRUE
		var/key = "[fr]|[fg]|[fb]|[fa]"
		if(cliff_keys?[T] == key)
			continue
		if(cliff_images?[T])
			cliff_client.images -= cliff_images[T]
		var/image/face = sumiari_cliff_image(T, fr, fg, fb, fa)
		LAZYSET(cliff_images, T, face)
		LAZYSET(cliff_keys, T, key)
		cliff_client.images += face
	for(var/turf/T as anything in cliff_images)
		if(!keep[T])
			cliff_client.images -= cliff_images[T]
			cliff_images -= T
			cliff_keys -= T
#endif

// What the sky overlay would draw on an open tile with these corners (create_sunlight_overlay), on the cliff plane.
/proc/sumiari_cliff_image(turf/T, fr, fg, fb, fa)
	var/image/face = image(LIGHTING_ICON, T)
	face.icon_state = null
	face.plane = SUMIARI_CLIFF_PLANE
	face.layer = 1
	face.blend_mode = BLEND_OVERLAY
	face.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART
	face.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	face.color = sumiari_cliff_matrix(fr, fg, fb, fa)
	return face

/proc/sumiari_cliff_matrix(fr, fg, fb, fa)
	return list(fr, fr, fr, 0, fg, fg, fg, 0, fb, fb, fb, 0, fa, fa, fa, 0, 0, 0, 0, 1)

// Classification, plumbing, and one live spare image.
/proc/sumiari_sweep_nonfire(obj/item/organ/eyes/sumiari/eyes)
	var/list/bad = list()
#if SUMIARI_MOON_SPARES_NONFIRE
	var/list/fire_paths = list(/obj/machinery/light/rogue/campfire, /obj/machinery/light/rogue/candle, /obj/machinery/light/rogue/torchholder,
		/obj/machinery/light/rogue/firebowl, /obj/machinery/light/rogue/oven, /obj/machinery/light/roguestreet, /obj/item/flashlight/flare/torch,
		/obj/item/flashlight/flare/torch/lantern, /obj/item/flashlight/flare/torch/lantern/bronzelamptern, /obj/item/candle)
	var/list/calm_paths = list(/obj/structure/glowshroom, /obj/effect/wisp, /obj/item/flashlight/flare/light)
	for(var/path in fire_paths)
		if(!is_type_in_typecache(path, GLOB.sumiari_fire_light_types) || is_type_in_typecache(path, GLOB.sumiari_nonfire_light_types))
			bad += "fire [path]"
	for(var/path in calm_paths)
		if(is_type_in_typecache(path, GLOB.sumiari_fire_light_types) && !is_type_in_typecache(path, GLOB.sumiari_nonfire_light_types))
			bad += "calm [path]"
	var/atom/movable/screen/plane_master/spare_master = eyes.owner?.hud_used?.plane_masters["[SUMIARI_SPARE_PLANE]"]
	if(!spare_master || spare_master.render_target != SUMIARI_SPARE_RENDER_TARGET)
		bad += "spare plane master"
	var/list/moon_filters = sumiari_moon_mask_filters(TRUE)
	if(sumiari_filter_field(moon_filters, 6 + SUMIARI_MOON_CLIFFS, "render_source") != SUMIARI_SPARE_RENDER_TARGET || sumiari_filter_field(moon_filters, 6 + SUMIARI_MOON_CLIFFS, "blend_mode") != BLEND_ADD)
		bad += "moon mask has no spare add"
#if SUMIARI_MOON_CLIFFS
	var/atom/movable/screen/plane_master/cliff_master = eyes.owner?.hud_used?.plane_masters["[SUMIARI_CLIFF_PLANE]"]
	if(!cliff_master || cliff_master.render_target != SUMIARI_CLIFF_RENDER_TARGET)
		bad += "cliff plane master"
	if(sumiari_filter_field(moon_filters, 1, "render_source") != SUMIARI_CLIFF_RENDER_TARGET || sumiari_filter_field(moon_filters, 1, "blend_mode") != BLEND_ADD)
		bad += "moon mask has no cliff add"
	var/list/half = sumiari_cliff_matrix(1, 0.5, 0, 0)
	if(half[1] != 1 || half[5] != 0.5 || half[20] != 1)
		bad += "cliff matrix"
#endif
	var/atom/movable/screen/sumiari_sampler/mask = null
	for(var/atom/movable/screen/sumiari_sampler/sampler in eyes.screen_pieces)
		if(sampler.name == "[SUMIARI_TARGET_MASK] sample")
			mask = sampler
	if(!mask || sumiari_filter_field(mask.filters, length(mask.filters) - 1, "render_source") != SUMIARI_SPARE_RENDER_TARGET || sumiari_filter_field(mask.filters, length(mask.filters) - 1, "blend_mode") != BLEND_SUBTRACT)
		bad += "ink mask has no spare subtract"
	var/turf/origin = get_turf(eyes.owner)
	var/image/spare = sumiari_spare_image(origin, list(list(0, 0), list(1, 0, 0.5)))
	if(spare.plane != SUMIARI_SPARE_PLANE || length(spare.overlays) != 2)
		bad += "spare image plane=[spare.plane] tiles=[length(spare.overlays)]"
	// The spare follows the light's falloff: strongest at the light, fading with distance, gone past its range.
	// A bare nullspace obj with light vars set directly: nothing actually lights.
	var/obj/probe = new /obj(null)
	probe.light_outer_range = 4
	probe.light_inner_range = 0
	probe.light_power = 1
	probe.light_color = "#ffffff"
	var/fall_near = sumiari_spare_falloff(probe, 0, 1)
	var/fall_mid = sumiari_spare_falloff(probe, 2, 0)
	var/fall_far = sumiari_spare_falloff(probe, 5, 0)
	qdel(probe)
	if(!(fall_near > fall_mid && fall_mid > 0 && fall_far == 0))
		bad += "spare falloff near=[fall_near] mid=[fall_mid] far=[fall_far]"
	// A flame within reach blocks a tile, one out of reach does not.
	var/obj/machinery/light/rogue/campfire/fire = new(origin)
	var/list/fires = list(fire)
	var/turf/near = locate(origin.x + 1, origin.y, origin.z)
	var/turf/far = locate(origin.x + fire.brightness + 4, origin.y, origin.z)
	var/list/fire_lit = sumiari_spare_fire_tiles(fires)
	if(near && !near.opacity && !fire_lit[near])
		bad += "near flame not blocking"
	if(far && fire.light_outer_range < 4 && fire_lit[far])
		bad += "far flame blocking range=[fire.light_outer_range]"
	qdel(fire)
	if(length(eyes.screen_pieces) > SUMIARI_PIECE_CAP)
		bad += "pieces=[length(eyes.screen_pieces)]"
#endif
	if(length(bad))
		log_world("SUMIARI TEST FAIL nonfire [bad.Join(" ")]")
		return FALSE
	log_world("SUMIARI TEST nonfire PASS spares=[SUMIARI_MOON_SPARES_NONFIRE] fire_types=[length(GLOB.sumiari_fire_light_types)] calm_overrides=[length(GLOB.sumiari_nonfire_light_types)]")
	return TRUE


// ---------------------------------------------------------------------------------------------
// Moon effects. See SUMIARI_MOON_FX at the top.

var/global/sumiari_moon_water_enabled = TRUE
var/global/sumiari_moon_rims_enabled = TRUE
var/global/sumiari_moon_dew_enabled = TRUE
var/global/sumiari_moon_bloom_enabled = TRUE
var/global/sumiari_moon_shade_enabled = TRUE

/atom/movable/screen/plane_master/sumiari_fx_floor
	name = "sumiari moon effects (ground) plane master"
	plane = SUMIARI_FX_FLOOR_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = SUMIARI_FX_FLOOR_TARGET

/atom/movable/screen/plane_master/sumiari_fx_lower
	name = "sumiari moon effects (structures) plane master"
	plane = SUMIARI_FX_LOWER_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = SUMIARI_FX_LOWER_TARGET

/atom/movable/screen/plane_master/sumiari_fx_game
	name = "sumiari moon effects (water) plane master"
	plane = SUMIARI_FX_GAME_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = SUMIARI_FX_GAME_TARGET

/atom/movable/screen/plane_master/sumiari_fx_upper
	name = "sumiari moon effects (canopy) plane master"
	plane = SUMIARI_FX_UPPER_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = SUMIARI_FX_UPPER_TARGET

// The hidden effect plane layered right after a world plane, or null.
/proc/sumiari_fx_plane_for(host_plane)
	switch(host_plane)
		if(FLOOR_PLANE)
			return SUMIARI_FX_FLOOR_PLANE
		if(GAME_PLANE_LOWER)
			return SUMIARI_FX_LOWER_PLANE
		if(GAME_PLANE)
			return SUMIARI_FX_GAME_PLANE
		if(GAME_PLANE_UPPER)
			return SUMIARI_FX_UPPER_PLANE
	return null

// The effect plane for something drawn on host_plane: the nearest one at or below it in the world stack.
/proc/sumiari_fx_plane_near(host_plane)
	if(host_plane <= FLOOR_PLANE)
		return SUMIARI_FX_FLOOR_PLANE
	if(host_plane < GAME_PLANE)
		return SUMIARI_FX_LOWER_PLANE
	if(host_plane < GAME_PLANE_UPPER)
		return SUMIARI_FX_GAME_PLANE
	return SUMIARI_FX_UPPER_PLANE

/proc/sumiari_fx_target(fx_plane)
	switch(fx_plane)
		if(SUMIARI_FX_FLOOR_PLANE)
			return SUMIARI_FX_FLOOR_TARGET
		if(SUMIARI_FX_LOWER_PLANE)
			return SUMIARI_FX_LOWER_TARGET
		if(SUMIARI_FX_GAME_PLANE)
			return SUMIARI_FX_GAME_TARGET
		if(SUMIARI_FX_UPPER_PLANE)
			return SUMIARI_FX_UPPER_TARGET
	return null

// Common look of an effect image: on its hidden plane, never tinted, faded or scaled by what it sits on, never clicked.
/proc/sumiari_fx_style(image/picture, fx_plane)
	picture.name = ""
	picture.plane = fx_plane
	picture.layer = 1
	picture.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	picture.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART
	return picture

// A fully transparent 32x32 icon to draw on (the lighting gradient with every channel mapped to 0).
/proc/sumiari_blank_icon()
	var/icon/blank = icon(LIGHTING_ICON, "")
	blank.MapColors(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	return blank

/proc/sumiari_fx_silver(alpha)
	return rgb(SUMIARI_FX_SILVER_R, SUMIARI_FX_SILVER_G, SUMIARI_FX_SILVER_B, alpha)

/obj/item/organ/eyes/sumiari/proc/clear_fx()
	for(var/key in fx_images)
		fx_client?.images -= fx_images[key]
	for(var/image/dew as anything in fx_dew_images)
		fx_client?.images -= dew
	fx_dew_images = null
	fx_dew_spots = null
	fx_bloom = null
	fx_images = null
	fx_states = null
	fx_center = null
	fx_age = 0
	fx_client = null

// Every beauty tick, and on every step (moved). Rescans the tiles around the owner when they changed tile or every
// FX_RESCAN ticks; the per-tick live parts (dew, bloom) run on the timer only.
/obj/item/organ/eyes/sumiari/proc/fx_tick(moved = FALSE)
#if SUMIARI_MOON_FX
	if(fx_client && fx_client != owner?.client)
		clear_fx()
	var/turf/center = get_turf(owner)
	if(!sumiari_night_beauty_enabled || !center || sense_blocked() || wash_mode != SUMIARI_WASH_LIVE || !sumiari_is_moon_night())
		clear_fx()
		return
	if(fx_center && fx_center.z != center.z)
		clear_fx()
	fx_client = owner.client
	if(fx_center != center || ++fx_age >= SUMIARI_FX_RESCAN)
		fx_center = center
		fx_age = 0
		fx_scan(center)
	if(!moved)
		fx_live(center)
#endif

/obj/item/organ/eyes/sumiari/proc/fx_scan(turf/center)
	var/list/wanted = list()
	// Shade: turf -> TRUE/FALSE, whether it blocks the moon, filled as the shade asks.
	var/list/blockers = list()
	fx_dew_spots = null
	if(isnull(fx_bloom))
		fx_bloom = sumiari_bloom_level()
	var/turf/low = locate(max(center.x - SUMIARI_FX_RANGE, 1), max(center.y - SUMIARI_FX_RANGE, 1), center.z)
	var/turf/high = locate(min(center.x + SUMIARI_FX_RANGE, world.maxx), min(center.y + SUMIARI_FX_RANGE, world.maxy), center.z)
	for(var/turf/T as anything in block(low, high))
#if SUMIARI_MOON_WATER
		if(sumiari_moon_water_enabled)
			fx_water(T, wanted)
#endif
#if SUMIARI_MOON_RIMS
		if(sumiari_moon_rims_enabled)
			fx_rims(T, wanted)
#endif
#if SUMIARI_MOON_DEW
		if(sumiari_moon_dew_enabled && LAZYLEN(fx_dew_spots) < SUMIARI_DEW_SPOTS_MAX && is_type_in_typecache(T, GLOB.sumiari_dew_turfs) && sumiari_spare_turf_open(T))
			LAZYADD(fx_dew_spots, T)
#endif
#if SUMIARI_MOON_BLOOM
		if(sumiari_moon_bloom_enabled)
			fx_blooms(T, wanted)
#endif
#if SUMIARI_MOON_SHADE
		if(sumiari_moon_shade_enabled)
			fx_shade(T, wanted, blockers)
#endif
	for(var/key in fx_images)
		if(!wanted[key])
			fx_drop(key)

// Effects that change between scans. Each effect adds its own part here.
/obj/item/organ/eyes/sumiari/proc/fx_live(turf/center)
#if SUMIARI_MOON_DEW
	fx_dew()
#endif
#if SUMIARI_MOON_BLOOM
	fx_bloom_ease()
#endif

// Marks key as wanted this scan; TRUE when its image must be (re)built because the state changed.
/obj/item/organ/eyes/sumiari/proc/fx_want(key, state, list/wanted)
	wanted[key] = TRUE
	return fx_states?[key] != state

/obj/item/organ/eyes/sumiari/proc/fx_put(key, state, image/picture)
	if(fx_images?[key])
		fx_client.images -= fx_images[key]
	LAZYSET(fx_images, key, picture)
	LAZYSET(fx_states, key, state)
	fx_client.images += picture

/obj/item/organ/eyes/sumiari/proc/fx_drop(key)
	fx_client?.images -= fx_images?[key]
	LAZYREMOVE(fx_images, key)
	LAZYREMOVE(fx_states, key)

// 1) Moonlit water.
/obj/item/organ/eyes/sumiari/proc/fx_water(turf/T, list/wanted)
	if(!istype(T, /turf/open/water) || !sumiari_spare_turf_open(T))
		return
	var/key = "w[T.x],[T.y]"
	if(fx_want(key, "1", wanted))
		fx_put(key, "1", sumiari_water_image(T))

/proc/sumiari_water_image(turf/T)
	var/variant = ((T.x * 7 + T.y * 13) % SUMIARI_WATER_VARIANTS) + 1
	var/image/ripple = sumiari_fx_style(image(sumiari_water_icon(variant), T), SUMIARI_FX_GAME_PLANE)
	var/period = SUMIARI_WATER_PERIOD + ((T.x * 31 + T.y * 17) % 5) * 4
	var/drift = (variant == 2) ? -1 : 1
	ripple.alpha = SUMIARI_WATER_ALPHA_LOW
	animate(ripple, alpha = SUMIARI_WATER_ALPHA_HIGH, pixel_x = 2 * drift, time = period / 2, loop = -1, easing = SINE_EASING)
	animate(alpha = SUMIARI_WATER_ALPHA_LOW, pixel_x = -drift, time = period / 2, easing = SINE_EASING)
	return ripple

// Dashes as list(x, y, length), inside 3..29 so a two-pixel drift never leaves the tile.
/proc/sumiari_water_dashes(variant)
	switch(variant)
		if(1)
			return list(list(5, 22, 7), list(16, 13, 9), list(8, 6, 5))
		if(2)
			return list(list(14, 25, 6), list(4, 15, 8), list(19, 7, 7))
	return list(list(9, 19, 9), list(20, 26, 5), list(13, 9, 6))

/proc/sumiari_water_icon(variant)
	var/static/list/made = list()
	if(made["[variant]"])
		return made["[variant]"]
	var/icon/ripples = sumiari_blank_icon()
	for(var/list/dash as anything in sumiari_water_dashes(variant))
		var/x = dash[1]
		var/y = dash[2]
		var/length = dash[3]
		ripples.DrawBox(sumiari_fx_silver(SUMIARI_WATER_END_ALPHA), x, y)
		ripples.DrawBox(sumiari_fx_silver(SUMIARI_WATER_CORE_ALPHA), x + 1, y, x + length - 2, y)
		ripples.DrawBox(sumiari_fx_silver(SUMIARI_WATER_END_ALPHA), x + length - 1, y)
	made["[variant]"] = ripples
	return ripples

// 2) Moon-edge highlights.
GLOBAL_LIST_INIT(sumiari_rim_types, typecacheof(list(
	/obj/structure/flora/roguetree,
	/obj/structure/roguerock,
	/obj/structure/flora/rogueshroom,
	/obj/structure/flora/roguegrass/bush,
)))

/obj/item/organ/eyes/sumiari/proc/fx_rims(turf/T, list/wanted)
	if(isclosedturf(T))
		var/sides = 0
		for(var/side in list(NORTH, WEST, EAST))
			var/turf/next = get_step(T, side)
			if(next && !isclosedturf(next) && sumiari_spare_turf_open(next))
				sides |= side
		if(!sides)
			return
		var/key = "e[T.x],[T.y]"
		if(fx_want(key, "[sides]", wanted))
			fx_put(key, "[sides]", sumiari_fx_style(image(sumiari_rim_icon(sides), T), SUMIARI_FX_LOWER_PLANE))
		return
	if(!sumiari_spare_turf_open(T))
		return
	for(var/obj/thing in T)
		if(!is_type_in_typecache(thing, GLOB.sumiari_rim_types) || thing.invisibility || !thing.icon_state)
			continue
		var/key = "r[REF(thing)]"
		var/state = "[thing.icon]|[thing.icon_state]|[thing.dir]|[thing.plane]"
		if(fx_want(key, state, wanted))
			fx_put(key, state, sumiari_rim_image(thing))

// The wall rim for a set of sides (NORTH, WEST, EAST bits): outer pixel bright, the one inside it faint.
/proc/sumiari_rim_icon(sides)
	var/static/list/made = list()
	if(made["[sides]"])
		return made["[sides]"]
	var/icon/rim = sumiari_blank_icon()
	if(sides & NORTH)
		rim.DrawBox(sumiari_fx_silver(SUMIARI_RIM_INNER_ALPHA), 1, 31, 32, 31)
	if(sides & WEST)
		rim.DrawBox(sumiari_fx_silver(SUMIARI_RIM_INNER_ALPHA), 2, 1, 2, 32)
	if(sides & EAST)
		rim.DrawBox(sumiari_fx_silver(SUMIARI_RIM_INNER_ALPHA), 31, 1, 31, 32)
	if(sides & NORTH)
		rim.DrawBox(sumiari_fx_silver(SUMIARI_RIM_OUTER_ALPHA), 1, 32, 32, 32)
	if(sides & WEST)
		rim.DrawBox(sumiari_fx_silver(SUMIARI_RIM_OUTER_ALPHA), 1, 1, 1, 32)
	if(sides & EAST)
		rim.DrawBox(sumiari_fx_silver(SUMIARI_RIM_OUTER_ALPHA), 32, 1, 32, 32)
	made["[sides]"] = rim
	return rim

// The object's own sprite in solid silver, minus itself shifted one pixel right and down: what is left are the
// pixels whose up-left neighbour is outside the sprite, the edge that faces the moon. Rides the object (its offset
// and transform), so it stays glued to the sprite.
/proc/sumiari_rim_image(obj/thing)
	var/image/rim = image(thing.icon, thing, thing.icon_state)
	rim.dir = thing.dir
	sumiari_fx_style(rim, sumiari_fx_plane_near(thing.plane))
	rim.appearance_flags = RESET_COLOR | RESET_ALPHA | KEEP_APART
	rim.color = sumiari_solid_matrix(sumiari_fx_silver(255))
	rim.alpha = SUMIARI_RIM_SPRITE_ALPHA
	rim.filters = list(filter(type = "alpha", icon = sumiari_flora_cutout(thing), x = 1, y = -1, flags = MASK_INVERSE))
	return rim

// 3) Dew sparkle.
/obj/item/organ/eyes/sumiari/proc/fx_dew()
	for(var/image/old as anything in fx_dew_images)
		if(fx_dew_images[old] <= world.time)
			fx_client.images -= old
			fx_dew_images -= old
	if(!sumiari_moon_dew_enabled || !length(fx_dew_spots) || LAZYLEN(fx_dew_images) >= SUMIARI_DEW_MAX || !prob(SUMIARI_DEW_CHANCE))
		return
	var/turf/T = pick(fx_dew_spots)
	if(locate(/mob/living) in T)
		return
	var/image/dew = sumiari_dew_image(T)
	LAZYSET(fx_dew_images, dew, world.time + SUMIARI_DEW_RISE + SUMIARI_DEW_FALL + 2)
	fx_client.images += dew

/proc/sumiari_dew_image(turf/T)
	var/image/dew = sumiari_fx_style(image(sumiari_dew_icon(), T), SUMIARI_FX_FLOOR_PLANE)
	dew.pixel_x = rand(-12, 12)
	dew.pixel_y = rand(-12, 12)
	dew.alpha = 0
	animate(dew, alpha = SUMIARI_DEW_ALPHA, time = SUMIARI_DEW_RISE, easing = SINE_EASING)
	animate(alpha = 0, time = SUMIARI_DEW_FALL, easing = SINE_EASING)
	return dew

/proc/sumiari_dew_icon()
	var/static/icon/made
	if(made)
		return made
	made = sumiari_blank_icon()
	made.DrawBox(sumiari_fx_silver(90), 15, 16)
	made.DrawBox(sumiari_fx_silver(90), 17, 16)
	made.DrawBox(sumiari_fx_silver(90), 16, 15)
	made.DrawBox(sumiari_fx_silver(90), 16, 17)
	made.DrawBox(rgb(246, 248, 255, 255), 16, 16)
	return made

// 4) Night-flower blooming.
GLOBAL_LIST_INIT(sumiari_bloom_types, typecacheof(list(
	/obj/structure/flora/roguegrass/herb,
	/obj/structure/flora/roguegrass/pyroclasticflowers,
	/obj/structure/flower_sprout,
	/obj/structure/flora/tinymushrooms,
	/obj/structure/flora/mushroomcluster,
	/obj/structure/flora/rogueshroom,
	/obj/structure/glowshroom,
)))

// How open the night flowers are at a station time (null: now), 0..1.
/proc/sumiari_bloom_level(time)
	if(isnull(time))
		time = station_time()
	var/ramp
	if(time >= SUMIARI_BLOOM_OPEN_END || time < SUMIARI_BLOOM_CLOSE_START)
		return 1
	if(time >= SUMIARI_BLOOM_OPEN_START)
		ramp = (time - SUMIARI_BLOOM_OPEN_START) / (SUMIARI_BLOOM_OPEN_END - SUMIARI_BLOOM_OPEN_START)
	else if(time < SUMIARI_BLOOM_CLOSE_END)
		ramp = 1 - (time - SUMIARI_BLOOM_CLOSE_START) / (SUMIARI_BLOOM_CLOSE_END - SUMIARI_BLOOM_CLOSE_START)
	else
		return 0
	ramp = clamp(ramp, 0, 1)
	return ramp * ramp * (3 - 2 * ramp)

// Richer color: saturation, a little gain, a faint violet-blue lift. Alpha untouched.
/proc/sumiari_bloom_matrix()
	var/list/look = color_matrix_saturation(SUMIARI_BLOOM_SATURATION)
	for(var/i in 1 to 12)
		if(i % 4)
			look[i] *= SUMIARI_BLOOM_GAIN
	look[17] = SUMIARI_BLOOM_BIAS_R
	look[18] = SUMIARI_BLOOM_BIAS_G
	look[19] = SUMIARI_BLOOM_BIAS_B
	return look

/obj/item/organ/eyes/sumiari/proc/fx_blooms(turf/T, list/wanted)
	if(isclosedturf(T) || !sumiari_spare_turf_open(T))
		return
	for(var/obj/plant in T)
		if(!is_type_in_typecache(plant, GLOB.sumiari_bloom_types) || plant.invisibility || !plant.icon_state)
			continue
		var/key = "b[REF(plant)]"
		var/state = "[plant.icon]|[plant.icon_state]|[plant.dir]|[plant.plane]"
		if(fx_want(key, state, wanted))
			fx_put(key, state, sumiari_bloom_image(plant, fx_bloom))

/proc/sumiari_bloom_image(obj/plant, level)
	var/image/bloom = image(plant.icon, plant, plant.icon_state)
	bloom.dir = plant.dir
	sumiari_fx_style(bloom, sumiari_fx_plane_near(plant.plane))
	bloom.appearance_flags = RESET_COLOR | RESET_ALPHA | KEEP_APART
	bloom.color = sumiari_bloom_matrix()
	bloom.alpha = round(SUMIARI_BLOOM_ALPHA * level)
	return bloom

// The night moved on: ease every open flower to the new bloom.
/obj/item/organ/eyes/sumiari/proc/fx_bloom_ease()
	var/level = sumiari_bloom_level()
	if(!isnull(fx_bloom) && abs(level - fx_bloom) < SUMIARI_BLOOM_STEP)
		return
	fx_bloom = level
	var/target = round(SUMIARI_BLOOM_ALPHA * level)
	for(var/key in fx_images)
		if(copytext(key, 1, 2) == "b")
			animate(fx_images[key], alpha = target, time = SUMIARI_BLOOM_EASE)

// 5) Soft moon shadows.
GLOBAL_LIST_INIT(sumiari_shade_types, typecacheof(list(
	/obj/structure/flora/roguetree,
	/obj/structure/roguerock,
	/obj/structure/flora/rogueshroom,
)))

// A tile that blocks the moon: a wall or cliff, or a tree, rock or big mushroom. Cached per scan in blockers.
/proc/sumiari_shade_blocks(turf/T, list/blockers)
	if(!T)
		return FALSE
	if(!isnull(blockers[T]))
		return blockers[T]
	var/blocks = isclosedturf(T)
	if(!blocks)
		for(var/obj/thing in T)
			if(is_type_in_typecache(thing, GLOB.sumiari_shade_types))
				blocks = TRUE
				break
	blockers[T] = blocks
	return blocks

// Shade at the grid corner between tiles (x - 1, x) and (y - 1, y): north pair weighted, all four for contact.
/proc/sumiari_shade_corner(x, y, z, list/blockers)
	var/north_west = sumiari_shade_blocks(locate(x - 1, y, z), blockers)
	var/north_east = sumiari_shade_blocks(locate(x, y, z), blockers)
	var/south_west = sumiari_shade_blocks(locate(x - 1, y - 1, z), blockers)
	var/south_east = sumiari_shade_blocks(locate(x, y - 1, z), blockers)
	var/shade = SUMIARI_SHADE_NORTH * (north_west + north_east) / 2 + SUMIARI_SHADE_CONTACT * (north_west + north_east + south_west + south_east) / 4
	return round(min(shade, 1), 0.05)

/obj/item/organ/eyes/sumiari/proc/fx_shade(turf/T, list/wanted, list/blockers)
	if(sumiari_shade_blocks(T, blockers) || !sumiari_spare_turf_open(T))
		return
	// Tile (x, y) has corners SW (x, y), SE (x + 1, y), NW (x, y + 1), NE (x + 1, y + 1) on that grid.
	var/sw = sumiari_shade_corner(T.x, T.y, T.z, blockers)
	var/se = sumiari_shade_corner(T.x + 1, T.y, T.z, blockers)
	var/nw = sumiari_shade_corner(T.x, T.y + 1, T.z, blockers)
	var/ne = sumiari_shade_corner(T.x + 1, T.y + 1, T.z, blockers)
	if(max(sw, se, nw, ne) < SUMIARI_SHADE_MIN)
		return
	var/key = "s[T.x],[T.y]"
	var/state = "[sw]|[se]|[nw]|[ne]"
	if(fx_want(key, state, wanted))
		var/image/shade = sumiari_fx_style(image(LIGHTING_ICON, T, ""), SUMIARI_FX_FLOOR_PLANE)
		shade.color = sumiari_shade_matrix(sw, se, nw, ne)
		fx_put(key, state, shade)

// The lighting gradient's channels weigh its corners: red SW, green SE, blue NW, alpha NE (as the sky light reads
// them). Out: the shade color, alpha the corner-weighted shade.
/proc/sumiari_shade_matrix(sw, se, nw, ne)
	var/list/rgb = rgb2num(SUMIARI_SHADE_COLOR)
	var/strength = SUMIARI_SHADE_ALPHA
	return list(0, 0, 0, sw * strength, 0, 0, 0, se * strength, 0, 0, 0, nw * strength, 0, 0, 0, ne * strength, rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 0)

// Moon effect checks that do not depend on the map or the time of day.
/proc/sumiari_sweep_moon_fx(obj/item/organ/eyes/sumiari/eyes)
	var/list/bad = list()
#if SUMIARI_MOON_FX
	for(var/host in list(FLOOR_PLANE, GAME_PLANE_LOWER, GAME_PLANE, GAME_PLANE_UPPER))
		var/fx_plane = sumiari_fx_plane_for(host)
		var/atom/movable/screen/plane_master/master = eyes.owner?.hud_used?.plane_masters["[fx_plane]"]
		if(!master || master.render_target != sumiari_fx_target(fx_plane))
			bad += "fx plane master [host]"
	var/atom/movable/screen/sumiari_relay/moon = sumiari_find_piece(eyes, "sumiari moon")
	var/fx_layers = 0
	for(var/sample in moon?.filters)
		var/source = sumiari_filter_field(list(sample), 1, "render_source")
		if(source == SUMIARI_FX_FLOOR_TARGET || source == SUMIARI_FX_LOWER_TARGET || source == SUMIARI_FX_GAME_TARGET || source == SUMIARI_FX_UPPER_TARGET)
			fx_layers++
	if(eyes.wash_mode == SUMIARI_WASH_LIVE && moon && fx_layers != 4)
		bad += "moon relay fx layers=[fx_layers]"
	if(sumiari_fx_plane_near(FLOOR_PLANE) != SUMIARI_FX_FLOOR_PLANE || sumiari_fx_plane_near(WALL_PLANE) != SUMIARI_FX_LOWER_PLANE || sumiari_fx_plane_near(GAME_PLANE_FOV_HIDDEN) != SUMIARI_FX_GAME_PLANE || sumiari_fx_plane_near(GAME_PLANE_HIGHEST) != SUMIARI_FX_UPPER_PLANE)
		bad += "fx plane near"
	var/turf/spot = get_turf(eyes.owner)
#if SUMIARI_MOON_WATER
	var/image/ripple = sumiari_water_image(spot)
	if(ripple.plane != SUMIARI_FX_GAME_PLANE || ripple.loc != spot || !ripple.icon)
		bad += "water image"
#endif
#if SUMIARI_MOON_RIMS
	var/icon/rim_icon = sumiari_rim_icon(NORTH | WEST)
	if(!rim_icon || rim_icon.GetPixel(10, 32) == null || rim_icon.GetPixel(1, 10) == null || rim_icon.GetPixel(32, 10) != null || rim_icon.GetPixel(16, 16) != null)
		bad += "rim icon"
	var/obj/structure/roguerock/rock = new(spot)
	var/image/rock_rim = sumiari_rim_image(rock)
	if(rock_rim.plane != SUMIARI_FX_LOWER_PLANE || length(rock_rim.filters) != 1 || rock_rim.loc != rock)
		bad += "rim image plane=[rock_rim.plane]"
	qdel(rock)
#endif
#if SUMIARI_MOON_DEW
	var/image/dew = sumiari_dew_image(spot)
	var/icon/dew_icon = sumiari_dew_icon()
	if(dew.plane != SUMIARI_FX_FLOOR_PLANE || abs(dew.pixel_x) > 12 || dew_icon.GetPixel(16, 16) == null || dew_icon.GetPixel(20, 20) != null || SUMIARI_GLINT_DEW)
		bad += "dew"
#endif
#if SUMIARI_MOON_BLOOM
	if(sumiari_bloom_level(12 HOURS) != 0 || sumiari_bloom_level(0) != 1 || sumiari_bloom_level(15.9 HOURS) != 0)
		bad += "bloom curve noon=[sumiari_bloom_level(12 HOURS)] midnight=[sumiari_bloom_level(0)]"
	var/dusk_bloom = sumiari_bloom_level(19 HOURS)
	var/dawn_bloom = sumiari_bloom_level(6.5 HOURS)
	if(!(dusk_bloom > 0 && dusk_bloom < 1 && dawn_bloom > 0 && dawn_bloom < 1))
		bad += "bloom ramp dusk=[dusk_bloom] dawn=[dawn_bloom]"
	// Richer but not neon: a muted green gets more chroma and keeps its hue order, white does not blow past 1.2.
	var/list/leaf = sumiari_apply_matrix(sumiari_bloom_matrix(), 0.3, 0.45, 0.25)
	var/list/bloom_white = sumiari_apply_matrix(sumiari_bloom_matrix(), 1, 1, 1)
	if(!(leaf[2] - leaf[3] > 0.45 - 0.25 && leaf[2] > leaf[1]) || max(bloom_white[1], bloom_white[2], bloom_white[3]) > 1.25)
		bad += "bloom matrix leaf=[leaf[1]],[leaf[2]],[leaf[3]]"
	var/obj/structure/flora/tinymushrooms/shroom = new(spot)
	var/image/bloom = sumiari_bloom_image(shroom, 0.5)
	if(bloom.alpha != round(SUMIARI_BLOOM_ALPHA * 0.5) || bloom.loc != shroom || bloom.plane != sumiari_fx_plane_near(shroom.plane))
		bad += "bloom image alpha=[bloom.alpha] plane=[bloom.plane]"
	qdel(shroom)
#endif
#if SUMIARI_MOON_SHADE
	// A wall row to the north shades a tile's north corners strongly and its south corners not at all.
	var/list/fake = list()
	var/turf/probe = locate(50, 50, spot.z)
	if(probe)
		fake[locate(49, 51, spot.z)] = TRUE
		fake[locate(50, 51, spot.z)] = TRUE
		fake[locate(51, 51, spot.z)] = TRUE
		for(var/dx in -1 to 1)
			for(var/dy in -1 to 0)
				fake[locate(50 + dx, 50 + dy, spot.z)] = FALSE
		fake[locate(49, 49, spot.z)] = FALSE
		fake[locate(50, 49, spot.z)] = FALSE
		fake[locate(51, 49, spot.z)] = FALSE
		var/north = sumiari_shade_corner(50, 51, spot.z, fake)
		var/south = sumiari_shade_corner(50, 50, spot.z, fake)
		if(!(north >= 0.9 && south == 0))
			bad += "shade corners north=[north] south=[south]"
	var/list/shade_matrix = sumiari_shade_matrix(1, 0, 0, 0)
	if(shade_matrix[4] != SUMIARI_SHADE_ALPHA || shade_matrix[8] != 0 || shade_matrix[20] != 0)
		bad += "shade matrix"
#endif
#endif
	if(length(bad))
		log_world("SUMIARI TEST FAIL moon fx [bad.Join(" ")]")
		return FALSE
	log_world("SUMIARI TEST moon fx PASS water=[SUMIARI_MOON_WATER] rims=[SUMIARI_MOON_RIMS] dew=[SUMIARI_MOON_DEW] bloom=[SUMIARI_MOON_BLOOM] shade=[SUMIARI_MOON_SHADE]")
	return TRUE
