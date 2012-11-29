/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "Ball.h"
#import "Shared.h"


@implementation Ball {
	ChipmunkBody *_body;
	Ball *_componentParent;
}

@dynamic componentRoot, pos;

/*
	This array is the object references used for shape.collisionType.
	'collisionType' is an unretained pointer in Objective-Chipmunk.
	The value is compared *by reference* and not using the equals method.
	Because of this, if you really want, you can use regular ints (not NSNumbers)
	as your collisionTypes. If you are using ARC, this adds a lot of annoying casting though.
	Generally static NSStrings or class references work really well for collision types.
*/
static NSArray *CollisionTypes = nil;

+(void)initialize
{
	CollisionTypes = @[@"1", @"2", @"3", @"4", @"5", @"6"];
}

+(NSArray *)collisionTypes
{
	return CollisionTypes;
}

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
	return _body.pos;
}

-(void)setPos:(cpVect)pos
{
	_body.pos = pos;
}

-(id)init
{
	if((self = [super init])){
		int color = arc4random()%6;
		
		cpFloat radius = cpflerp(30.0f, 40.0f, frand());
		cpFloat mass = radius*radius;
		
		_body = [ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0f, radius, cpvzero)];
		_body.data = self;
		
		_shape = [ChipmunkCircleShape circleWithBody:_body radius:radius offset:cpvzero];
		_shape.friction = 0.7f;
		_shape.layers = PhysicsBallLayers;
		_shape.collisionType = [CollisionTypes objectAtIndex:color];
		_shape.data = self;
		
		_chipmunkObjects = @[_body, _shape];
		
		// Setup the sprites
		CCTexture2D *balls = [[CCTextureCache sharedTextureCache] addImage:@"balls.png"];
		float texSize = balls.contentSize.width/4.0f;
		
		int row = color/4;
		int col = color%4;
		
		CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithFile:@"balls.png" rect:CGRectMake(col*texSize, row*texSize, texSize, texSize)];
		sprite.chipmunkBody = _body;
		sprite.scale = 2.0f*radius/(texSize - 8.0f);
		sprite.zOrder = Z_BALLS;
		
		CCPhysicsSprite *highlight = [CCPhysicsSprite spriteWithFile:@"balls.png" rect:CGRectMake(3*texSize, 1*texSize, texSize, texSize)];
		highlight.chipmunkBody = _body;
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

@end
