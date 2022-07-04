/*  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/
void t_movetarget ();
void SUB_AttackFinished (float normal);
/*

.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to its path.

.huntt_ime
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave its stand state and head towards its .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing
*/


//
// globals
//
// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player
//
entity	sight_entity;
float	sight_entity_time;

float	enemy_vis;
float	enemy_infront;
float	enemy_range;
float	enemy_yaw;

/*
==============================================================================

MOVETARGET CODE

The angle of the movetarget affects standing and bowing direction, but has no effect on movement, which always heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
*/


void movetarget_f ()
{
	if (!self.targetname)
		objerror ("monster_movetarget: no targetname");

	self.solid = SOLID_TRIGGER;
	self.touch = t_movetarget;
	setsize (self, '-8 -8 -8', '8 8 8');

}

/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
*/
void path_corner ()
{
	movetarget_f ();
}


/*
=============
t_movetarget

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void t_movetarget ()
{
	entity	temp;

	if (other.movetarget != self)
		return;

	if (other.enemy)
		return;		// fighting, not following a path

	temp = self;
	self = other;
	other = temp;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);// play chainsaw drag sound

//dprint ("t_movetarget\n");
	self.goalentity = self.movetarget = find (world, targetname, other.target);
	self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
	if (!self.movetarget)
	{
		self.pausetime = time + 999999;
		self.th_stand ();
		return;
	}
}



//============================================================================

/*
=============
range

returns the range catagorization of an entity reletive to self
0	melee range, will become hostile even if back is turned
1	visibility and infront, or visibility and show hostile
2	infront and show hostile
3	only triggered by damage
=============
*/
float range (entity targ)
{
	vector	spot1, spot2;
	float	r;
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	r = vlen (spot1 - spot2);
	if (r < 120)
		return RANGE_MELEE;
	if (r < 500)
		return RANGE_NEAR;
	if (r < 1000)
		return RANGE_MID;
	return RANGE_FAR;
}

/*
=============
visible

returns 1 if the entity is visible to self, even if not infront ()
=============
*/
float visible (entity targ)
{
	vector	spot1, spot2;

	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
	traceline (spot1, spot2, true, self);	// see through other monsters

	if (trace_inopen && trace_inwater)
		return false;			// sight line crossed contents

	if (trace_fraction == 1)
		return true;
	return false;
}


/*
=============
infront

returns 1 if the entity is in front (in sight) of self
=============
*/
float infront (entity targ)
{
	vector	vec;
	float	dot;

	makevectors (self.angles);
	vec = normalize (targ.origin - self.origin);
	dot = vec * v_forward;

	if ( dot > 0.3)
	{
		return true;
	}
	return false;
}

//============================================================================

void HuntTarget ()
{
	self.goalentity = self.enemy;
	self.think = self.th_run;
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	self.nextthink = time + 0.1;
	SUB_AttackFinished (1);	// wait a while before first attack
}

void SightSound ()
{
	float	rsnd;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogwake.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_knight")
		sound (self, CHAN_VOICE, "knight/ksight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shambler")
		sound (self, CHAN_VOICE, "shambler/ssight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_demon1")
		sound (self, CHAN_VOICE, "demon/sight2.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_wizard")
		sound (self, CHAN_VOICE, "wizard/wsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_zombie")
		sound (self, CHAN_VOICE, "zombie/z_idle.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_dog")
		sound (self, CHAN_VOICE, "dog/dsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_hell_knight")
		sound (self, CHAN_VOICE, "hknight/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_tarbaby")
		sound (self, CHAN_VOICE, "blob/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_enforcer")
	{
		rsnd = rint(random() * 3);
		if (rsnd == 1)
			sound (self, CHAN_VOICE, "enforcer/sight1.wav", 1, ATTN_NORM);
		else if (rsnd == 2)
			sound (self, CHAN_VOICE, "enforcer/sight2.wav", 1, ATTN_NORM);
		else if (rsnd == 0)
			sound (self, CHAN_VOICE, "enforcer/sight3.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "enforcer/sight4.wav", 1, ATTN_NORM);
	}
	else if (self.classname == "monster_army")
		sound (self, CHAN_VOICE, "soldier/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shalrath")
		sound (self, CHAN_VOICE, "shalrath/sight.wav", 1, ATTN_NORM);
}

void FoundTarget ()
{
	// New enemy found, do not try to search for quite some time so monster does not change enemy from one player to another.
	self.search_time = time + 10 + random() * 5;

	if (self.enemy.classname == "player")
	{	// let other monsters see this monster for a while
		sight_entity = self;
		sight_entity_time = time;
	}

	self.show_hostile = time + 1;		// wake up other monsters

	SightSound ();
	HuntTarget ();
}

/*
===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns true if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============
*/
float FindTarget ()
{
	entity	client = __NULL__;

// if the first spawnflag bit is set, the monster will only wake up on
// really seeing the player, not another monster getting angry

// spawnflags & 3 is a big hack, because zombie crucified used the first
// spawn flag prior to the ambush flag, and I forgot about it, so the second
// spawn flag works as well
	if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3)
		&& sight_entity && sight_entity.enemy && sight_entity.enemy.classname == "player"
		&& !isInvalidEnemy(sight_entity.enemy))
	{
		client = sight_entity;
		if (client.enemy == self.enemy)
			return false;
	} else {
		client = qp_checkclient();
	}
	if (!client)
		return false;

	if (client == self.enemy)
		return false;

	// Do not use visibility/range/etc checks in QP mode.
	if (!isQP()) {
		float r = range(client);
		if (r == RANGE_FAR)
			return false;
		if (!visible(client))
			return false;
		if (r == RANGE_NEAR) {
			if (client.show_hostile < time && !infront(client))
				return false;
		} else if (r == RANGE_MID) {
			if ( /* client.show_hostile < time || */ !infront(client))
				return false;
		}
	}

	// Check if client is `sight_entity` and a monster, use monster enemy as client.
	if (client.classname != "player")
		client = client.enemy;
	if (client.classname != "player" || isInvalidEnemy(client))
		return false;
