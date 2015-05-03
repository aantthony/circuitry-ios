//
//  TouchHighlight.h
//  Circuitry
//
//  Created by Anthony Foster on 19/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface TouchHighlight : NSObject
- (BOOL) drawTouchMatchingAtPosition:(GLKVector2)position progress:(GLfloat)progress withTransform:(GLKMatrix4) viewProjectionMatrix;
- (BOOL) drawOutFromPosition:(GLKVector2)position progress:(GLfloat)progress withTransform:(GLKMatrix4) viewProjectionMatrix;
@end
