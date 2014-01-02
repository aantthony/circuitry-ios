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
#import "Circuit.h"

@interface ViewController : GLKViewController <UIGestureRecognizerDelegate>


- (IBAction) handlePanGesture:(UIPanGestureRecognizer *) recognizer;

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *) recognizer;

- (IBAction) handleLongPressGesture:(UILongPressGestureRecognizer *) recognizer;

- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos;

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end
