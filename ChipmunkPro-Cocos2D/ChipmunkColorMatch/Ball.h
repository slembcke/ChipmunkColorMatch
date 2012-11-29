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

#import "ObjectiveChipmunk.h"
#import "cocos2d.h"

@interface Ball : NSObject<ChipmunkObject>

@property(nonatomic, assign) cpVect pos;
@property(nonatomic, readonly) ChipmunkShape *shape;

// Sprites for this ball.
// The regular sprite, and a non-rotating highlight.
@property(nonatomic, readonly) NSArray *sprites;

// This property is all you need to do to implement the ChipmunkObject protocol.
// Simply fill it with the Chipmunk objects that this object owns.
@property(nonatomic, readonly) NSArray *chipmunkObjects;

// Properties used when finding matched groups of balls.
// See MainLayer.m for how these are used.
@property(nonatomic, weak) Ball *componentRoot;
@property(nonatomic, assign) int componentCount;

+(Ball *)ball;

// List of cpCollisionType identifiers.
// Used by the space to add the collision handlers.
+(NSArray *)collisionTypes;

@end
