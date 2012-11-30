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
#import "GameViewController.h"
#import "Shared.h"

@implementation Ball {
	cpBody *_body;
	Ball *_componentParent;
}

@dynamic componentRoot, pos;

// The following two methods implement the other half of the disjoint set forest algorithm.
// See [MainLayer markPairs:space:] for more information.
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
		// The mass will increase with the square of the radius.
		// Since there are only balls in the game, the actual value don't matter as long as they are relative.
		cpFloat mass = radius*radius;
		
		// Create the body.
		_body = cpBodyNew(mass, cpMomentForCircle(mass, 0.0f, radius, cpvzero));
		// Set the user data pointer of the body to point back at the Ball object.
		// That way you can access the Ball object from Chipmunk callbacks and such.
		// If you are using ARC, you'll need to use a brigded cast.
		cpBodySetUserData(_body, (__bridge void *)self);
		
		// Create the collision shape of the ball.
		_shape = cpCircleShapeNew(_body, radius, cpvzero);
		cpShapeSetFriction(_shape, 0.7f);
		// The layers is a bitmask used for filtering collisions or queries.
		// See the [MainLayer ccTouchesBegan:withEvent:] method for more info.
		cpShapeSetLayers(_shape, PhysicsBallLayers);
		// The collision type is an object reference that is used to figure out which if any collision handler to call.
		cpShapeSetCollisionType(_shape, collisionType);
		// Set the user data pointer of the shape to point back at the Ball object.
		// That way you can access the Ball object from Chipmunk callbacks and such.
		cpShapeSetUserData(_shape, (__bridge void *)self);
		
		// Setup the UIButton instance.
		UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"ball_%d.png", color]];
		CGFloat scale = 2.0*radius/(image.size.width - 8.0f);
		
		_button = [UIButton buttonWithType:UIButtonTypeCustom];
		[_button setImage:image forState:UIControlStateNormal];
		_button.frame = CGRectMake(0, 0, image.size.width*scale, image.size.height*scale);
		// Not really sure why, but for the transform to line up properly you need to set the center to (0,0)
		_button.center = CGPointZero;
		[_button addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
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
	// Manually add all the bodies, shapes and joints associated with this object to the space.
	// This approach works, but becomes tedious and error prone when you start to work with composite objects.
	// Objective-Chipmunk, part of Chipmunk Pro provides a nice solution to this though.
	cpSpaceAddBody(space, _body);
	cpSpaceAddShape(space, _shape);
}

-(void)removeFromSpace:(cpSpace *)space
{
	cpSpaceRemoveBody(space, _body);
	cpSpaceRemoveShape(space, _shape);
}

-(void)sync;
{
	// So there are a number of ways that you can sync the view to the body.
	// I implemented it here where at the end of each frame, the transform is copied manually to the view.
	// You could make it more automatic for larger, more complicated projects, but this is the simplest way.
	cpVect pos = cpBodyGetPos(_body);
	CGAffineTransform trans = CGAffineTransformMakeTranslation(pos.x, pos.y);
	CGAffineTransform rot = CGAffineTransformMakeRotation(cpBodyGetAngle(_body));
	_button.transform = CGAffineTransformConcat(rot, trans);
}

-(IBAction)clicked:(id)sender
{
	[_game removeBall:self];
}

@end
