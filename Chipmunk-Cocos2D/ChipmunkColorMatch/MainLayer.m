//
//  HelloWorldLayer.m
//  ChipmunkColorMatch
//
//  Created by Scott Lembcke on 11/28/12.
//  Copyright Howling Moon Software 2012. All rights reserved.
//

#import "SimpleAudioEngine.h"
#import "MainLayer.h"
#import "Ball.h"
#import "Shared.h"

@implementation MainLayer {
	cpSpace *_space;
	NSMutableArray *_balls;
	
	// Time tracking for the fixed timestep.
	ccTime _accumulator, _fixedTime;
	int _ticks;
}

static NSDictionary *PopParticles = nil;

+(void)initialize
{
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
		
		_balls = [NSMutableArray array];
		
		// Force the balls texture to be trilinear filtered for better texture scaling quality.
		CCTexture2D *balls = [[CCTextureCache sharedTextureCache] addImage:@"balls.png"];
		[balls generateMipmap];
		[balls setTexParameters:(ccTexParams[]){{GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT}}];
		
		// Set up the physics space
		_space = cpSpaceNew();
		cpSpaceSetGravity(_space, cpv(0.0f, -500.0f));
		cpSpaceSetCollisionSlop(_space, 2.0f);
		
		for(cpCollisionType i=1; i<=6; i++){
			cpSpaceAddCollisionHandler(_space, i, i, NULL, (cpCollisionBeginFunc)MarkPair, NULL, NULL, (__bridge void *)self);
		}
		
		// Add bounds around the playfield
		{
			cpShape *shape;
			cpBody *staticBody = cpSpaceGetStaticBody(_space);
			cpFloat radius = 20.0;
			
			shape = cpSpaceAddShape(_space, cpSegmentShapeNew(staticBody, cpv(130 - radius, 139 - radius), cpv(130 - radius, 139 + 1500 + radius), radius));
			cpShapeSetFriction(shape, 1.0f);
			
			shape = cpSpaceAddShape(_space, cpSegmentShapeNew(staticBody, cpv(130 + 767 + radius, 139 - radius), cpv(130 + 767 + radius, 139 + 1500 + radius), radius));
			cpShapeSetFriction(shape, 1.0f);
			
			shape = cpSpaceAddShape(_space, cpSegmentShapeNew(staticBody, cpv(130 - radius, 139 - radius), cpv(130 + 767 + radius, 139 - radius), radius));
			cpShapeSetFriction(shape, 1.0f);
		}
//		[_space addBounds:CGRectMake(130, 139, 767, 1500) thickness:20 elasticity:1.0 friction:1.0 layers:CP_ALL_LAYERS group:CP_NO_GROUP collisionType:nil];
		
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
	[CDAudioManager configure:kAMM_FxOnly];
	[self scheduleUpdate];
	[super onEnter];
}

-(void)addBall:(Ball *)ball
{
	[_balls addObject:ball];
	
	[ball addToSpace:_space];
	
	for(CCNode *node in ball.sprites){
		[self addChild:node];
	}
}

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

static cpBool
MarkPair(cpArbiter *arb, cpSpace *space, MainLayer *self)
{
	CP_ARBITER_GET_SHAPES(arb, shapeA, shapeB);
	
	Ball *ballA = (__bridge Ball *)cpShapeGetUserData(shapeA);
	Ball *ballB = (__bridge Ball *)cpShapeGetUserData(shapeB);
	
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
	
	cpSpaceStep(_space, dt);
	
	// Look for balls in components with 4 or more balls.
	// Remove those balls.
	for(Ball *ball in [_balls copy]){
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

-(void)update:(ccTime)dt
{
	ccTime fixed_dt = 1.0/120.0;
	
	// Add the current dynamic timestep to the accumulator.
	_accumulator += dt;
	// Subtract off fixed-sized chunks of time from the accumulator and step
	while(_accumulator > fixed_dt){
		[self tick:fixed_dt];
		_accumulator -= fixed_dt;
		_fixedTime += fixed_dt;
	}
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	cpVect point = [self convertTouchToNodeSpace:touch];
	
	// TODO need to filter out the border segments
	cpShape *shape = cpSpaceNearestPointQueryNearest(_space, point, 10.0, CP_ALL_LAYERS, CP_NO_GROUP, NULL);
	if(shape){
		Ball *ball = (__bridge Ball *)cpShapeGetUserData(shape);
		[self removeBall:ball];
		
		int half_steps = (arc4random()%(2*4 + 1) - 4);
		float pitch = pow(2.0f, half_steps/12.0f);
		[[SimpleAudioEngine sharedEngine] playEffect:@"pop.wav" pitch:pitch pan:0.0 gain:1.0];
	}
}

@end
