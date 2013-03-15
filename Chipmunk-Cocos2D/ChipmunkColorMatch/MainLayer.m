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
		bg.blendFunc = (ccBlendFunc){GL_ONE, GL_ZERO};
		[self addChild:bg z:Z_BACKGROUND];
		
		CCSprite *fg = [CCSprite spriteWithFile:@"fg.png"];
		fg.anchorPoint = CGPointZero;
		[self addChild:fg z:Z_FOREGROUND];
		
		// Create the array for the balls.
		_balls = [NSMutableArray array];
		
		_space = cpSpaceNew();
		cpSpaceSetGravity(_space, cpv(0, -500));
		[self addBall:[Ball ballAt:cpv(512, 384)]];
		
		[self addBounds];
		
		CCPhysicsDebugNode *debugNode = [CCPhysicsDebugNode debugNodeForCPSpace:_space];
		debugNode.visible = TRUE;
		[self addChild:debugNode z:Z_PHYSICS_DEBUG];
		
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
	// When using ARC you can't ensure that the ball objects will be destroyed before the space.
	[_balls removeAllObjects];
	
	cpSpaceFree(_space);
}

-(void)onEnter
{
	[super onEnter];
	[self scheduleUpdate];
}

-(void)addBounds
{
	cpShape *shape;
	cpBody *staticBody = cpSpaceGetStaticBody(_space);
	cpFloat radius = 20.0;
	
	// left, right, bottom, top
	cpFloat l = 130 - radius;
	cpFloat r = 130 + 767 + radius;
	cpFloat b = 139 - radius;
	cpFloat t = 139 + 1500 + radius;
	
	shape = cpSegmentShapeNew(staticBody, cpv(l, b), cpv(l, t), radius);
	cpShapeSetFriction(shape, 1.0f);
	cpShapeSetLayers(shape, PhysicsEdgeLayers);
	cpSpaceAddShape(_space, shape);
	
	shape = cpSegmentShapeNew(staticBody, cpv(r, b), cpv(r, t), radius);
	cpShapeSetFriction(shape, 1.0f);
	cpShapeSetLayers(shape, PhysicsEdgeLayers);
	cpSpaceAddShape(_space, shape);
	
	shape = cpSegmentShapeNew(staticBody, cpv(l, b), cpv(r, b), radius);
	cpShapeSetFriction(shape, 1.0f);
	cpShapeSetLayers(shape, PhysicsEdgeLayers);
	cpSpaceAddShape(_space, shape);
}

const int TICKS_PER_SECOND = 120;

-(void)update:(ccTime)dt
{
	ccTime fixed_dt = 1.0/(ccTime)TICKS_PER_SECOND;
	
	// Add the current dynamic timestep to the accumulator.
	// Clamp the timestep though to prevent really long frames from causing a large backlog of fixed timesteps to be run.
	_accumulator += MIN(dt, 0.1);
	
	// Subtract off fixed-sized chunks of time from the accumulator and step
	while(_accumulator > fixed_dt){
		[self tick:fixed_dt];
		_accumulator -= fixed_dt;
	}
}

-(void)tick:(ccTime)dt
{
//	[self fillPlayArea];
	[self resetMatchInfo];
	
	cpSpaceStep(_space, dt);
	
	[self checkForMatches];
	_ticks++;
}

-(void)fillPlayArea
{
	if(_balls.count < 70 && _ticks%6 == 0){
		cpVect pos = cpv(512.0f + 300.0f*frand_unit(), 1000.0f);
		Ball *ball = [Ball ballAt:pos];
		[self addBall:ball];
	}
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
}

-(void)resetMatchInfo
{
	for(Ball *ball in _balls){
		ball.componentCount = 1;
		ball.componentRoot = ball;
	}
}

-(void)checkForMatches
{
	for(Ball *ball in [_balls copy]){
		Ball *root = ball.componentRoot;
		
		if(root.componentCount >= 4){
			[self removeBall:ball];
		}
	}
}

static cpBool
MarkPair(cpArbiter *arb, cpSpace *space, void *ptr)
{
	CP_ARBITER_GET_SHAPES(arb, shapeA, shapeB);
	
	Ball *ballA = (__bridge Ball *)cpShapeGetUserData(shapeA);
	Ball *ballB = (__bridge Ball *)cpShapeGetUserData(shapeB);
	
	Ball *rootA = ballA.componentRoot;
	Ball *rootB = ballB.componentRoot;
	
	if(rootA != rootB){
		rootB.componentRoot = rootA.componentRoot;
		rootA.componentCount += rootB.componentCount;
	}
	
	return TRUE;
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	cpVect point = [self convertTouchToNodeSpace:touch];
	
	cpFloat fingerRadius = 10.0;
	cpShape *shape = cpSpaceNearestPointQueryNearest(_space, point, fingerRadius, PhysicsBallOnlyBit, CP_NO_GROUP, NULL);
	
	if(shape){
		Ball *ball = (__bridge Ball *)cpShapeGetUserData(shape);
		[self removeBall:ball];
	}
}

@end
