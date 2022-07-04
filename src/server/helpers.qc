void safe_remove(entity e)
{
	if (e != __NULL__)
	{
		remove(e);
	}
}

// Interate client entities only (players/bots/spectators).
entity nextclient(entity from)
{
	for (entity e = from; (e = nextent(e));) {
		float cltype = clienttype(e);
		if (cltype == CLIENTTYPE_NOTACLIENT)
			break; // End of client entities.
		if (cltype != CLIENTTYPE_REAL && cltype != CLIENTTYPE_BOT)
			continue; // Not a client or bot, probably disconnected slot.
		return e; // Found someone.
	}
	return __NULL__;
}

// Interate players/bots entities only.
entity nextplayer(entity from)
{
	for (entity e = from; (e = nextclient(e));) {
		if (e.classname != "player")
			continue;
		return e;
	}
	return __NULL__;
}

float countplayers()
{
	float players = 0;
	entity p = world;

	while ((p = find(p, classname, "player")))
		players += 1;

	return players;
}

// Check if entity would clip with something solid at location. Returns true if clipping detected.
bool is_location_occupied(entity e, vector loc)
{
	entity p;
	tracebox(loc, e.mins, e.maxs, loc, false, e);
	p = trace_ent;
	return (trace_startsolid || trace_fraction != 1 || (p != world && p != e && (p.solid == SOLID_BSP || p.solid == SOLID_SLIDEBOX)));
}

// Find count of edicts matching particular field value.
int find_cnt(.string fld, string match)
{
	int cnt = 0;
	for (entity p = world; (p = find(p, fld, match)); cnt++)
		; // Nothing.
	return cnt;
}

// Find edict with particular index number and matching particular field value.
entity find_idx(.string fld, string match, int idx)
{
	int cnt = 0;

	if (idx < 0)
	{
		return world; // Invalid arguments.
	}

	for (entity p = world; (p = find(p, fld, match)); cnt++)
	{
		if (cnt == idx)
		{
			return p; // Found entity for index.
		}
	}
	return world; // Entity not found.
}

// Returns integer number in [from, to] range.
int i_rnd(int from, int to)
{
	float r;

	if (from >= to)
	{
		return from;
	}

	r = (int)(from + (1.0 + to - from) * random());

	return bound(from, r, to);
}

void safe_precache_model(string name)
{
	if (framecount > 2)
		return;
	precache_model(name);
}

void safe_precache_model2(string name)
{
	if (framecount > 2)
		return;
	precache_model2(name);
}

void safe_precache_sound(string name)
{
	if (framecount > 2)
		return;
	precache_sound(name);
}

void safe_precache_sound2(string name)
{
	if (framecount > 2)
		return;
	precache_sound2(name);
}

bool isAlive(entity e)
{
	return (e != __NULL__ && e.health > 0);
}

bool isDead(entity e)
{
	return !isAlive(e);
}

bool isInvalidEnemy(entity e)
{
	return isDead(e) || (e.flags & FL_NOTARGET) || (e.items & IT_INVISIBILITY);
}

float argvf(int n)
{
	return stof(argv(n));
}
