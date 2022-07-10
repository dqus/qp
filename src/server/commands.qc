/*
	commands.qc

	user commands
*/

typedef enum {
	CMD_PASS_TO_ENGINE = 0, // Mod did not recognize user command and SHOULD pass it to the engine.
	CMD_HANDLED = 1, // Mod handled command and should NOT pass command to the engine.
} cmdHandled_t;

typedef struct {
	string name;
	string desc;
	string cb(__variant arg, int argc);
	__variant arg;
	int flags;
} cmd_t;

static bool CheatsAllowed()
{
	return cvar("sv_cheats");
}

static string CheatsAllowedStr()
{
	if (CheatsAllowed())
		return "";
	return "Cheats are not allowed on this server";
}

static string give_cmd(__variant arg, int argc)
{
	string item;
	float	am = 100;

	string err = CheatsAllowedStr();
	if (err != "")
		return err;

	if (argc < 2)
		return "invalid arguments";

	item = argv(1);
	if (argc >= 3)
		am = argvf(2);

	am = max(0, am); // Do not allow negative values.

	if (item == "2")
		self.items = self.items | IT_SHOTGUN;
	else if (item == "3")
		self.items = self.items | IT_SUPER_SHOTGUN;
	else if (item == "4")
		self.items = self.items | IT_NAILGUN;
	else if (item == "5")
		self.items = self.items | IT_SUPER_NAILGUN;
	else if (item == "6")
		self.items = self.items | IT_GRENADE_LAUNCHER;
	else if (item == "7")
		self.items = self.items | IT_ROCKET_LAUNCHER;
	else if (item == "8")
		self.items = self.items | IT_LIGHTNING;
	else if (item == "s" || item == "shells")
		self.ammo_shells = am;
	else if (item == "n" || item == "nails")
		self.ammo_nails = am;
	else if (item == "r" || item == "rockets")
		self.ammo_rockets =am;
	else if (item == "c" || item == "cells")
		self.ammo_cells = am;
	else if (item == "h" || item == "health") {
		self.health = max(1, am); // Do not allow zero health.
	}
	else if (item == "ga") {
		self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
		if (am > 0) {
			self.items = self.items | IT_ARMOR1;
			self.armorvalue = am;
			self.armortype = 0.3;
		}
		else
			self.armorvalue = 0;
	}
	else if (item == "ya") {
		if (argc < 3)
			am = 150;
		self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
		if (am > 0) {
			self.items = self.items | IT_ARMOR2;
			self.armorvalue = am;
			self.armortype = 0.6;
		}
		else
			self.armorvalue = 0;
	}
	else if (item == "ra") {
		if (argc < 3)
			am = 200;
		self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
		if (am > 0) {
			self.items = self.items | IT_ARMOR3;
			self.armorvalue = am;
			self.armortype = 0.8;
		}
		else
			self.armorvalue = 0;
	}
	else if (item == "quad") {
		self.items = self.items | IT_QUAD;
		self.super_time = 1;
		self.super_damage_finished = time + am;
	}
	else if (item == "pent") {
		self.items = self.items | IT_PENT;
		self.invincible_time = 1;
		self.invincible_finished = time + am;
	}
	else if (item == "suit") {
		self.items = self.items | IT_SUIT;
		self.rad_time = 1;
		self.radsuit_finished = time + am;
	}
	else if (item == "ring") {
		self.items = self.items | IT_RING;
		self.invisible_time = 1;
		self.invisible_finished = time + am;
	}
	else if (item == "key1")
		self.items = self.items | IT_KEY1;
	else if (item == "key2")
		self.items = self.items | IT_KEY2;
	else if (item == "rune")
		serverflags = (serverflags * 2 + 1) & 15;
	else if (item == "all") {
		self.items = self.items | IT_ALL_WEAPONS | IT_KEY1 | IT_KEY2;
		self.ammo_shells = 100;
		self.ammo_nails = 200;
		self.ammo_rockets = 100;
		self.ammo_cells = 100;
		if (self.health < 100)
			self.health = 100;
		self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3;
		self.armortype = 0.8;
		self.armorvalue = 200;
	}
	else {
		return strcat("no such item: ", item);
	}
	return "";
}

static string pos_show_cmd(__variant arg, int argc)
{
	string err = CheatsAllowedStr();
	if (err != "")
		return err;

	cPrintf(self, PRINT_HIGH, "position: %v\n", self.origin);
	return "";
}

