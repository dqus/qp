//
// Q-oPerative mode aka QP.
//

static int total_spots; // Total amount of monster spawn spots.

typedef struct
{
	string classname;		// monsters class name.
	void() spawn;			// spawn func.
	int hp_for_kill;		// how much hp player gains for killing such monster.
	int armor_for_kill;		// how much armor player gains for killing such monster.
//	bool boss_able;			// able to be a boss.
} monster_t;

static monster_t monsters[] =
{
	{
		.classname = "monster_dog",
		.spawn = monster_dog,
		.hp_for_kill = 1,
		.armor_for_kill = 1
	},
	{
		.classname = "monster_ogre",
		.spawn = monster_ogre,
		.hp_for_kill = 3,
		.armor_for_kill = 2
	},
	{
		.classname = "monster_demon1",
		.spawn = monster_demon1,
		.hp_for_kill = 4,
		.armor_for_kill = 4
	},
	{
		.classname = "monster_shambler",
		.spawn = monster_shambler,
		.hp_for_kill = 10,
		.armor_for_kill = 8
	},
	{
		.classname = "monster_knight",
		.spawn = monster_knight,
		.hp_for_kill = 1,
		.armor_for_kill = 1
	},
	{
		.classname = "monster_army",
		.spawn = monster_army,
		.hp_for_kill = 1,
		.armor_for_kill = 1
	},
	{
		.classname = "monster_wizard",
		.spawn = monster_wizard,
		.hp_for_kill = 2,
		.armor_for_kill = 2
	},
	{
		.classname = "monster_zombie",
		.spawn = monster_zombie,
		.hp_for_kill = 1,
		.armor_for_kill = 1
	},
	{
		.classname = "monster_tarbaby",
		.spawn = monster_tarbaby,
		.hp_for_kill = 4,
		.armor_for_kill = 4
	},
	{
		.classname = "monster_hell_knight",
		.spawn = monster_hell_knight,
		.hp_for_kill = 4,
		.armor_for_kill = 3
	},
	{
		.classname = "monster_shalrath",
		.spawn = monster_shalrath,
		.hp_for_kill = 6,
		.armor_for_kill = 6
	},
	{
		.classname = "monster_enforcer",
		.spawn = monster_enforcer,
		.hp_for_kill = 2,
		.armor_for_kill = 1
	},
};

// find monster_t in the monsters array by classname.
static monster_t *findMonsterByClassname(string classname)
{
	for (int i = 0; i < monsters.length; i++) {
		if (monsters[i].classname == classname)
			return &monsters[i];
	}
	return __NULL__;
}

bool isQP()
{
	return getkey(mode) == "qp";
}

// Do required actions at start of the game for each player.
static void preparePlayersForGame()
{
	for (entity e = world; (e = nextplayer(e));) {
		if (isDead(e))
			continue; // Player is dead, his fault, not going to forcebly respawn him.
		// Give red armor and health.
		e.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
		e.items |= IT_ARMOR3;
		e.armortype = 0.8;
		e.armorvalue = 200;
		e.health = 250;
		// Reset frags.
		e.frags = 0;
	}
}

static void game_start_disable();
static void game_start_enable();

// Start the game.
static void startGame(entity starter)
{
	if (serverstate == SS_PLAYING)
		return;
	string starterName = (starter.classname == "player" ? starter.netname : "server");
	bPrintf(PRINT_HIGH, "%s ^2""started the game\n", starterName);
	game_start_disable();
	preparePlayersForGame();
	serverstate = SS_PLAYING;
}

// Stop the game.
static void stopGame()
{
	if (serverstate == SS_PREWAR)
		return;
	bPrintf(PRINT_HIGH, "^1""game over\n");
	game_start_enable();
	serverstate = SS_PREWAR;
}

