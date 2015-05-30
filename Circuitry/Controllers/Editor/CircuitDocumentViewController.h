//
//  CircuitDocumentViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 6/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//
@class Circuit;
@class CircuitDocument;
@protocol CircuitDocumentViewControllerDelegate;
@interface CircuitDocumentViewController : UIViewController

@property (weak, nonatomic) id<CircuitDocumentViewControllerDelegate> delegate;
// Container views:
@property (weak, nonatomic) IBOutlet UIView *objectListView;
@property (weak, nonatomic) IBOutlet UIView *problemInfoView;

@property (nonatomic) Circuit *circuit;
@property (nonatomic) CircuitDocument *document;

- (UIImage *) snapshot;

@end


@protocol CircuitDocumentViewControllerDelegate <NSObject>

@required
- (CircuitDocument *) circuitDocumentViewController:(CircuitDocumentViewController *)viewController nextDocumentAfterDocument:(CircuitDocument *)document;
- (void) circuitDocumentViewController:(CircuitDocumentViewController *)viewController didFinish:(CircuitDocument *) sender;

@end