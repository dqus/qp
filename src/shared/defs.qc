typedef enum
{
	true = 1,
	false = 0,
	TRUE = 1,
	FALSE = 0
} bool;

// Helpers.
#define printf(...) print(sprintf(__VA_ARGS__))