//
// got one
//
	self.enemy = client;
	FoundTarget ();

	return true;
}


//=============================================================================

/*
=============
GetMadAtAttacker

T_Damage calls this when a monster is hurt
=============
*/
void GetMadAtAttacker (entity attacker)
{
	if (isQP() && attacker.classname != "player")
		return;

// get mad unless of the same class (except for soldiers)
	if (self != attacker && attacker != self.enemy)
	{
		if ( (self.classname != attacker.classname)
		|| (self.classname == "monster_army" ) )
		{
			self.enemy = attacker;
			FoundTarget ();
		}
	}
}

//=============================================================================

void ai_forward (float dist)
{
	walkmove (self.angles_y, dist);
}

void ai_back (float dist)
{
	walkmove ( (self.angles_y+180), dist);
}


/*
=============
ai_pain

stagger back a bit
=============
*/
void ai_pain (float dist)
{
	ai_back (dist);
/*
	float	away;

	away = anglemod (vectoyaw (self.origin - self.enemy.origin)
	+ 180*(random()- 0.5) );

	walkmove (away, dist);
*/
}

/*
=============
ai_painforward

stagger back a bit
=============
*/
void ai_painforward (float dist)
{
	walkmove (self.ideal_yaw, dist);
}

/*
=============
ai_walk

The monster is walking its beat
=============
*/
void ai_walk (float dist)
{
	movedist = dist;

	if (self.classname == "monster_dragon")
	{
		movetogoal (dist);
		return;
	}
	// check for noticing a player
	if (FindTarget ())
		return;

	movetogoal (dist);
}


/*
=============
ai_stand

The monster is staying in one place for a while, with slight angle turns
=============
*/
void ai_stand ()
{
	if (FindTarget ())
		return;

	if (time > self.pausetime)
	{
		self.th_walk ();
		return;
	}

// change angle slightly

}

/*
=============
ai_turn

don't move, but turn towards ideal_yaw
=============
*/
void ai_turn ()
{
	if (FindTarget ())
		return;

	ChangeYaw ();
}

/*
============
FacingIdeal

============
*/
float FacingIdeal ()
{
	float	delta;

	delta = anglemod(self.angles_y - self.ideal_yaw);
	if (delta > 45 && delta < 315)
		return false;
	return true;
}

//=============================================================================

/*
===========
CheckAttack

The player is in view, so decide to move or launch an attack
Returns false if movement should continue
============
*/
static float CheckAttack ()
{
	vector	spot1, spot2;
	entity	targ;
	float	chance;

	targ = self.enemy;

// see if any entities are in the way of the shot
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	traceline (spot1, spot2, false, self);

	if (trace_ent != targ)
		return false;		// don't have a clear shot

	if (trace_inopen && trace_inwater)
		return false;			// sight line crossed contents

	if (enemy_range == RANGE_MELEE)
	{	// melee attack
		if (self.th_melee)
		{
			self.th_melee ();
			return true;
		}
	}

// missile attack
	if (!self.th_missile)
		return false;

	if (time < self.attack_finished)
		return false;

	if (enemy_range == RANGE_FAR)
		return false;

	if (enemy_range == RANGE_MELEE)
	{
		chance = 0.9;
		self.attack_finished = 0;
	}
	else if (enemy_range == RANGE_NEAR)
	{
		if (self.th_melee)
			chance = 0.2;
		else
			chance = 0.4;
	}
	else if (enemy_range == RANGE_MID)
	{
		if (self.th_melee)
			chance = 0.05;
		else
			chance = 0.1;
	}
	else
		chance = 0;

	if (random () < chance)
	{
		self.th_missile ();
		SUB_AttackFinished (2*random());
		return true;
	}

	return false;
}