// Stop the game if required.
static void checkStopGame(void)
{
	if (serverstate == SS_PREWAR)
		return;
	// If we found at least one alive player then do not stop the game.
	if (haveAlivePlayers())
		return;
	// All players dead, end game now!
	stopGame();
}

// Called each time something/someone is killed.
void qpKilled(entity killed, entity attacker)
{
	if (serverstate != SS_PLAYING)
		return;

	// If killed was a player then check for endmatch.
	if (killed.flags & FL_CLIENT) {
		checkStopGame();
		return;
	}

	// Alive players regen health for killing monsters.
	if (isDead(attacker) || !(attacker.flags & FL_CLIENT))
		return;
	// 'killed' could be a monter or trigger, we need monster.
	if (!(killed.flags & FL_MONSTER))
		return;

	monster_t *monster = findMonsterByClassname(killed.classname);
	if (!monster)
		return; // Monster not found, should not be the case.
	// HP regen.
	if (attacker.health < 250 && monster->hp_for_kill > 0) {
		attacker.health += monster->hp_for_kill;
		attacker.health = min(attacker.health, 250); // Cap it at 250
	}
	// Armor regen.
	if (attacker.armorvalue < 200 && monster->armor_for_kill > 0) {
		attacker.armorvalue += monster->armor_for_kill;
		attacker.armorvalue = min(attacker.armorvalue, 200); // Cap it at 200
		// Remove all armors and add red armor.
		attacker.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
		attacker.items |= IT_ARMOR3;
		attacker.armortype = 0.8;
	}
	// Bump the score according to monster difficulty.
	if (monster->hp_for_kill > 1)
		attacker.frags += monster->hp_for_kill - 1;
}

// Find best enemy (player) for monster.
entity qp_checkclient(void)
{
	if (!isQP())
		return checkclient(); // If not a qp mode then use plain checkclient() from the engine.

	entity best = __NULL__;
	float best_distance = 0;
	for (entity e = world; (e = nextplayer(e));) {
		if (isInvalidEnemy(e))
			continue;
		vector dir = e.origin - self.origin;
		float distance = dir * dir;
		if (distance < best_distance || best == __NULL__) {
			best = e;
			best_distance = distance;
		}
	}
	return best;
}

// Returns alive monsters count.
int monstersAliveCount(void)
{
	int count = 0;
	for (entity mon = nextent(world); mon != world; mon = nextent(mon)) {
		if((mon.flags & FL_MONSTER) && isAlive(mon))
			count++;
	}
	return count;
}

// Remove self if self.origin occupied by something.
bool removeMonsterIfLocationOccupied(void)
{
	if (!isQP())
		return false;

	setorigin(self, self.origin);
	if (is_location_occupied(self, self.origin)) {
		remove(self);
		return true;
	}
	return false;
}

// Reduce entity alpha time to time till it zero, when alpha becomes zero remove entity at all.
static void entityFade(void)
{
	self.alpha -= 0.025;
	if (self.alpha <= 0) {
		remove(self);
		return;
	}
	self.nextthink = time + 0.05;
}

// Init body/gibs fading in qp mode.
void initEntityFade(entity e)
{
	e.alpha = 1;
	e.think = entityFade;
	e.nextthink = time + 2 + random() * 3;
}

static void game_start_disable()
{
	for (entity e = world; (e = find(e, classname, "info_game_start"));) {
		e.solid = SOLID_NOT;
		e.model = "";
	}
}

static void game_start_enable()
{
	for (entity e = world; (e = find(e, classname, "info_game_start"));) {
		e.solid = SOLID_TRIGGER;
		e.model = e.mdl;
	}
}

void game_start_touch()
{
	if (other.classname != "player" || isDead(other))
		return;
	startGame(other);
}

/*QUAKED info_game_start (0 0 0) (-16 -16 -24) (16 16 32)
*/
void info_game_start(void)
{
	precache_model("progs/quaddama.mdl");
	setmodel(self, "progs/quaddama.mdl");
	self.effects |= EF_BLUE;
	self.touch = game_start_touch;
	setsize(self, '-16 -16 -24', '16 16 32');
	StartItem();
}

