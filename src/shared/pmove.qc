/*
 * Copyright (c) 2016-2022 Vera Visions LLC.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

#define CUSTOMPLAYERPHYSICS

#ifdef CUSTOMPLAYERPHYSICS

// { HACK: various things required by custom physics. Got it from nuclide.

	string(string cmd) readcmd = #0:readcmd;

	// Actually used by input_button etc.
	#define INPUT_BUTTON0 0x00000001
	#define INPUT_BUTTON2 0x00000002
	#define INPUT_BUTTON3 0x00000004
	#define INPUT_BUTTON4 0x00000008
	#define INPUT_BUTTON5 0x00000010
	#define INPUT_BUTTON6 0x00000020
	#define INPUT_BUTTON7 0x00000040
	#define INPUT_BUTTON8 0x00000080

	#define FL_ONLADDER			(1<<13)
	#define FL_CROUCHING		(1<<17)

	.float jumptime; // FIXME: unused, remove me.
	.vector basevelocity; // FIXME: unused, remove me.
// }

	void PMoveCustom_Init(void);
	#ifdef SERVER
	void PMoveCustom_StartFrame(void);
	#endif
#endif

#ifndef PMOVE_STEPHEIGHT
	#define PMOVE_STEPHEIGHT 18
#endif

#ifndef PMOVE_AIRSTEPHEIGHT
	#define PMOVE_AIRSTEPHEIGHT 18
#endif

#ifndef PMOVE_FRICTION
	#define PMOVE_FRICTION 4
#endif

#ifndef PMOVE_EDGEFRICTION
	#define PMOVE_EDGEFRICTION 1
#endif

#ifndef PMOVE_STOPSPEED
	#define PMOVE_STOPSPEED 75
#endif

#ifndef PMOVE_GRAVITY
	#define PMOVE_GRAVITY 800
#endif

#ifndef PMOVE_AIRACCELERATE
	#define PMOVE_AIRACCELERATE 10
#endif

#ifndef PMOVE_WATERACCELERATE
	#define PMOVE_WATERACCELERATE 8
#endif

#ifndef PMOVE_ACCELERATE
	#define PMOVE_ACCELERATE 8
#endif

#ifndef PMOVE_MAXSPEED
	#define PMOVE_MAXSPEED 270
#endif

#ifndef PMOVE_STEP_WALKSPEED
	#define PMOVE_STEP_WALKSPEED 135
#endif

#ifndef PMOVE_STEP_RUNSPEED
	#define PMOVE_STEP_RUNSPEED 220
#endif

#ifndef PHY_VIEWPOS
	#define PHY_VIEWPOS [0,0,28]
#endif

#ifndef PHY_VIEWPOS_CROUCHED
	#define PHY_VIEWPOS_CROUCHED [0,0,12]
#endif

/* stamina system, inspired by idTech 4 */
#ifndef PMOVE_STAMINA
	#define PMOVE_STAMINA 24
#endif

#ifndef PMOVE_STAMINARATE
	#define PMOVE_STAMINARATE 0.75
#endif

#ifndef PMOVE_STAMINATHRESHOLD
	#define PMOVE_STAMINATHRESHOLD 4
#endif


/* Those are constant for HL BSP and CANNOT be changed.
 * Blame Valve for purchasing a Quake II license but not
 * scrapping hull sizes for their .bsp format... 
 * however, you can offset them */
#ifndef PHY_HULL_MIN
	#define PHY_HULL_MIN [-16,-16,-36]
#endif

#ifndef PHY_HULL_MAX
	#define PHY_HULL_MAX [16,16,36]
#endif

#ifndef PHY_HULL_CROUCHED_MIN
	#define PHY_HULL_CROUCHED_MIN [-16,-16,-18]
#endif

#ifndef PHY_HULL_CROUCHED_MAX
	#define PHY_HULL_CROUCHED_MAX [16,16,18]
#endif

/* if they're undefined by a config, they'll be set by the game/mod default */
var float autocvar_sv_stepheight = PMOVE_STEPHEIGHT;
var float autocvar_sv_airstepheight = PMOVE_AIRSTEPHEIGHT;
var float autocvar_sv_friction = PMOVE_FRICTION;
var float autocvar_sv_edgefriction = PMOVE_EDGEFRICTION;
var float autocvar_sv_stopspeed = PMOVE_STOPSPEED;
var float autocvar_sv_gravity = PMOVE_GRAVITY;
var float autocvar_sv_airaccelerate = PMOVE_AIRACCELERATE;
var float autocvar_sv_wateraccelerate = PMOVE_WATERACCELERATE;
var float autocvar_sv_accelerate = PMOVE_ACCELERATE;
var float autocvar_sv_maxspeed = PMOVE_MAXSPEED;

void
PMove_Init(void)
{
	#ifdef SERVER
	cvar_set("sv_stepheight", ftos(PMOVE_STEPHEIGHT));
	cvar_set("sv_airstepheight", ftos(PMOVE_AIRSTEPHEIGHT));
	cvar_set("sv_friction", ftos(PMOVE_FRICTION));
	cvar_set("sv_edgefriction", ftos(PMOVE_EDGEFRICTION));
	cvar_set("sv_stopspeed", ftos(PMOVE_STOPSPEED));
	cvar_set("sv_gravity", ftos(PMOVE_GRAVITY));
	cvar_set("sv_airaccelerate", ftos(PMOVE_AIRACCELERATE));
	cvar_set("sv_wateraccelerate", ftos(PMOVE_WATERACCELERATE));
	cvar_set("sv_accelerate", ftos(PMOVE_ACCELERATE));
	cvar_set("sv_maxspeed", ftos(PMOVE_MAXSPEED));
	#endif

	#ifdef CUSTOMPLAYERPHYSICS
	PMoveCustom_Init();
	#endif
}

#ifdef SERVER
void
PMove_StartFrame(void)
{
	#ifdef CUSTOMPLAYERPHYSICS
	PMoveCustom_StartFrame();
	#endif
}
#endif

/* simple bounds check */
int
PMove_IsStuck(entity eTarget, vector vOffset, vector vecMins, vector vecMaxs)
{
	vector bound;

	if (eTarget.solid != SOLID_SLIDEBOX) {
		return (0);
	}

	bound = eTarget.origin + vOffset;
	tracebox(bound, vecMins, vecMaxs, bound, MOVE_NORMAL, eTarget);
	return trace_startsolid;
}
