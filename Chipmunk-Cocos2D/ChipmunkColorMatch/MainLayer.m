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

#import "SimpleAudioEngine.h"
#import "MainLayer.h"
#import "Ball.h"
#import "Shared.h"

@implementation MainLayer {
	cpSpace *_space;
	NSMutableArray *_balls;
	
	// Time tracking for the fixed timestep.
	ccTime _accumulator;
	int _ticks;
}

static NSDictionary *PopParticles = nil;

+(void)initialize
{
	// Preload the plist definition for the pop particles.
	NSString *path = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:@"pop.plist"];
	PopParticles = [NSDictionary dictionaryWithContentsOfFile:path];
}

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild:[MainLayer node]];
	return scene;
}

-(id) init
{
	if((self = [super init])){
		self.touchEnabled = TRUE;
		
		// Set up the foreground/background layers.
		CCSprite *bg = [CCSprite spriteWithFile:@"bg.png"];
		bg.anchorPoint = CGPointZero;
		[self addChild:bg z:Z_BACKGROUND];
		
		CCSprite *fg = [CCSprite spriteWithFile:@"fg.png"];
		fg.anchorPoint = CGPointZero;
		[self addChild:fg z:Z_FOREGROUND];
		
		// Create the array for the balls.
		_balls = [NSMutableArray array];
		
		// Force the balls texture to be trilinear filtered for better texture scaling quality.
		CCTexture2D *balls = [[CCTextureCache sharedTextureCache] addImage:@"balls.png"];
		[balls generateMipmap];
		[balls setTexParameters:(ccTexParams[]){{GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT}}];
		
		// Set up the physics space
		_space = cpSpaceNew();
		cpSpaceSetGravity(_space, cpv(0.0f, -500.0f));
		// Allow collsion shapes to overlap by 2 pixels.
		// This will make contacts pop on and off less, which helps it find matching groups better.
		cpSpaceSetCollisionSlop(_space, 2.0f);
		
		// Set up collision handlers for each of the colors.
		for(cpCollisionType i=1; i<=6; i++){
			// Call the MarkPair function each time a collision is detected between two balls of the same color.
			// self is passed as the last parameter of MarkPair.
			cpSpaceAddCollisionHandler(_space, i, i, NULL, (cpCollisionBeginFunc)MarkPair, NULL, NULL, (__bridge void *)self);
		}
		
		// Add bounds around the playfield
		{
			cpShape *shape;
			cpBody *staticBody = cpSpaceGetStaticBody(_space);
			cpFloat radius = 20.0;
			
			shape = cpSpaceAddShape(_space, cpSegmentShapeNew(staticBody, cpv(130 - radius, 139 - radius), cpv(130 - radius, 139 + 1500 + radius), radius));
			cpShapeSetFriction(shape, 1.0f);
			cpShapeSetLayers(shape, PhysicsEdgeLayers);
			
			shape = cpSpaceAddShape(_space, cpSegmentShapeNew(staticBody, cpv(130 + 767 + radius, 139 - radius), cpv(130 + 767 + radius, 139 + 1500 + radius), radius));
			cpShapeSetFriction(shape, 1.0f);
			cpShapeSetLayers(shape, PhysicsEdgeLayers);
			
			shape = cpSpaceAddShape(_space, cpSegmentShapeNew(staticBody, cpv(130 - radius, 139 - radius), cpv(130 + 767 + radius, 139 - radius), radius));
			cpShapeSetFriction(shape, 1.0f);
			cpShapeSetLayers(shape, PhysicsEdgeLayers);
		}
		
		// The debug node will draw an overlay of the physics shapes.
		// Very useful for debugging so that you know your collision shapes and graphics line up.
		CCPhysicsDebugNode *debugNode = [CCPhysicsDebugNode debugNodeForCPSpace:_space];
		debugNode.visible = FALSE;
		[self addChild:debugNode z:Z_PHYSICS_DEBUG];
		
		// Add a menu item to toggle the debug rendering.
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Toggle Debug" fontName:@"Helvetica" fontSize:30];
		label.color = ccBLACK;
		
		CCMenuItemLabel *item = [CCMenuItemLabel itemWithLabel:label block:^(id sender){debugNode.visible ^= TRUE;}];
		item.position = ccp(870, 740);
		
		CCMenu *menu = [CCMenu menuWithItems:item, nil];
		menu.position = CGPointZero;
		[self addChild:menu z:Z_MENU];
	}
	
	return self;
}

-(void)dealloc
{
	// When using ARC you can't ensure that the ball objects will be destroyed 
	[_balls removeAllObjects];
	
	cpSpaceFree(_space);
}

-(void)onEnter
{
	[self scheduleUpdate];
	[super onEnter];
}

