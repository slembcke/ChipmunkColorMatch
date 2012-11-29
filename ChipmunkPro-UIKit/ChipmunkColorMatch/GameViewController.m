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
	NSTimeInterval _accumulator;
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
	
	// Set up a display link to drive the animation.
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(draw:)];
	[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	
	// Create the array for the balls.
	_balls = [NSMutableArray array];
	
	// Set up the physics space
	_space = [[ChipmunkSpace alloc] init];
	_space.gravity = cpv(0.0f, 500.0f);
	// Allow collsion shapes to overlap by 2 pixels.
	// This will make contacts pop on and off less, which helps it find matching groups better.
	_space.collisionSlop = 2.0f;
	
	// Set up collision handlers for each of the colors.
	for(cpCollisionType type in [Ball collisionTypes]){
		// Call the markPair:space: method each time a collision is detected between two balls of the same color.
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

// Add a Ball object to the scene.
-(void)addBall:(Ball *)ball
{
	[_balls addObject:ball];
	
	// The Ball class implements the ChipmunkObject protocol so you can add it directly to the space.
	[_space add:ball];
	
	// Add the ball's view to the scene.
	[self.view insertSubview:ball.button belowSubview:_foreground];
	
	// Set the GamkeViewController instance on the ball so you can remove it later.
	ball.game = self;
}

// This method should look suspiciously similar to addBall:
-(void)removeBall:(Ball *)ball
{
	[_space remove:ball];
	[ball.button removeFromSuperview];
	
	[_balls removeObject:ball];
	ball.game = nil;
}

// This is the method that is called every time Chipmunk detects a collision between two like color balls.
-(bool)markPair:(cpArbiter *)arb space:(ChipmunkSpace *)space
{
	// Get the two shapes involved in the collision.
	// This macro defines the shapeA and shapeB variables for you.
	CHIPMUNK_ARBITER_GET_BODIES(arb, shapeA, shapeB);
	
	// We set the shapes' data pointers to point to the ball that owns them.
	Ball *ballA = shapeA.data;
	Ball *ballB = shapeB.data;
	
	// So the rest of the method is half of the implementation of the disjoint set forest algorithm.
	// I won't further explain the algorithm here, but it's one of my favorites.
	// I use it within Chipmunk itself to find groups of sleeping objects.
	// You can find more information here: http://en.wikipedia.org/wiki/Disjoint_set_forest#Disjoint-set_forests
	
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

const int TICKS_PER_SECOND = 120;

-(void)tick:(NSTimeInterval)dt
{
	// Attempt to add a ball every 6 ticks if the playfield has less than 70 balls.
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
	
	// Step the space forward in time.
	// This is what actually makes the physics go.
	[_space step:dt];
	
	// At this point Chipmunk called markPair:space: a bunch of times.
	// Look for balls in components with 4 or more balls and remove them.
	// Not that I'm iterating a copy of the _balls array.
	// You can't remove objects from an array while iterating it.
	for(Ball *ball in [_balls copy]){
		// Get the component's root and check the count.
		Ball *root = ball.componentRoot;
		if(root.componentCount >= 4){
			[self removeBall:ball];
		}
	}
	
	_ticks++;
}

// This is the method called by DisplayLink each time it draws a frame.
// It implements a fixed timestep to keep the physics running smoothly and deterministically.
// Using a fixed timestep is *highly* recommended with Chipmunk.
// A good article on fixed timesteps can be found here: http://gafferongames.com/game-physics/fix-your-timestep/
// I consider extrapolation/interpolation to be fairly optional unless the tickrate is slower than the framerate.
-(void)draw:(CADisplayLink *)displayLink
{
	NSTimeInterval dt = displayLink.duration*displayLink.frameInterval;
	NSTimeInterval fixed_dt = 1.0/(NSTimeInterval)TICKS_PER_SECOND;
	
	// Add the current dynamic timestep to the accumulator.
	_accumulator += dt;
	// Subtract off fixed-sized chunks of time from the accumulator and step
	while(_accumulator > fixed_dt){
		[self tick:fixed_dt];
		_accumulator -= fixed_dt;
	}
	
	for(Ball *ball in _balls) [ball sync];
}

@end
