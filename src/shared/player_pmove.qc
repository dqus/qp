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

vector saved_input_movevalues;
int saved_input_buttons;

// { HACK: various things which is missed in our code unlike nuclide.
#ifdef SERVER

typedef enumflags
{
	DMG_GENERIC,
	DMG_BURN,
	DMG_FALL,
	DMG_ACID,
	DMG_DROWN,
} damageType_t;

static void Damage_Apply(entity t, entity c, float dmg, int w, damageType_t type)
{
	T_Damage(t, c, c, dmg);
}

static void Sound_Play(entity target, int chan, string shader)
{
	switch (shader) {
	case "player.fall":
		sound(target, chan, "player/land2.wav", 1, ATTN_NORM); break;
	case "player.lightfall":
		sound(target, chan, "player/land.wav", 1, ATTN_NORM); break;
	case "player.gaspheavy":
		sound(target, chan, "player/gasp2.wav", 1, ATTN_NORM); break;
	case "player.gasplight":
		sound(target, chan, "player/gasp1.wav", 1, ATTN_NORM); break;
	case "player.waterexit":
		sound(target, chan, "misc/outwater.wav", 1, ATTN_NORM); break;
	case "player.waterenter":
		sound(target, chan, "player/inh2o.wav", 1, ATTN_NORM); break;
	case "player.lavaenter":
		sound(target, chan, "player/inlava.wav", 1, ATTN_NORM); break;
	case "player.slimeenter":
		sound(target, chan, "player/slimbrn2.wav", 1, ATTN_NORM); break;
	case "player.jump":
		sound(target, chan, "player/plyrjmp8.wav", 1, ATTN_NORM); break;
	default:
		bPrintf(PRINT_HIGH, "FIXME: Sound_Play: %s\n", shader);
		break;
	}
}

#endif
// }

void
Player_Physics_Fall(float flDownforce)
{
	if (flDownforce > 580) {
#ifdef SERVER
		float fFallDamage = (flDownforce - 580) * (100 / (1024 - 580));
		Damage_Apply(self, world, fFallDamage, 0, DMG_FALL);
		Sound_Play(self, CHAN_VOICE, "player.fall");
#endif
		self.punchangle += [15,0,(input_sequence & 1) ? 15 : -15];
	} else if (flDownforce > 400) {
		self.punchangle += [15,0,0];
#ifdef SERVER
		Sound_Play(self, CHAN_VOICE, "player.lightfall");
#endif
	}
}

void
Player_Physics_Crouch(void)
{
	int iFixCrouch = FALSE;
	if (input_buttons & INPUT_BUTTON8) {
		self.flags |= FL_CROUCHING;
	} else {
		// If we aren't holding down duck anymore and 'attempt' to stand up, prevent it
		if (self.flags & FL_CROUCHING) {
			if (PMove_IsStuck(self, [0,0,PHY_HULL_MAX[2]], PHY_HULL_MIN, PHY_HULL_MAX) == FALSE) {
				self.flags &= ~FL_CROUCHING;
				iFixCrouch = TRUE;
			}
		} else {
			self.flags &= ~FL_CROUCHING;
		}
	}

	if (self.flags & FL_CROUCHING) {
		setsize(self, PHY_HULL_CROUCHED_MIN, PHY_HULL_CROUCHED_MAX);
		self.view_ofs = PHY_VIEWPOS_CROUCHED;
	} else {
		setsize(self, PHY_HULL_MIN, PHY_HULL_MAX);
		if (iFixCrouch && PMove_IsStuck(self, [0,0,0], PHY_HULL_MIN, PHY_HULL_MAX)) {
			for (int i = 0; i < 36; i++) {
				self.origin[2] += 1;
				if (PMove_IsStuck(self, [0,0,0], self.mins, self.maxs) == FALSE) {
					break;
				}
			}
		}
		setorigin(self, self.origin);
		self.view_ofs = PHY_VIEWPOS;
	}
}

void
Player_Physics_Jump(void)
{
	/* climb out of substances when underwater */
	if (self.waterlevel >= 2) {
		if (self.watertype == CONTENT_WATER) {
			self.velocity[2] = 100;
		} else if (self.watertype == CONTENT_SLIME) {
			self.velocity[2] = 80;
		} else {
			self.velocity[2] = 50;
		}
	} else {
		if (self.flags & FL_ONGROUND) {
#ifdef SERVER
			Sound_Play(self, CHAN_BODY, "player.jump");
#endif
			self.velocity[2] += 270;
		}
	}
}

