//
//  CircuitListControllerViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 7/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitListViewController.h"

#import "CircuitDocument.h"
#import "AppDelegate.h"
#import "CircuitCollectionViewCell.h"

#import "UIAlertView+MKBlockAdditions.h"

//#import "OpenDocumentFromDocumentsListSegue.h"

#import "TransitionFromDocumentListToDocument.h"

@interface DocumentListItem : NSObject
@property NSURL *url;
@property NSString *title;
@property NSDate *lastModified;
@end
@implementation DocumentListItem
- (id) initWithURL: (NSURL *)url; {
    self = [super init];
    _url = url;
    NSInputStream *stream = [[NSInputStream alloc] initWithURL:[url URLByAppendingPathComponent:@"package.json"]];
    [stream open];
    NSDictionary *package = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:NULL];
    _title = package[@"title"];
    
    NSDictionary* properties = [[NSFileManager defaultManager]
                                attributesOfItemAtPath:url.path
                                error:NULL];
    
    _lastModified = [properties objectForKey:NSFileModificationDate];
    NSLog(@"last modified: %@", _lastModified);

    return self;
}
@end

@interface CircuitListViewController () <UIActionSheetDelegate, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>
@property NSMutableArray *items;
@property NSMutableArray *circuits;
@property NSMutableArray *problems;
@property ViewController *documentViewController;
@property NSIndexPath *actionSheetIndexPath;
@property CGRect selectionRect;
@property BOOL openDocumentAnimationShouldFadeIn;
@end

@implementation CircuitListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_items == _circuits) {
        return _circuits.count + 1;
    }
    return _items.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CircuitListHeader" forIndexPath:indexPath];
        
        reusableview = headerView;
    }
    return reusableview;
}

- (void) openDocument: (NSURL *)url {
    ViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"Viewing Circuit"];
    
    [controller loadURL:url complete:^(NSError *error) { 
        if (error) [[NSException exceptionWithName:error.localizedDescription reason:error.localizedFailureReason userInfo:nil] raise];
        
        [self.navigationController pushViewController:controller animated:YES];
    }];
}

- (IBAction) createDocument:(id)sender {
    NSString *_id = [MongoID stringWithId:[MongoID id]];
    NSURL *url = [[AppDelegate documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.circuit", _id]];
    
    int index = 0;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index + 1 inSection:0];
    
    [self.collectionView performBatchUpdates:^{
        
        NSArray *selectedItemsIndexPaths = @[indexPath];
        
        DocumentListItem *item = [[DocumentListItem alloc] initWithURL:url];
        
        [_circuits insertObject:item atIndex:index];
        if (_items == _circuits) {
            [self.collectionView insertItemsAtIndexPaths:selectedItemsIndexPaths];
        }

    } completion:^(BOOL finished) {
        if (_items == _circuits) {
            CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:indexPath];
            _selectionRect = [self.view convertRect:cell.imageView.frame fromView:cell];
        }
        [self openDocument:url];
    }];
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    if (_items == _circuits) {
        NSURL *docURL = nil;
        if (indexPath.row) {
            DocumentListItem *item = [_items objectAtIndex:indexPath.row - 1];
            docURL = item.url;
            CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [collectionView cellForItemAtIndexPath:indexPath];
            _selectionRect = [self.view convertRect:cell.imageView.frame fromView:cell];
            _openDocumentAnimationShouldFadeIn = NO;
            [self openDocument:docURL];
        } else {
            CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [collectionView cellForItemAtIndexPath:indexPath];
            _selectionRect = [self.view convertRect:cell.imageView.frame fromView:cell];
            _openDocumentAnimationShouldFadeIn = YES;
            [self createDocument:collectionView];
        }
    }
}

- (IBAction)edit:(UIBarButtonItem *)sender {
    [self reloadCircuitListData];
}

- (IBAction)didChangeCircuitsProblemsSegment:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        // circuits
        _items = _circuits;
        [self.collectionView reloadData];
    } else {
        // problems
        _items = _problems;
        [self.collectionView reloadData];
    }
}

- (void) preload {
    ViewController *viewcontroller = [[ViewController alloc] init];
    [self.view addSubview:viewcontroller.view];
    [viewcontroller.view removeFromSuperview];
}

- (IBAction) didLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (_items == _circuits) {
            _actionSheetIndexPath = [self.collectionView indexPathForItemAtPoint: [sender locationInView:self.collectionView]];
            CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:_actionSheetIndexPath];
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:cell.textLabel.text delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Share", nil];
            CGRect rect = [self.view convertRect:cell.imageView.frame fromView:cell];
            [sheet showFromRect:rect inView:self.view animated:YES];
        }
    }
}

#pragma mark -
#pragma mark UIActionSheetDelegate Methods


// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // delete
        UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Delete Circuit" message:@"Are you sure you want to delete this circuit?" cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Delete"] onDismiss:^(int buttonIndex) {
            if (buttonIndex == 0) {
                [self.collectionView performBatchUpdates:^{
                    
                    NSArray *selectedItemsIndexPaths = @[_actionSheetIndexPath];

                    [self deleteItemsFromDataSourceAtIndexPaths:selectedItemsIndexPaths];
                    
                    [self.collectionView deleteItemsAtIndexPaths:selectedItemsIndexPaths];
                    
                } completion:nil];
            }
        } onCancel:nil];
        
        [alert show];
    } else if (buttonIndex == 1) {
        [[[UIAlertView alloc] initWithTitle:@"Not implemented" message:@"Share feature not implemented" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

- (void) deleteURL:(NSURL *)fileURL {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting
                                              error:nil byAccessor:^(NSURL* writingURL) {
                                                  NSFileManager* fileManager = [[NSFileManager alloc] init];
                                                  fileManager = [NSFileManager defaultManager];
                                                  NSLog(@"Delete %@", writingURL);
                                                  [fileManager removeItemAtURL:writingURL error:nil];
                                              }];
    });
}

-(void)deleteItemsFromDataSourceAtIndexPaths:(NSArray  *)itemPaths {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *itemPath  in itemPaths) {
        if (itemPath.row == 0) {
            [[NSException exceptionWithName:@"Could not remove \"Create Circuit\" item from list" reason:nil userInfo:nil] raise];
        }
        int index = itemPath.row - 1;
        DocumentListItem *item = [_items objectAtIndex:index];
        [self deleteURL:item.url];
        [indexSet addIndex:index];
    }
    [_items removeObjectsAtIndexes:indexSet];
}

#pragma mark -
#pragma mark UICollectionViewDataSource methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_items == _circuits) {
        if (indexPath.row == 0) {
            return [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitCreatePrototypeCell" forIndexPath:indexPath];
        }
        
        CircuitCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitListPrototypeCell" forIndexPath:indexPath];
        
        DocumentListItem *item = [_items objectAtIndex:indexPath.row - 1];
        
        cell.textLabel.text = item.title;
        [cell.imageView loadURL:item.url];
        return cell;
    } else {
        
        CircuitCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitListPrototypeCell" forIndexPath:indexPath];
        
        DocumentListItem *item = [_items objectAtIndex:indexPath.row];
        
        cell.textLabel.text = item.title;
        return cell;
    }
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTransitioningDelegate:self];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self preload];
        dispatch_async(dispatch_get_main_queue(), ^(void){
        });
    });
    

    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;
}

#pragma mark - Navigation Controller Delegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    // Check if we're transitioning from this view controller to a DSLSecondViewController
    if (fromVC == self && [toVC isKindOfClass:[ViewController class]]) {
        TransitionFromDocumentListToDocument *delegate = [[TransitionFromDocumentListToDocument alloc] init];
        delegate.originatingRect = _selectionRect;
        delegate.fadeIn = _openDocumentAnimationShouldFadeIn;
        return delegate;
    }
    
    if ([fromVC isKindOfClass:[ViewController class]]) {
        TransitionFromDocumentListToDocument *delegate = [[TransitionFromDocumentListToDocument alloc] init];
        delegate.reverse = YES;
        delegate.originatingRect = _selectionRect;
        if (_openDocumentAnimationShouldFadeIn) {
            ViewController * controller = (ViewController *) fromVC;
            NSURL *url = controller.documentURL;
            NSString *urlPath = url.path;
            __block BOOL found = NO;
            [_items enumerateObjectsUsingBlock:^(DocumentListItem *item, NSUInteger idx, BOOL *stop) {
                if ([item.url.path isEqualToString:urlPath]) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx + 1 inSection:0];
                    
                    CircuitCollectionViewCell * cell = (CircuitCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                    delegate.originatingRect = [self.view convertRect:cell.imageView.frame fromView:cell];
                    found = YES;
                    *stop = YES;
                }
            }];
            
            if (!found) {
                NSLog(@"Could not find rect");
            }
        }
        return delegate;
    }

    return nil;
}

//
//#pragma mark - Transitioning Delegate (Modal)
//-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
//    _modalAnimationController.type = AnimationTypePresent;
//    return _modalAnimationController;
//}
//
//-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
//    _modalAnimationController.type = AnimationTypeDismiss;
//    return _modalAnimationController;
//}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadCircuitListData];
}

- (void) reloadCircuitListData {
    
    NSString *directoryPath = [AppDelegate.documentsDirectory path];
    
    NSArray* localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:
                               directoryPath error:nil];
    
    
    NSMutableArray *items = [NSMutableArray array];
    
    
    for (NSString* document in localDocuments) {
        NSURL *url = [NSURL fileURLWithPath:[directoryPath
                                             stringByAppendingPathComponent:document]];
        
        DocumentListItem *item = [[DocumentListItem alloc] initWithURL:url];
        
        [items addObject:item];
    }
    _circuits = [[items sortedArrayUsingComparator:^NSComparisonResult(DocumentListItem *obj1, DocumentListItem *obj2) {
        return [obj2.lastModified compare: obj1.lastModified];
    }] mutableCopy];
    
    _items = _circuits;
    [self.collectionView reloadData];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
