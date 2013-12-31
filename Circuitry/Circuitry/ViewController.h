//
//  ViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 9/11/2013.
//  Copyright (c) 2013 Circuitry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "Viewport.h"

@interface ViewController : GLKViewController <UIGestureRecognizerDelegate>


- (IBAction) handlePanGesture:(UIGestureRecognizer *)gestureRecognizer;
- (IBAction) handlePinchGesture:(UIGestureRecognizer *)gestureRecognizer;
- (IBAction) handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer;

@end
