//
//  OpenDocumentFromDocumentsListSegue.m
//  Circuitry
//
//  Created by Anthony Foster on 8/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "OpenDocumentFromDocumentsListSegue.h"
#import "CircuitListViewController.h"

@implementation OpenDocumentFromDocumentsListSegue
- (void) perform {
//    return [super perform];
    CircuitListViewController *source = (CircuitListViewController *) self.sourceViewController;
    
    [source.navigationController pushViewController:self.destinationViewController animated:YES];
//    [source.navigationController presentViewController:self.destinationViewController animated:YES completion:^{
//        NSLog(@"complted");
//    }];
}
@end
