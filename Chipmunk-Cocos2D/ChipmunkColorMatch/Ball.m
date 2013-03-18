#import "Ball.h"
#import "Shared.h"


@implementation Ball {
	cpBody *_body;
	Ball *_componentParent;
}

@dynamic componentRoot, pos;

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

+(Ball *)ballAt:(cpVect)pos
{
	return [[Ball alloc] initAt:pos];
}

-(id)initAt:(cpVect)pos
{
	if((self = [super init])){
		int color = arc4random()%6;
		cpFloat radius = cpflerp(30.0f, 40.0f, frand());
		
		CCPhysicsSprite *sprite = [CCSprite spriteWithFile:[NSString stringWithFormat:@"ball_%d.png", color]];
		sprite.position = pos;
		sprite.scale = 2.0f*radius/(sprite.contentSize.width - 8.0f);
		sprite.zOrder = Z_BALLS;
		
		CCPhysicsSprite *highlight = [CCSprite spriteWithFile:@"ball_highlight.png"];
		sprite.position = pos;
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
	if(_body) cpSpaceAddBody(space, _body);
	if(_shape) cpSpaceAddShape(space, _shape);
}

-(void)removeFromSpace:(cpSpace *)space
{
	if(_body) cpSpaceRemoveBody(space, _body);
	if(_shape)	cpSpaceRemoveShape(space, _shape);
}

@end
