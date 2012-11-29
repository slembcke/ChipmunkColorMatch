//
//  Ball.m
//  ChipmunkColorMatch
//
//  Created by Scott Lembcke on 11/28/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import "Ball.h"
#import "GameViewController.h"
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
		_shape.collisionType = [CollisionTypes objectAtIndex:color];
		_shape.data = self;
		
		_chipmunkObjects = @[_body, _shape];
		
		UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"ball_%d.png", color]];
		CGFloat scale = 2.0*radius/(image.size.width - 8.0f);
		
		_button = [UIButton buttonWithType:UIButtonTypeCustom];
		[_button setImage:image forState:UIControlStateNormal];
		_button.frame = CGRectMake(0, 0, image.size.width*scale, image.size.height*scale);
		_button.center = CGPointZero;
		[_button addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
	}
	
	return self;
}

+(Ball *)ball
{
	return [[Ball alloc] init];
}

-(void)sync;
{
	_button.transform = _body.affineTransform;
}

-(IBAction)clicked:(id)sender
{
	[_game removeBall:self];
}

@end
