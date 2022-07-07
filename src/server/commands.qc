/*
	commands.qc

	user commands
*/

#if 0

void Cmd_Give ()
{
	string item;
	float	am;

	if (!infokey(world, "*cheats")) {
		sprint (self, PRINT_HIGH, "Cheats are not allowed on this server\n");
		return;
	}

	if (argc() < 2)
		return;

	item = argv(1);
	if (argc() >= 3)
		am = stof(argv(2));
	else
		am = 100;

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
		self.health = am;
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
		if (argc() < 3)
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
		if (argc() < 3)
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
		self.super_time = 0;
		self.super_damage_finished = time + 30;
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
		sprint (self, PRINT_HIGH, "no such item: ", item, "\n");
	}
}


void Cmd_God ()
{
	if (infokey(world, "*cheats") == "") {
		sprint (self, PRINT_HIGH, "Cheats are not allowed on this server\n");
		return;
	}

	if (self.flags & FL_GODMODE)
	{
		self.flags = self.flags - FL_GODMODE;
		sprint (self, PRINT_HIGH, "godmode OFF\n");
	}
	else
	{
		self.flags = self.flags | FL_GODMODE;
		sprint (self, PRINT_HIGH, "godmode ON\n");
	}
}

#ifdef ZQUAKE_STUFF
void Cmd_Observe ()
{
	entity spot;

	if (infokey(self, "*spectator") != "")
		return;

	if (!deathmatch && !coop) {
		sprint (self, PRINT_HIGH, "This command is disabled in single player mode\n");
		return;
	}

	ClientDisconnect ();

	setinfo(self, "*spectator", "1");
	self.movetype = MOVETYPE_NOCLIP;
	self.view_ofs = '0 0 22';
	self.fixangle = true;
	spot = find (world, classname, "info_player_start");
	self.origin = spot.origin;
	self.angles = spot.angles;

	SpectatorConnect ();
}

void Cmd_Join ()
{
	if (infokey(self, "*spectator") == "")
		return;

	if (!deathmatch && !coop) {
		sprint (self, PRINT_HIGH, "This command is disabled in single player mode\n");
		return;
	}

	SpectatorDisconnect ();
	setinfo(self, "*spectator", "");
	ClientConnect ();
	PutClientInServer ();
}
#endif


/*
** ZQ_CLIENTCOMMAND extension
*/
float GE_ClientCommand (string cmd, string args)
{
	if (cmd == "give")
		Cmd_Give ();
	else if (cmd == "god")
		Cmd_God ();
#ifdef ZQUAKE_STUFF
	else if (cmd == "join")
		Cmd_Join ();
	else if (cmd == "observe")
		Cmd_Observe ();
#endif
#ifdef FRIKBOT
	else if (BotClientCommand(cmd, args))
		return true;
#endif
	else
		return false;

	return true;
}

#endif

typedef struct {
	string name;
	string desc;
	string cb(__variant arg);
	__variant arg;
	int flags;
} cmd_t;

static string pos_show_cmd(__variant arg)
{
	cPrintf(self, PRINT_HIGH, "^1fixme\n");
	return "";
}

static string pos_set_cmd(__variant arg)
{
	cPrintf(self, PRINT_HIGH, "^1fixme\n");
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

static float handle_setinfo(string key, string value)
{
#if 0
	if (key == "team")
	{
		self.userteam = value;
		if (self.classname == "player" && (self.ready || serverstate == serverstate_countdown || serverstate == serverstate_playing))
		{
			if (self.teamname != self.userteam)
				sprint(self, PRINT_HIGH, "Your team will be changed at the end of the match.\n");
			return TRUE;
		}
		forceinfokey(self, "team", value);
		self.teamname = infokey(self, "team");
		return TRUE;
	}
	if (key == "name")
	{
		if (self.classname == "player" && (serverstate == serverstate_countdown || serverstate == serverstate_playing))
		{
			if (self.netname != value)
				sprint(self, PRINT_HIGH, "You cannot change name while the game is in progress.\n");
			return TRUE;
		}
	}
#endif
	return FALSE;
}

float handle_usercmd(float argc)
{
	if (argc < 1 || self.is_fully_connected == 0)
		return 0;

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
			string err = cmd.cb(0);
			if (err != "")
				cPrintf(self, PRINT_HIGH, "%s\n", err);
			return 1;
		}
	}
	return 0;
};


void SV_ParseClientCommand(string str)
{
	float numargs = tokenize(str);
	if (numargs < 1)
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

	if (handle_usercmd(numargs) == 0)
		clientcommand(self, str);
};
