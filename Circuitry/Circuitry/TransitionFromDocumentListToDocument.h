//
//  TransitionFromDocumentListToDocument.h
//  Circuitry
//
//  Created by Anthony Foster on 9/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@interface TransitionFromDocumentListToDocument : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic) BOOL reverse;
@property (nonatomic) CGRect originatingRect;
@property (nonatomic) BOOL fadeIn;
@end
