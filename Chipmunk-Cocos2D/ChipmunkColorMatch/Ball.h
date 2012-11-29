//
//  Ball.h
//  ChipmunkColorMatch
//
//  Created by Scott Lembcke on 11/28/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import "cocos2d.h"

@interface Ball : NSObject

@property(nonatomic, assign) cpVect pos;
@property(nonatomic, readonly) cpShape *shape;

// Properties used when finding matched groups of balls.
// See MainLayer.m for how these are used.
@property(nonatomic, weak) Ball *componentRoot;
@property(nonatomic, assign) int componentCount;

@property(nonatomic, readonly) NSArray *sprites;

-(void)addToSpace:(cpSpace *)space;
-(void)removeFromSpace:(cpSpace *)space;

+(Ball *)ball;

@end