static string pos_set_cmd(__variant arg, int argc)
{
	string err = CheatsAllowedStr();
	if (err != "")
		return err;

	vector org = [argvf(1), argvf(2), argvf(3)];
	setorigin(self, org); // Unsafe, could stuck in a wall and such, but it is intentionall.
	return "";
}

cmd_t commands[] =
{
	{
		.name = "qp_pos_show",
		.desc = "show position",
		.cb = pos_show_cmd,
		.arg = 0,
		.flags = 0
	},
	{
		.name = "qp_pos_set",
		.desc = "set position",
		.cb = pos_set_cmd,
		.arg = 0,
		.flags = 0
	},
	{
		.name = "qp_votemap",
		.desc = "vote map",
		.cb = vote_map_cmd,
		.arg = 0,
		.flags = 0
	},
	{
		.name = "qp_giveme",
		.desc = "give cheat",
		.cb = give_cmd,
		.arg = 0,
		.flags = 0
	},
};

static void maps_stuffer_cb()
{
	string name = map_pool_readidx(self.stuff_idx++);
	if (name == "") {
		self.stuff_idx = -1; // We done.
		return;
	}
	string aliascmd = sprintf("alias %s_map cmd qp_votemap %s\n", name, name);
	stuffcmd(self, aliascmd);
}

static void commands_stuffer_cb()
{
	// Set up maps stuffing if we done with commands.
	if (self.stuff_idx >= commands.length) {
		self.stuff_cb = maps_stuffer_cb;
		self.stuff_idx = 0;
		return;
	}
	cmd_t cmd = commands[self.stuff_idx++];
	string aliascmd = sprintf("alias %s cmd %s\n", substring(cmd.name, 3, -1), cmd.name);
	stuffcmd(self, aliascmd);
}

void commands_stuffer_do()
{
	// Set up command stuffer when client just connected.
	if (!self.stuff_cb) {
		self.stuff_cb = commands_stuffer_cb;
		self.stuff_idx = 0;
	}
	// Check if we have to stuff something or we already done.
	while (self.stuff_idx >= 0) {
		if (!isbackbuffered(self))
			self.stuff_cb();
	}
}

static cmdHandled_t handle_setinfo(string key, string value)
{
	if (self.classname != "player")
		return CMD_PASS_TO_ENGINE; // Let spectator do whatever he wants with setinfo, we does not care.

	if (key == "team" || key == "name") {
		if (serverstate != SS_PREWAR) {
			cPrintf(self, PRINT_HIGH, "You cannot change %s while the game is in progress\n", key);
			return CMD_HANDLED; // Does not pass command to the engine, so team/name stay the same.
		}
	}
	return CMD_PASS_TO_ENGINE;
}

cmdHandled_t handle_usercmd(int argc)
{
	if (argc < 1 || self.is_fully_connected == 0)
		return CMD_PASS_TO_ENGINE;

	string cmdname = argv(0);

	if (cmdname == "setinfo")
		return handle_setinfo(argv(1), argv(2));
	else if (cmdname == "team" || cmdname == "name") { //for NQ users that lack userinfos clientside.
		return handle_setinfo(cmdname, argv(1));
	} else {
		for (int i = 0; i < commands.length; i++) {
			cmd_t cmd = commands[i];
			if (cmd.name != cmdname)
				continue;
			string err = cmd.cb(0, argc);
			if (err != "")
				cPrintf(self, PRINT_HIGH, "%s\n", err);
			return CMD_HANDLED; // Does not pass command to the engine, we handled it ourself.
		}
	}
	return CMD_PASS_TO_ENGINE;
}

void SV_ParseClientCommand(string str)
{
	int argc = tokenize(str);
	if (argc < 1)
		return;

	// When spectating you need to use say_game to talk to everyone during a game
	if (serverstate == SS_PLAYING && self.classname != "player" && argv(0) == "say")
	{
		if (substring(argv(1), 0, 8) != "say_game") {
			str = substring(str, 3, strlen(str));
			str = strcat("say_team", str);
		} else if (substring(argv(1), 0, 8) == "say_game") {
			if (substring(str, 4, 1) == "\"") {
				// ezquake
				str = substring(str, 14, strlen(str) - 15);
			} else {
				// fodquake
				str = substring(str, 13, strlen(str));
			}

			str = strcat("say ", str);
		}
	}

	if (handle_usercmd(argc) == CMD_PASS_TO_ENGINE)
		clientcommand(self, str);
}
