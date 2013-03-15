#import "Ball.h"
#import "Shared.h"


@implementation Ball {
	cpBody *_body;
	Ball *_componentParent;
}

+(Ball *)ballAt:(cpVect)pos
{
	return [[Ball alloc] initAt:pos];
}

-(id)initAt:(cpVect)pos
{
	if((self = [super init])){
		int color = arc4random()%6;
		cpFloat radius = cpflerp(30.0f, 40.0f, frand());
		
		cpFloat mass = radius*radius;
		cpFloat moment = cpMomentForCircle(mass, 0, radius, cpvzero);
		_body = cpBodyNew(mass, moment);
		cpBodySetPos(_body, pos);
		cpBodySetUserData(_body, (__bridge void *)self);
		
		_shape = cpCircleShapeNew(_body, radius, cpvzero);
		cpShapeSetUserData(_shape, (__bridge void *)self);
		
//		_shape = cpCircleShapeNew(_body, radius, cpvzero);
//		cpShapeSetFriction(_shape, 0.7f);
//		cpShapeSetLayers(_shape, PhysicsBallLayers);
//		cpShapeSetCollisionType(_shape, color + 1);
//		cpShapeSetUserData(_shape, (__bridge void *)self);
		
		CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithFile:[NSString stringWithFormat:@"ball_%d.png", color]];
		sprite.body = _body;
		sprite.scale = 2.0f*radius/(sprite.contentSize.width - 8.0f);
		sprite.zOrder = Z_BALLS;
		
		CCPhysicsSprite *highlight = [CCPhysicsSprite spriteWithFile:@"ball_highlight.png"];
		highlight.body = _body;
		highlight.ignoreBodyRotation = TRUE;
		highlight.scale = sprite.scale;
		highlight.zOrder = Z_BALL_HIGHLIGHTS;
		
		_sprites = @[sprite, highlight];
	}
	
	return self;
}

-(void)dealloc
{
	cpShapeFree(_shape);
	cpBodyFree(_body);
}

-(void)addToSpace:(cpSpace *)space
{
//	cpSpaceAddBody(space, _body);
//	cpSpaceAddShape(space, _shape);
}

-(void)removeFromSpace:(cpSpace *)space
{
//	cpSpaceRemoveBody(space, _body);
//	cpSpaceRemoveShape(space, _shape);
}

// MARK: Misc

-(Ball *)componentRoot
{
	if(_componentParent != self){
		_componentParent = _componentParent.componentRoot;
	}
	
	return _componentParent;
}

-(void)setComponentRoot:(Ball *)componentRoot
{
	if(componentRoot == self){
		_componentParent = self;
	} else {
		_componentParent = componentRoot.componentRoot;
	}
}

-(cpVect)pos
{
	return cpBodyGetPos(_body);
}

-(void)setPos:(cpVect)pos
{
	cpBodySetPos(_body, pos);
}

@end
