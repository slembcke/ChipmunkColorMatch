//
//  ViewController.m
//  ChipmunkColorMatch
//
//  Created by Scott Lembcke on 11/28/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import "GameViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "Ball.h"
#import "Shared.h"

@implementation GameViewController {
	IBOutlet UIView *_foreground;
	
	ChipmunkSpace *_space;
	
	NSMutableArray *_balls;
	CADisplayLink *_displayLink;
	
	// Time tracking for the fixed timestep.
	NSTimeInterval _accumulator, _fixedTime;
	int _ticks;
}

-(NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscapeRight;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(draw:)];
	[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	
	_balls = [NSMutableArray array];
	
	// Set up the physics space
	_space = [[ChipmunkSpace alloc] init];
	_space.gravity = cpv(0.0f, 500.0f);
	_space.collisionSlop = 2.0f;
	
	for(cpCollisionType type in [Ball collisionTypes]){
		[_space addCollisionHandler:self typeA:type typeB:type begin:nil preSolve:@selector(markPair:space:) postSolve:nil separate:nil];
	}
	
	// Add bounds around the playfield
	// This is a little goofy due to UIKit's "upside down" coordinate system.
	[_space addBounds:CGRectMake(130, -871, 767, 1500) thickness:20 elasticity:1.0 friction:1.0 layers:CP_ALL_LAYERS group:CP_NO_GROUP collisionType:nil];
	
//	Ball *ball = [Ball ball];
//	ball.pos = cpv(512, 384);
//	[ball sync];
//	[self addBall:ball];
}

-(void)addBall:(Ball *)ball
{
	[_balls addObject:ball];
	
	[_space add:ball];
	[self.view insertSubview:ball.button belowSubview:_foreground];
	ball.game = self;
}

-(void)removeBall:(Ball *)ball
{
	[_space remove:ball];
	[ball.button removeFromSuperview];
	
	[_balls removeObject:ball];
	ball.game = nil;
}

-(bool)markPair:(cpArbiter *)arb space:(ChipmunkSpace *)space
{
	CHIPMUNK_ARBITER_GET_BODIES(arb, shapeA, shapeB);
	
	Ball *ballA = shapeA.data;
	Ball *ballB = shapeB.data;
	
	Ball *rootA = ballA.componentRoot;
	Ball *rootB = ballB.componentRoot;
	
	if(rootA != rootB){
		// Merge the two component trees.
		rootA.componentRoot = rootB.componentRoot;
		rootA.componentCount = rootB.componentCount = rootA.componentCount + rootB.componentCount;
	}
	
	// Returning false would mean Chipmunk should ignore the collision between shapeA and shapeB.
	return TRUE;
}

-(void)tick:(NSTimeInterval)dt
{
	// Attempt to add a ball every few ticks if the playfield has less than 70 balls.
	if(_ticks%6 == 0 && _balls.count < 70){
		Ball *ball = [Ball ball];
		
		// Try up to 10 times to find a clear spot to insert the ball.
		for(int i=0; i<10; i++){
			// Give the ball a random position.
			ball.pos = cpv(512.0f + 300.0f*frand_unit(), -100);
			
			if(![_space shapeTest:ball.shape]){
				// If the area is clear, add the ball and exit the loop.
				[self addBall:ball];
				break;
			}
		}
	}
	
	// Reset the component properties
	for(Ball *ball in _balls){
		ball.componentCount = 1;
		ball.componentRoot = ball;
	}
	
	[_space step:dt];
	
	// Look for balls in components with 4 or more balls.
	// Remove those balls.
	for(Ball *ball in [_balls copy]){
		Ball *root = ball.componentRoot;
		if(root.componentCount >= 4){
			[self removeBall:ball];
			
//			// Play a pop noise.
//			int half_steps = (arc4random()%(2*4 + 1) - 4);
//			float pitch = pow(2.0f, half_steps/12.0f);
//			[[SimpleAudioEngine sharedEngine] playEffect:@"ploop.wav" pitch:pitch pan:0.0 gain:1.0];
		}
	}
	
	_ticks++;
}

-(void)draw:(CADisplayLink *)displayLink
{
	NSTimeInterval dt = displayLink.duration*displayLink.frameInterval;
	NSTimeInterval fixed_dt = 1.0/120.0;
	
	// Add the current dynamic timestep to the accumulator.
	_accumulator += dt;
	// Subtract off fixed-sized chunks of time from the accumulator and step
	while(_accumulator > fixed_dt){
		[self tick:fixed_dt];
		_accumulator -= fixed_dt;
		_fixedTime += fixed_dt;
	}
	
	for(Ball *ball in _balls) [ball sync];
}

//-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//	UITouch *touch = [touches anyObject];
//	cpVect point = [self convertTouchToNodeSpace:touch];
//	
//	// TODO need to filter out the border segments
//	ChipmunkNearestPointQueryInfo *info = [_space nearestPointQueryNearest:point maxDistance:10.0 layers:CP_ALL_LAYERS group:CP_NO_GROUP];
//	if(info.shape){
//		Ball *ball = info.shape.data;
//		[self removeBall:ball];
//		
//		int half_steps = (arc4random()%(2*4 + 1) - 4);
//		float pitch = pow(2.0f, half_steps/12.0f);
//		[[SimpleAudioEngine sharedEngine] playEffect:@"pop.wav" pitch:pitch pan:0.0 gain:1.0];
//	}
//}

@end