/* check if we're elligible to jump */
void
Player_Physics_CheckJump(float premove)
{
	/* unset jump-key whenever it's not set */
	if (!(input_buttons & INPUT_BUTTON2)) {
		self.flags |= FL_JUMPRELEASED;
		return;
	}

	if (self.flags & FL_WATERJUMP)
		return;
	if (!(self.flags & FL_ONGROUND))
		return;

	if (!(infokey(self, "autojump") == "1"))
	if (!(self.flags & FL_JUMPRELEASED))
		return;

	if (input_buttons & INPUT_BUTTON2 && premove) {
		if (self.velocity[2] < 0) {
			self.velocity[2] = 0;
		}

		Player_Physics_Jump();
		self.flags &= ~FL_ONGROUND;
		self.flags &= ~FL_JUMPRELEASED;
	}
}

/* establish the right size and camera position */
void
Player_Physics_SetViewParms(void)
{
	if (self.flags & FL_CROUCHING) {
		self.mins = PHY_HULL_CROUCHED_MIN;
		self.maxs = PHY_HULL_CROUCHED_MAX;
		self.view_ofs = PHY_VIEWPOS_CROUCHED;
	} else {
		self.mins = PHY_HULL_MIN;
		self.maxs = PHY_HULL_MAX;
		self.view_ofs = PHY_VIEWPOS;
	}
	setsize(self, self.mins, self.maxs);
}

void
Player_Physics_WaterJump(void)
{
	vector vStart;
	vector vEnd;

	makevectors(self.angles);
	vStart = self.origin;
	vStart[2] = vStart[2] + 8; 
	v_forward[2] = 0;
	normalize(v_forward);
	vEnd = vStart + (v_forward * 24);
	traceline(vStart, vEnd, TRUE, self);

	if (trace_fraction < 1) {
		vStart[2] = vStart[2] + self.maxs[2];
		vEnd = vStart + (v_forward * 24);
		//movedir = trace_plane_normal * -50;
		traceline(vStart, vEnd, TRUE, self);
		
		if (trace_fraction == 1) {
			self.flags |= FL_WATERJUMP;
			self.velocity[2] = 350;
			self.flags &= ~FL_JUMPRELEASED;
			return;
		}
	}
}

/* handle your time underwater */
void
Player_Physics_WaterMove(void)
{
	if (self.movetype == MOVETYPE_NOCLIP) {
		return;
	}

#ifdef SERVER
	if (self.health < 0) {
		return;
	}

	/* we've just exited water */
	if (self.waterlevel != 3) {
		if (self.air_finished < time) {
			Sound_Play(self, CHAN_VOICE, "player.gaspheavy");
		} else if (self.air_finished < time + 9) {
			Sound_Play(self, CHAN_VOICE, "player.gasplight");
		}
		self.air_finished = time + 12;
	} else if (self.air_finished < time) {
		/* we've been underwater... for too long. */
		if (self.pain_finished < time) {
			Damage_Apply(self, world, 5, 0, DMG_DROWN);
			self.pain_finished = time + 1;
		}
	}
#endif

	if (!self.waterlevel){
		if (self.flags & FL_INWATER) {
#ifdef SERVER
			Sound_Play(self, CHAN_BODY, "player.waterexit");
#endif
			self.flags &= ~FL_INWATER;
		}
		return;
	}

#ifdef SERVER
	if (self.watertype == CONTENT_LAVA) {
		if (self.pain_finished < time) {
			Damage_Apply(self, world, 10*self.waterlevel, 0, DMG_BURN);
			self.pain_finished = time + 0.2;
		}
	} else if (self.watertype == CONTENT_SLIME) {
		if (self.pain_finished < time) {
			Damage_Apply(self, world, 4*self.waterlevel, 0, DMG_ACID);
			self.pain_finished = time + 1;
		}
	}
#endif

	if (!(self.flags & FL_INWATER)) {
#ifdef SERVER
		if (self.watertype == CONTENT_LAVA)
			Sound_Play(self, CHAN_BODY, "player.lavaenter");
		else if (self.watertype == CONTENT_WATER)
			Sound_Play(self, CHAN_BODY, "player.waterenter");
		else if (self.watertype == CONTENT_SLIME)
			Sound_Play(self, CHAN_BODY, "player.slimeenter");
		self.pain_finished = 0;
#endif
		self.flags |= FL_INWATER;
	}

	/* we might need to apply extra-velocity to get out of water-volumes */
	if (self.waterlevel >= 2) {
		Player_Physics_WaterJump();
	}
}