/*QUAKED info_monster_start (0 0 0) (-32 -32 -24) (32 32 64)
*/
void info_monster_start(void)
{
	if (total_spots < 0)
		return;
	total_spots++;
}

// Randomly choose spawn spot for monster.
static entity findMonsterSpawnSpot()
{
	static entity mon_spawn;
	// Spawn spots defined by the map itself.
	if (total_spots > 0) {
		// Find random spawn point.
		return find_idx(classname, "info_monster_start", i_rnd(0, total_spots - 1));
	}
	// Use mins/maxs of the world entity to guess spawn points.
	if (!mon_spawn) {
		mon_spawn = spawn(); // It executed once, mon_spawn has static keyword.
		mon_spawn.classname = "mon_spawn";
	}
	// Selecte random location but try to select something not in the wall/floor.
	float x = i_rnd(world.mins_x + 100, world.maxs_x - 100);
	float y = i_rnd(world.mins_y + 100, world.maxs_y - 100);
	float z = min(world.maxs_z - 100, world.mins_z + 1500);
	mon_spawn.origin = [x, y, z];
	return mon_spawn;
}

// Remove monsters if match is not in progress.
static void removeMonsters(void)
{
	if (serverstate == SS_PLAYING)
		return; // Game in progress, nothing to remove.

	for (entity m = world; (m = nextent(m));) {
		if (!(m.flags & FL_MONSTER))
			continue; // not a monster
		remove(m);
	}
}

// Spawn mon at spot.
static entity spawnOneMonsterDo(monster_t mon, entity spot)
{
	entity oself = self; // Remember self.
	entity spawned = spawn();
	self = spawned; // Changed self.
	self.classname = mon.classname;
	self.angles = spot.angles;
	setorigin(self, spot.origin);
	mon.spawn();
	self = oself; // Restore self.
	if (wasfreed(spawned)) {
		return __NULL__; // Seems spawned entity was removed.
	}
	return spawned;
}

// Choose random monster from monsters array and spawn it at random spot.
static entity spawnOneMonster(void)
{
	// Find random spawn point.
	entity spot = findMonsterSpawnSpot();
	// Can't find.
	if (!spot)
		return __NULL__;
	// Randomly select monster.
	monster_t mon = monsters[i_rnd(0, monsters.length - 1)];
	// Spawn monster.
	return spawnOneMonsterDo(mon, spot);
}

// Precache monsters from monsters array by spawning it and immediate remove.
static void precacheMonsters(void)
{
	for (int i = 0; i < monsters.length; i++) {
		monster_t mon = monsters[i];
		safe_remove(spawnOneMonsterDo(mon, world));
	}
}

// Spawn monsters if possible.
static void spawnMonsters(void)
{
	// Precache all monsters at frame 2.
	if (framecount == 2)
		precacheMonsters();
	// Check various conditions if we are ready for spawning monsters.
	if (serverstate != SS_PLAYING
		|| time < 3 || framecount < 100 || monstersAliveCount() >= 1)
		return;
	// Attempt to spawn one monster.
	// We trying to do it few times in row since we can fail because spawn point is busy or something.
	for (int i = 0; i < 30; i++) {
		if (spawnOneMonster())
			return;
	}
}

// QP hook to worldspawn().
void qp_worldspawn()
{
	// Check if map geometry (simple box) let us calculate spawn points for monsters instead of using entities for spawns.
	if (!strncasecmp("qp_", mapname, 3)) {
		dPrintf("^2QP map\n");
		total_spots = -1;
	}
}

// QP hook to StartFrame().
void qp_think(void)
{
	if (!isQP() || total_spots == 0)
		return; // qp mode disabled or map does not support it.

	checkStopGame();
	spawnMonsters();
	removeMonsters();
}
