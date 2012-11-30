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

#import <Foundation/Foundation.h>
#import "chipmunk.h"

@class GameViewController;


@interface Ball : NSObject

@property(nonatomic, weak) GameViewController *game;

@property(nonatomic, assign) cpVect pos;
@property(nonatomic, readonly) cpShape *shape;

// This is the UIButton object that draws the ball.
// It's also what you click on when you touch it.
@property(nonatomic, readonly) UIButton *button;

// Properties used when finding matched groups of balls.
// See MainLayer.m for how these are used.
@property(nonatomic, weak) Ball *componentRoot;
@property(nonatomic, assign) int componentCount;

// These are hand coded methods that add/remove the objects for the ball to/from the space.
-(void)addToSpace:(cpSpace *)space;
-(void)removeFromSpace:(cpSpace *)space;

+(Ball *)ball;

-(void)sync;

@end