float
Player_Physics_MaxSpeed(void)
{
	float maxspeed = serverkeyfloat("phy_maxspeed");
	float desiredspeed = (self.flags & FL_CROUCHING) ? PMOVE_STEP_WALKSPEED : PMOVE_MAXSPEED;
	return min(desiredspeed, maxspeed);
}

void
Player_Physics_InputPreMove(void)
{
//	NSVehicle veh = (NSVehicle)vehicle;

	/* when pressing the 'use' button, we also walk slower for precision */
	if (input_buttons & INPUT_BUTTON5) {
		input_movevalues *= 0.25;
	}

	/* move camera up (noclip, fly) when holding jump */
	if (input_buttons & INPUT_BUTTON2) {
		input_movevalues[2] = 240;
	}
	/* move camera down (noclip, fly) when holding crouching */
	if (input_buttons & INPUT_BUTTON8) {
		input_movevalues[2] = -240;
	}

	if (self.flags & FL_FROZEN || self.movetype == MOVETYPE_NONE) {
		input_movevalues = [0,0,0];
		input_buttons &= ~INPUT_BUTTON2;
	}

	/* suppress crouching in vehicles */
//	if (veh)
//		if (veh.CanDriverCrouch() == false)
//			input_buttons &= ~INPUT_BUTTON8;
}

/* timers get processed here after physics are run */
void
Player_Physics_InputPostMove(void)
{
	float punch;
	/* timers, these are predicted and shared across client and server */
//	w_attack_next = max(0, w_attack_next - input_timelength);
//	w_idle_next = max(0, w_idle_next - input_timelength);
//	weapontime += input_timelength;
	punch = max(0, 1.0f - (input_timelength * 4));
	self.punchangle[0] *= punch;
	self.punchangle[1] *= punch;
	self.punchangle[2] *= punch;

	/* player animation code */
//	Animation_TimerUpdate((player)self, input_timelength);
//	Animation_PlayerUpdate((player)self);

	self.flags &= ~FL_FROZEN;

//	ClientInput();
}

/* the main physics routine, the head */
void
Player_Physics_Run(void)
{
	float flFallVel = (self.flags & FL_ONGROUND) ? 0 : -self.velocity[2];

	saved_input_movevalues = input_movevalues;
	saved_input_buttons = input_buttons;

	/* maxspeed changes when crouching, TODO: make this game-specific */
	self.maxspeed = Player_Physics_MaxSpeed();

	/* give us a chance to manipulate input_ globals before running physics */
	Player_Physics_InputPreMove();

	/* handle drowning and other environmental factors */
	Player_Physics_WaterMove();

	Player_Physics_SetViewParms();

	Player_Physics_Crouch();
	Player_Physics_CheckJump(TRUE);

#ifdef CUSTOMPLAYERPHYSICS
	/* QuakeC powered physics (slow, but more customizable) */
	PMoveCustom_RunPlayerPhysics(self);
#else
	/* fast engine-side player physics */
	runstandardplayerphysics(self);
#endif

	Player_Physics_CheckJump(FALSE);

	if (self.waterlevel != 0) {
		flFallVel = 0;
	}

	if ((self.flags & FL_ONGROUND) && self.movetype == MOVETYPE_WALK) {
		Player_Physics_Fall(flFallVel);
	}

	input_movevalues = saved_input_movevalues;
	input_buttons = saved_input_buttons;
	Player_Physics_InputPostMove();

	self.angles[0] = Math_FixDelta(self.angles[0]);
	self.angles[1] = Math_FixDelta(self.angles[1]);
	self.angles[2] = Math_FixDelta(self.angles[2]);
}