// Add a Ball object to the scene.
-(void)addBall:(Ball *)ball
{
	[_balls addObject:ball];
	
	// The addToSpace: method manually adds all the Chipmunk objects to the space.
	[ball addToSpace:_space];
	
	// Add each sprite for the ball to the scene.
	for(CCNode *node in ball.sprites){
		[self addChild:node];
	}
}

// This method should look suspiciously similar to addBall:
-(void)removeBall:(Ball *)ball
{
	[ball removeFromSpace:_space];
	
	for(CCNode *node in ball.sprites){
		[self removeChild:node];
	}
	
	[_balls removeObject:ball];
	
	// Draw particles whenever a ball is removed.
	CCParticleSystem *particles = [[CCParticleSystemQuad alloc] initWithDictionary:PopParticles];
	particles.position = ball.pos;
	particles.autoRemoveOnFinish = TRUE;
	[self addChild:particles z:Z_PARTICLES];
}

// This is the function that is called every time Chipmunk detects a collision between two like color balls.
static cpBool
MarkPair(cpArbiter *arb, cpSpace *space, MainLayer *self)
{
	// Get the two shapes involved in the collision.
	// This macro defines the shapeA and shapeB variables for you.
	CP_ARBITER_GET_SHAPES(arb, shapeA, shapeB);
	
	// We set the shapes' data pointers to point to the ball that owns them.
	// If you are using ARC, you need to use a bridged cast.
	Ball *ballA = (__bridge Ball *)cpShapeGetUserData(shapeA);
	Ball *ballB = (__bridge Ball *)cpShapeGetUserData(shapeB);
	
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

-(void)tick:(ccTime)dt
{
	// Attempt to add a ball every few ticks if the playfield has less than 70 balls.
	if(_ticks%6 == 0 && _balls.count < 70){
		Ball *ball = [Ball ball];
		
		// Try up to 10 times to find a clear spot to insert the ball.
		for(int i=0; i<10; i++){
			// Give the ball a random position.
			ball.pos = cpv(512.0f + 300.0f*frand_unit(), 1000.0f);
			
			if(!cpSpaceShapeQuery(_space, ball.shape, NULL, NULL)){
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
	cpSpaceStep(_space, dt);
	
	// At this point Chipmunk called markPair:space: a bunch of times.
	// Look for balls in components with 4 or more balls and remove them.
	// Not that I'm iterating a copy of the _balls array.
	// You can't remove objects from an array while iterating it.
	for(Ball *ball in [_balls copy]){
		// Get the component's root and check the count.
		Ball *root = ball.componentRoot;
		if(root.componentCount >= 4){
			[self removeBall:ball];
			
			// Play a pop noise.
			int half_steps = (arc4random()%(2*4 + 1) - 4);
			float pitch = pow(2.0f, half_steps/12.0f);
			[[SimpleAudioEngine sharedEngine] playEffect:@"ploop.wav" pitch:pitch pan:0.0 gain:1.0];
		}
	}
	
	_ticks++;
}

// This is the update method called by Cocos2D each time it draws a frame.
// It implements a fixed timestep to keep the physics running smoothly and deterministically.
// Using a fixed timestep is *highly* recommended with Chipmunk.
// A good article on fixed timesteps can be found here: http://gafferongames.com/game-physics/fix-your-timestep/
// I consider extrapolation/interpolation to be fairly optional unless the tickrate is slower than the framerate.
-(void)update:(ccTime)dt
{
	ccTime fixed_dt = 1.0/(ccTime)TICKS_PER_SECOND;
	
	// Add the current dynamic timestep to the accumulator.
	_accumulator += dt;
	// Subtract off fixed-sized chunks of time from the accumulator and step
	while(_accumulator > fixed_dt){
		[self tick:fixed_dt];
		_accumulator -= fixed_dt;
	}
}

// This method removes balls when you touch them.
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Convert the touch position to the correct coordinate system.
	UITouch *touch = [touches anyObject];
	cpVect point = [self convertTouchToNodeSpace:touch];
	
	// Perform a nearest point query to see what the closest shape to the touch is.
	// It only finds shapes that are within fingerRadius distance though.
	// Also, it is using PhysicsBallOnlyBit to filter out the results so it will only return a ball and not an edge shape.
	cpFloat fingerRadius = 10.0;
	cpShape *shape = cpSpaceNearestPointQueryNearest(_space, point, fingerRadius, PhysicsBallOnlyBit, CP_NO_GROUP, NULL);
	if(shape){
		Ball *ball = (__bridge Ball *)cpShapeGetUserData(shape);
		[self removeBall:ball];
		
		int half_steps = (arc4random()%(2*4 + 1) - 4);
		float pitch = pow(2.0f, half_steps/12.0f);
		[[SimpleAudioEngine sharedEngine] playEffect:@"pop.wav" pitch:pitch pan:0.0 gain:1.0];
	}
}

@end
