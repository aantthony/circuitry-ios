//
//  TransitionFromDocumentListToDocument.h
//  Circuitry
//
//  Created by Anthony Foster on 9/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TransitionFromDocumentListToDocument : NSObject <UIViewControllerAnimatedTransitioning>
@property BOOL reverse;
@property CGRect originatingRect;

@end
