// Constants for the different Z-layers
enum Z_LAYERS {
	Z_BACKGROUND,
	Z_BALLS,
	Z_BALL_HIGHLIGHTS,
	Z_OVERLAY,
	Z_FOREGROUND,
	Z_PHYSICS_DEBUG,
	Z_MENU,
};


static inline cpFloat frand(){return (cpFloat)arc4random()/(cpFloat)UINT32_MAX;}
static inline cpFloat frand_unit(){return 2.0f*frand() - 1.0f;}
