#define RSES_NOLERP 1
#define RSES_NOROTATE 2
//#define RSES_NOTRAILS 4
//#define RSES_NOLIGHTS 8

void CSQC_Init(float apilevel, string enginename, float engineversion)
{
	deltalisten("progs/player.mdl", Player_Update, /*RSES_NOLERP|RSES_NOROTATE*/ 0);
}

void CSQC_UpdateView(float flWidth, float flHeight, float fNotMenu)
{
	clearscene(); //wipe the scene, and apply the default rendering values.
	
	// Manipulate view, add entities here
	setproperty(VF_DRAWWORLD, TRUE);
	setproperty(VF_DRAWENGINESBAR, TRUE);
	setproperty(VF_DRAWCROSSHAIR, TRUE);
	
	addentities(( intermission ? 0 : MASK_VIEWMODEL ) | MASK_ENGINE);
	
	setproperty(VF_ORIGIN, vPlayerOrigin + [ 0, 0, getstatf( STAT_VIEWHEIGHT ) ]);
	setproperty(VF_ANGLES, view_angles);
	
	renderscene();
	
	// Any 2D elements will be here
}

void CSQC_Ent_Update(float isnew)
{
	float enttype = readbyte();
//	print("entupdate\n");
	switch (enttype)
	{
	default:
		error(sprintf("Unknown entity type: %s", ftos(enttype)));
		break;
	}
}

void CSQC_Ent_Remove()
{
	remove(self);
}
