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
/* ALL MONSTERS SHOULD BE 1 0 0 IN COLOR */

// name =[framenum,	nexttime, nextthink] {code}
// expands to:
// name ()
// {
//		self.frame=framenum;
//		self.nextthink = time + nexttime;
//		self.think = nextthink
//		<code>
// }

const int CONTENTBIT_BOTCLIP = 0x00400000i;
const int CONTENTBITS_MONSTER = CONTENTBIT_SOLID|CONTENTBIT_BODY|CONTENTBIT_MONSTERCLIP|CONTENTBIT_BOTCLIP;	
static void monster_physics(void)
{
	input_movevalues = [0,0,0];
	input_impulse = 0;
	input_buttons = 0;
	input_angles = self.angles; //self.v_angle;
	input_timelength = frametime;

	if (self.movetype == MOVETYPE_WALK) {
//		CheckRoute();
//		WalkRoute();

		self.hitcontentsmaski = CONTENTBITS_MONSTER;
//		if (CanCrouch())
//			PMoveCustom_RunCrouchPhysics(self);
//		else
			PMoveCustom_RunPlayerPhysics(self);

		setorigin(self, self.origin);
//		IdleNoise();

		self.button8 = input_buttons & INPUT_BUTTON8; // duck
	}

#if 0
	if (!(flags & FL_ONGROUND) && velocity[2] < -415) {
		if (!(m_iFlags & MSF_FALLING))
			FallNoise();

		m_iFlags |= MSF_FALLING;
	} else {
		m_iFlags &= ~MSF_FALLING;
	}
#endif

	/* support for think/nextthink */
	if (self.think && self.nextthink > 0.0f) {
		if (self.nextthink < time) {
			self.nextthink = 0.0f;
			self.think();
		}
	}
}

/*
================
monster_use

Using a monster makes it angry at the current activator
================
*/
void monster_use ()
{
	if (self.enemy)
		return;
	if (self.health <= 0)
		return;
	if (isInvalidEnemy(activator))
		return;
	if (activator.classname != "player")
		return;

// delay reaction so if the monster is teleported, its sound is still
// heard
	self.enemy = activator;
	self.nextthink = time + 0.1;
	self.think = FoundTarget;
}

/*
================
monster_death_use

When a mosnter dies, it fires all of its targets with the current
enemy as activator.
================
*/
void monster_death_use ()
{
// fall to ground
	if (self.flags & FL_FLY)
		self.flags = self.flags - FL_FLY;
	if (self.flags & FL_SWIM)
		self.flags = self.flags - FL_SWIM;

	if (!self.target)
		return;

	activator = self.enemy;
	SUB_UseTargets ();
}


//============================================================================

void walkmonster_start_go ()
{
	setorigin(self, self.origin + [0, 0, 1]); // raise off floor a bit
	if (!droptofloor()) {
		dPrintf("walkmonster:%s droptofloor failed at:%v\n", self.classname, self.origin);
	}

	if (!walkmove(0,0))	{
		dPrintf("walkmonster:%s in wall at:%v\n", self.classname, self.origin);
	}

	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 20;
	self.view_ofs = '0 0 25';
	self.use = monster_use;

	self.flags = self.flags | FL_MONSTER;

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		if (self.movetarget.classname == "path_corner")
			self.th_walk ();
		else
			self.pausetime = 99999999;
			self.th_stand ();
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}

// spread think times so they don't all happen at same time
	self.nextthink = time + random()*0.5;
}


void walkmonster_start ()
{
	if (removeMonsterIfLocationOccupied())
		return;

	self.customphysics = monster_physics;

// delay drop to floor to make sure all doors have been spawned
// spread think times so they don't all happen at same time
	self.nextthink = time + 0.1 + random()*0.5;
	self.think = walkmonster_start_go;
	if (isQP())	{
		self.think();
	} else {
		total_monsters = total_monsters + 1;
	}
}



void flymonster_start_go ()
{
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 10;
	self.view_ofs = '0 0 25';
	self.use = monster_use;

	if (!walkmove(0,0))
	{
		dprint ("flymonster in wall at: ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		if (self.movetarget.classname == "path_corner")
			self.th_walk ();
		else
			self.pausetime = 99999999;
			self.th_stand ();
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}
}

void flymonster_start ()
{
	if (removeMonsterIfLocationOccupied())
		return;
// set FL_FLY early so that we're not affected by gravity
	self.flags = self.flags | (FL_FLY | FL_MONSTER);

// spread think times so they don't all happen at same time
	self.nextthink = time + 0.1 + random()*0.5;
	self.think = flymonster_start_go;
	if (isQP())	{
		self.think();
	} else {
		total_monsters = total_monsters + 1;
	}
}


void swimmonster_start_go ()
{
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 10;
	self.view_ofs = '0 0 10';
	self.use = monster_use;

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		self.th_walk ();
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}

// spread think times so they don't all happen at same time
	self.nextthink = time + random()*0.5;
}

void swimmonster_start ()
{
	if (removeMonsterIfLocationOccupied())
		return;
// set FL_SWIM early so that we're not affected by gravity
	self.flags = self.flags | (FL_SWIM | FL_MONSTER);

// spread think times so they don't all happen at same time
	self.nextthink = time + 0.1 + random()*0.5;
	self.think = swimmonster_start_go;
	if (isQP())	{
		self.think();
	} else {
		total_monsters = total_monsters + 1;
	}
}
