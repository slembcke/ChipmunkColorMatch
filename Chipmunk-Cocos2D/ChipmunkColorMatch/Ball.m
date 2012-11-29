//
//  Ball.m
//  ChipmunkColorMatch
//
//  Created by Scott Lembcke on 11/28/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

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
		// Path compression.
		// Make the next lookup quicker by caching the parent's root.
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

-(id)init
{
	if((self = [super init])){
		int color = arc4random()%6;
		
		// color is will be [0, 5], but the collision types need to be non-zero
		cpCollisionType collisionType = color + 1;
		
		cpFloat radius = cpflerp(30.0f, 40.0f, frand());
		cpFloat mass = radius*radius;
		
		_body = cpBodyNew(mass, cpMomentForCircle(mass, 0.0f, radius, cpvzero));
		cpBodySetUserData(_body, (__bridge void *)self);
		
		_shape = cpCircleShapeNew(_body, radius, cpvzero);
		cpShapeSetFriction(_shape, 0.7f);
		cpShapeSetCollisionType(_shape, collisionType);
		cpShapeSetUserData(_shape, (__bridge void *)self);
		
		// Setup the sprites
		CCTexture2D *balls = [[CCTextureCache sharedTextureCache] addImage:@"balls.png"];
		float texSize = balls.contentSize.width/4.0f;
		
		int row = color/4;
		int col = color%4;
		
		CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithFile:@"balls.png" rect:CGRectMake(col*texSize, row*texSize, texSize, texSize)];
		sprite.body = _body;
		sprite.scale = 2.0f*radius/(texSize - 8.0f);
		sprite.zOrder = Z_BALLS;
		
		CCPhysicsSprite *highlight = [CCPhysicsSprite spriteWithFile:@"balls.png" rect:CGRectMake(3*texSize, 1*texSize, texSize, texSize)];
		highlight.body = _body;
		highlight.ignoreBodyRotation = TRUE;
		highlight.scale = sprite.scale;
		highlight.zOrder = Z_BALL_HIGHLIGHTS;
		
		_sprites = @[sprite, highlight];
	}
	
	return self;
}

+(Ball *)ball
{
	return [[Ball alloc] init];
}

-(void)dealloc
{
	cpShapeFree(_shape);
	cpBodyFree(_body);
}

-(void)addToSpace:(cpSpace *)space
{
	cpSpaceAddBody(space, _body);
	cpSpaceAddShape(space, _shape);
}

-(void)removeFromSpace:(cpSpace *)space
{
	cpSpaceRemoveBody(space, _body);
	cpSpaceRemoveShape(space, _shape);
}

@end
