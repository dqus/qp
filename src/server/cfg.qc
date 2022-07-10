#define GAMEVARS	\
	GVS(mode,					"qp",		"Game mode") \
	GVF(demorecord,				1,			"Record server side demo")

#define GVF(n,v,d) var float autocvar_g_##n = v;
#define GVS(n,v,d) var string autocvar_g_##n = v;

GAMEVARS

#undef GVF
#undef GVS

void setkey(string key, string val)
{
	cvar_set(strcat("g_", key), val);
}

void setkeyf(string key, float val)
{
	cvar_setf(strcat("g_", key), val);
}

#define getkey(n) autocvar_g_##n
