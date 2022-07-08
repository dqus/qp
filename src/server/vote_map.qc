/*
	Copyright (C) 2007 Mark Olsen
*/

static strbuf maplist;

//returns -1 on failure, 0+ for the index it was found at
float map_pool_findidx(string map)
{
	float i = buf_getsize(maplist);
	while (i > 0)
	{
		i--;
		if (bufstr_get(maplist, i) == map)
			return i;
	}
	return -1;
}

//obtains a single map's name
string map_pool_readidx(float idx)
{
	return bufstr_get(maplist, idx);
}

float map_pool_count(void)
{
	return buf_getsize(maplist);
}

//reloads the map pool settings.
void map_pool_init()
{
	string name;
	if (maplist)
		buf_del(maplist);

	maplist = buf_create();

	//all else failed, scan for maps.
	if (!buf_getsize(maplist))
	{
		searchhandle search_handle;
		float i, map_count;
		float offset;
		float namelength;

		search_handle = search_begin("maps/*.bsp", 0, 0);

		offset = 0;

		map_count = search_getsize(search_handle);
		for (i = 0; i < map_count; i++)
		{
			/* Blacklist the b_ files :/ */
			name = search_getfilename(search_handle, i);
			if (substring(name, 0, 7) == "maps/b_")
			{
				offset++;
				continue;
			}

			name = search_getfilename(search_handle, i);
			namelength = strlen(name);
			name = substring(name, 5, namelength-5-4);

			bufstr_add(maplist, name, TRUE);
		}

		search_end(search_handle);
	}
}

string vote_map_cmd(__variant arg, int argc)
{
	string mapstr = argv(1);

	if (mapstr == "" || !strncasecmp(mapstr, "b_", 2))
		return "Invalid map name";
	if not(whichpack(strcat("maps/", mapstr, ".bsp"), false))
		return "Server does not have that map";
	bPrintf(PRINT_HIGH, "%s votes for map %s\n", self.netname, mapstr);

	changelevel(mapstr);
	return "";
}
