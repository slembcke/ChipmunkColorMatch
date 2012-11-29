static inline cpFloat frand(){return (cpFloat)arc4random()/(cpFloat)UINT32_MAX;}
static inline cpFloat frand_unit(){return 2.0f*frand() - 1.0f;}
