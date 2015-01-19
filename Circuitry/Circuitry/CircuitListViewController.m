//
//  CircuitListControllerViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 7/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitListViewController.h"

#import "CircuitDocument.h"
#import "ProblemSet.h"
#import "AppDelegate.h"
#import "CircuitCollectionViewCell.h"

#import "UIAlertView+MKBlockAdditions.h"
#import "AnalyticsManager.h"

//#import "OpenDocumentFromDocumentsListSegue.h"

#import "TransitionFromDocumentListToDocument.h"

#import "CircuitDocumentViewController.h"
#import "ViewController.h"

@interface DocumentListItem : NSObject
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *lastModified;

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
    NSLog(@"Loaded circuit: %@", _title);

    return self;
}

@end

@interface CircuitListViewController () <UIActionSheetDelegate, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate, CircuitDocumentViewControllerDelegate>
@property (nonatomic) NSMutableArray *circuits;
@property (nonatomic) ProblemSet *problemSet;
@property (nonatomic) ViewController *documentViewController;
@property (nonatomic) NSIndexPath *actionSheetIndexPath;
@property (nonatomic) CGRect selectionRect;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createButton;
@property (nonatomic) BOOL openDocumentAnimationShouldFadeIn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic) CircuitDocument *presentingDocument;
@property (nonatomic) BOOL displayingProblems;
@end

@implementation CircuitListViewController

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_displayingProblems) {
        return _problemSet.problems.count;
    } else {
        return _circuits.count + 1;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CircuitListHeader" forIndexPath:indexPath];
        
        reusableview = headerView;
    }
    return reusableview;
}

- (void) createAndOpenNewDocumentWithURL:(NSURL *)url {
    
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"blank" withExtension:@"json"];
    NSInputStream *stream = [NSInputStream inputStreamWithURL:path];
    [stream open];
    Circuit *circuit = [[Circuit alloc] initWithPackage:[NSJSONSerialization JSONObjectWithStream:stream options:0 error:nil] items:@[]];
    
    CircuitDocument *doc = [[CircuitDocument alloc] initWithFileURL:url];
    doc.circuit = circuit;
    _presentingDocument = doc;
    [doc openWithCompletionHandler:^(BOOL success){
        [doc saveToURL:doc.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:nil];
        [self performSegueWithIdentifier:@"presentDocument" sender:self];
    }];
}

- (void) openProblem: (ProblemSetProblemInfo *) problemInfo {
    self.presentingDocument = [[CircuitDocument alloc] initWithFileURL:problemInfo.documentURL];
    self.presentingDocument.problemInfo = problemInfo;
    [self.presentingDocument openWithCompletionHandler:^(BOOL success){
        [self performSegueWithIdentifier:@"presentDocument" sender:self];
    }];
}

- (CircuitDocument *) circuitDocumentViewController:(CircuitDocumentViewController *)viewController nextDocumentAfterDocument:(CircuitDocument *)document {
    ProblemSetProblemInfo *info = document.problemInfo;
    ProblemSetProblemInfo *nextInfo = [info.set problemAfterProblem:info];
    if (!nextInfo) return nil;
    CircuitDocument *next = [[CircuitDocument alloc] initWithFileURL:nextInfo.documentURL];
    next.problemInfo = nextInfo;
    return next;
}

- (void) openDocumentItem:(DocumentListItem *)documentListItem {
    self.presentingDocument = [[CircuitDocument alloc] initWithFileURL:documentListItem.url];
    [self.presentingDocument openWithCompletionHandler:^(BOOL success){
        [self performSegueWithIdentifier:@"presentDocument" sender:self];
    }];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"presentDocument"]) {
        
        CircuitDocumentViewController *controller = [segue destinationViewController];
        controller.delegate = self;
        controller.document = _presentingDocument;
        
        [[AnalyticsManager shared] trackOpenDocument:_presentingDocument];
    }
}


- (IBAction) createDocument:(id)sender {
    if (_displayingProblems) return;
    
    NSString *_id = [MongoID stringWithId:[MongoID id]];
    NSURL *url = [[(AppDelegate *)[UIApplication sharedApplication].delegate documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.circuit", _id]];
    
    int index = 0;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index + 1 inSection:0];
    
    // TODO: Use fetched results controller somehow?
    [self.collectionView performBatchUpdates:^{
        
        NSArray *selectedItemsIndexPaths = @[indexPath];
        
        DocumentListItem *item = [[DocumentListItem alloc] initWithURL:url];
        [_circuits insertObject:item atIndex:index];
        [self.collectionView insertItemsAtIndexPaths:selectedItemsIndexPaths];

    } completion:^(BOOL finished) {
        CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:indexPath];
        _selectionRect = [self.view convertRect:cell.imageView.frame fromView:cell];
        [self createAndOpenNewDocumentWithURL:url];
    }];
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    if (!_displayingProblems) {
        if (indexPath.row) {
            DocumentListItem *item = [_circuits objectAtIndex:indexPath.row - 1];
            CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [collectionView cellForItemAtIndexPath:indexPath];
            _selectionRect = [self.view convertRect:cell.imageView.frame fromView:cell];
            _openDocumentAnimationShouldFadeIn = NO;
            [self openDocumentItem:item];
        } else {
            CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [collectionView cellForItemAtIndexPath:indexPath];
            _selectionRect = [self.view convertRect:cell.imageView.frame fromView:cell];
            _openDocumentAnimationShouldFadeIn = YES;
            [self createDocument:collectionView];
        }
    } else {
        ProblemSetProblemInfo *item = [_problemSet.problems objectAtIndex:indexPath.row];
        CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [collectionView cellForItemAtIndexPath:indexPath];
        _selectionRect = [self.view convertRect:cell.imageView.frame fromView:cell];
        _openDocumentAnimationShouldFadeIn = NO;
        [self openProblem:item];
    }
}

