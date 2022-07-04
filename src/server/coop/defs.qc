//
// globals
//
float	movedist;

//
// monster ai
//
.void() 	th_stand;
.void() 	th_walk;
.void() 	th_run;
.void() 	th_missile;
.void() 	th_melee;
.float() 	th_checkAttack;

.float	lefty;

.float	search_time;
.float	attack_state;

const float	AS_STRAIGHT		= 1;
const float	AS_SLIDING		= 2;
const float	AS_MELEE		= 3;
const float	AS_MISSILE		= 4;

//
// monsters
//
.entity 	movetarget;

//
// sounds
//
.float		waitmin;

//
// forward declarations
//

// QP mode.
bool isQP();
void qp_think(void);
// Find best enemy for monster.
entity qp_checkclient(void);
bool remove_monster_if_location_occupied(void);
// Init body fading in qp mode.
void monster_init_fade(entity e);
// called each time something/someone is killed.
void qp_killed_hook(entity killed, entity attacker);