float CheckAnyAttack ()
{
	if (!enemy_vis)
		return false;
	if (self.th_checkAttack)
		return self.th_checkAttack();
	// If monster does't have own check attack then use default one.
	return CheckAttack ();
}

/*
=============
ai_run_melee

Turn and close until within an angle to launch a melee attack
=============
*/
void ai_run_melee ()
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();

	if (FacingIdeal())
	{
		self.th_melee ();
		self.attack_state = AS_STRAIGHT;
	}
}


/*
=============
ai_run_missile

Turn in place until within an angle to launch a missile attack
=============
*/
void ai_run_missile ()
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (FacingIdeal())
	{
		self.th_missile ();
		self.attack_state = AS_STRAIGHT;
	}
}


/*
=============
ai_run_slide

Strafe sideways, but stay at aproximately the same range
=============
*/
void ai_run_slide ()
{
	float	ofs;

	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (self.lefty)
		ofs = 90;
	else
		ofs = -90;

	if (walkmove (self.ideal_yaw + ofs, movedist))
		return;

	self.lefty = 1 - self.lefty;

	walkmove (self.ideal_yaw - ofs, movedist);
}


/*
=============
ai_run

The monster has an enemy it is trying to kill
=============
*/
void ai_run (float dist)
{
	movedist = dist;

// set default knowledge of enemy
	enemy_vis = false;
	enemy_infront = false;
	enemy_range = RANGE_FAR;
	enemy_yaw = 0;

// see if the enemy is dead
	if (isInvalidEnemy(self.enemy))
	{
		self.enemy = world;
		self.search_time = 0;

		if (self.movetarget)
			self.th_walk ();
		else
			self.th_stand ();
		return;
	}

	self.show_hostile = time + 1;		// wake up other monsters

// look for other coop players
	if (coop && self.search_time < time)
	{
		if (FindTarget())
			return;
	}

// set actual knowledge of enemy
	enemy_vis = visible(self.enemy);
	enemy_infront = infront(self.enemy);
	enemy_range = range(self.enemy);
	enemy_yaw = vectoyaw(self.enemy.origin - self.origin);

	if (self.attack_state == AS_MISSILE)
	{
//dprint ("ai_run_missile\n");
		ai_run_missile ();
		return;
	}
	if (self.attack_state == AS_MELEE)
	{
//dprint ("ai_run_melee\n");
		ai_run_melee ();
		return;
	}

	if (CheckAnyAttack ())
		return;					// beginning an attack

	if (self.attack_state == AS_SLIDING)
	{
		ai_run_slide ();
		return;
	}

// head straight in
	movetogoal (dist);		// done in C code...
}

/*
=============
ai_face

Stay facing the enemy
=============
*/
void ai_face ()
{
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	ChangeYaw ();
}

/*
=============
ai_charge

The monster is in a melee attack, so get as close as possible to .enemy
=============
*/
void ai_charge (float d)
{
	ai_face ();
	movetogoal (d);		// done in C code...
}

void ai_charge_side ()
{
	vector	dtemp;
	float	heading;

// aim to the left of the enemy for a flyby

	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	ChangeYaw ();

	makevectors (self.angles);
	dtemp = self.enemy.origin - 30*v_right;
	heading = vectoyaw(dtemp - self.origin);

	walkmove(heading, 20);
}

/*
=============
ai_melee

=============
*/
void ai_melee ()
{
	vector	delta;
	float	ldmg;

	if (!self.enemy)
		return;		// removed before stroke

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 60)
		return;

	ldmg = (random() + random() + random()) * 3;
	T_Damage (self.enemy, self, self, ldmg);
}

void ai_melee_side ()
{
	vector	delta;
	float	ldmg;

	if (!self.enemy)
		return;		// removed before stroke

	ai_charge_side();

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 60)
		return;
	if (!CanDamage (self.enemy, self))
		return;
	ldmg = (random() + random() + random()) * 3;
	T_Damage (self.enemy, self, self, ldmg);
}

/*

in nightmare mode, all attack_finished times become 0
some monsters refire twice automatically

*/
void SUB_AttackFinished (float normal)
{
	self.cnt = 0;		// refire count for nightmare
	if (skill != 3)
		self.attack_finished = time + normal;
}

void SUB_CheckRefire (void() thinkst)
{
	if (skill != 3)
		return;
	if (self.cnt == 1)
		return;
	if (!visible (self.enemy))
		return;
	self.cnt = 1;
	self.think = thinkst;
}