- (IBAction)edit:(UIBarButtonItem *)sender {
    [self reloadCircuitListData];
}

- (IBAction)didChangeCircuitsProblemsSegment:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.displayingProblems = YES;
        _createButton.enabled = NO;
        self.title = @"Problems";
        [self.collectionView reloadData];
    } else {
        self.displayingProblems = NO;
        _createButton.enabled = YES;
        self.title = @"Saved Circuits";
        [self.collectionView reloadData];
    }
    _segmentControl = sender;
}

- (void) preload {
    return;
    ViewController *viewcontroller = [[ViewController alloc] init];
    [self.view addSubview:viewcontroller.view];
    [viewcontroller.view removeFromSuperview];
}

- (IBAction) didLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (!_displayingProblems) {
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
                                                  NSFileManager* fileManager = [NSFileManager defaultManager];
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
        long index = itemPath.row - 1;
        DocumentListItem *item = [_circuits objectAtIndex:index];
        [self deleteURL:item.url];
        [indexSet addIndex:index];
    }
    [_circuits removeObjectsAtIndexes:indexSet];
}
- (IBAction)optionsPanel:(UIBarButtonItem *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak CircuitListViewController *weakSelf = self;
    UIAlertAction *aboutAction = [UIAlertAction
                                  actionWithTitle:@"About Circuitry"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action)
                                  {
                                      if (!weakSelf) return;
                                      [weakSelf performSegueWithIdentifier:@"ShowTutorialAgain" sender:weakSelf];
                                  }];
    
    [alertController addAction:aboutAction];
    
    UIAlertAction *boringInfoAction = [UIAlertAction
                                  actionWithTitle:@"Legal & Attributions"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action)
                                  {
                                      if (!weakSelf) return;
                                      [weakSelf performSegueWithIdentifier:@"ShowBoringInfo" sender:weakSelf];
                                  }];
    
    [alertController addAction:boringInfoAction];
    
    [alertController.popoverPresentationController setPermittedArrowDirections:UIPopoverArrowDirectionUp];
    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:alertController];
    [popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

#pragma mark -
#pragma mark UICollectionViewDataSource methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!_displayingProblems) {
        if (indexPath.row == 0) {
            return [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitCreatePrototypeCell" forIndexPath:indexPath];
        }
        
        CircuitCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitListPrototypeCell" forIndexPath:indexPath];
        
        DocumentListItem *item = [_circuits objectAtIndex:indexPath.row - 1];
        
        cell.textLabel.text = item.title;
        if (!cell.textLabel.text.length) {
            cell.textLabel.text = @"Untitled";
        }
        cell.imageView.image = nil;
        return cell;
    } else {
        CircuitCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitListPrototypeCell" forIndexPath:indexPath];
        
        ProblemSetProblemInfo *item = [_problemSet.problems objectAtIndex:indexPath.row];
        
        cell.textLabel.text = item.title;
        cell.imageView.image = [UIImage imageNamed:@"level2"];
        
        return cell;
    }
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _displayingProblems = YES;
    self.transitioningDelegate = self;
    UIImage *img = [UIImage imageNamed:@"tutorial-bg-1.jpg"];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    imgView.alpha = 0.2;
    self.collectionView.backgroundView = imgView;
    self.collectionView.backgroundColor = [UIColor whiteColor];
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
            NSURL *url = controller.document.fileURL;
            NSString *urlPath = url.path;
            
            CircuitCollectionViewCell * cell = nil;
            delegate.originatingRect = [self.view convertRect:cell.imageView.frame fromView:cell];
            
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
    [self reloadProblemListData];
    [self reloadCircuitListData];
    
    if (_segmentControl && _segmentControl.selectedSegmentIndex == 1) {
        self.displayingProblems = NO;
    } else {
        self.displayingProblems = YES;
    }
    // TODO: This only needs to be called when the data is reloaded (on initial launch, it loads automatically, making this call unecessary)
    [self.collectionView reloadData];
}

- (void) reloadProblemListData {
    NSString *directoryPath = [[NSBundle mainBundle] pathForResource:@"Problems" ofType:nil];
    self.problemSet = [[ProblemSet alloc] initWithDirectoryPath:directoryPath];
}

- (void) reloadCircuitListData {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    NSString *directoryPath = delegate.documentsDirectory.path;
    
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
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
