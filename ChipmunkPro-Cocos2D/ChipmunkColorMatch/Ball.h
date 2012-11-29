//
//  Ball.h
//  ChipmunkColorMatch
//
//  Created by Scott Lembcke on 11/28/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import "ObjectiveChipmunk.h"
#import "cocos2d.h"

@interface Ball : NSObject<ChipmunkObject>

@property(nonatomic, assign) cpVect pos;
@property(nonatomic, readonly) ChipmunkShape *shape;

// Properties used when finding matched groups of balls.
// See MainLayer.m for how these are used.
@property(nonatomic, weak) Ball *componentRoot;
@property(nonatomic, assign) int componentCount;

@property(nonatomic, readonly) NSArray *sprites;
@property(nonatomic, readonly) NSArray *chipmunkObjects;

+(Ball *)ball;

+(NSArray *)collisionTypes;

@end
