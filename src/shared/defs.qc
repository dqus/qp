.float		spawn_time; // When this entity was spawned. For players it is the time of respawn.

typedef enum
{
	true = 1,
	false = 0,
	TRUE = 1,
	FALSE = 0
} bool;

// Helpers.
#define printf(...) print(sprintf(__VA_ARGS__))

// Wrapper around spawn().
__wrap entity spawn()
{
	entity e = prior();
	e.spawn_time = time;
	return e;
}

/* tries to make sure an angle value stays within certain constraints...
 * however it doesn't account for much larger discrepancies */
float Math_FixDelta(float fDelta)
{
	if (fDelta >= 180) {
		fDelta -= 360;
	} else if (fDelta <= -180) {
		fDelta += 360;
	}

	return fDelta;
}
