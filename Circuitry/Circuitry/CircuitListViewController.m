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
@property (nonatomic) UIImage *image;

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

    return self;
}

- (UIImage *) image {
    if (!_image) {
        _image = [UIImage imageWithContentsOfFile:[_url URLByAppendingPathComponent:@"screenshot.png"].path];
    }
    return _image;
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
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) BOOL canHandleRoundedViews;
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
    // Give our new document a name:
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    static NSString *kLastBlankName = @"LastBlankName";
    
    NSInteger lastBlankNameIndex = [defaults integerForKey:kLastBlankName];
    lastBlankNameIndex++;
    doc.circuit.title = [NSString stringWithFormat:@"Blank %li", (long)lastBlankNameIndex];
    [defaults setInteger:lastBlankNameIndex forKey:kLastBlankName];
    
    self.presentingDocument = doc;
    [doc saveToURL:doc.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
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
    
    [next openWithCompletionHandler:nil];
    
    return next;
}

- (void) circuitDocumentViewController:(CircuitDocumentViewController *)viewController didFinish:(CircuitDocument *)sender {
    CircuitDocument *doc = viewController.document;
    self.presentingDocument = doc;
    NSLog(@"Unsaved changes: %@", doc.hasUnsavedChanges ? @"YES" : @"NO");
    
    
    if (doc.hasUnsavedChanges) {
        [doc useScreenshot: viewController.snapshot];
    }
    
    [doc closeWithCompletionHandler:^(BOOL success) {
        [self reloadCircuitListData];
        [self.collectionView reloadData];
    }];
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
        if (!item.isAccessible) {
            return;
        }
        _selectionRect = [self.view convertRect:cell.imageView.frame fromView:cell];
        _openDocumentAnimationShouldFadeIn = NO;
        [self openProblem:item];
    }
}

- (void) setDisplayingProblems:(BOOL)displayingProblems {
    if (_displayingProblems == displayingProblems) return;
    _displayingProblems = displayingProblems;
    if (_displayingProblems) {
        _segmentControl.selectedSegmentIndex = 0;
        self.displayingProblems = YES;
        _createButton.enabled = NO;
        self.title = @"Problems";
        self.backgroundImageView.image = [UIImage imageNamed:@"bg-blur.jpg"];
        [self.collectionView reloadData];
    } else {
        _segmentControl.selectedSegmentIndex = 1;
        self.displayingProblems = NO;
        _createButton.enabled = YES;
        self.title = @"Saved Circuits";
        self.backgroundImageView.image = [UIImage imageNamed:@"tutorial-bg-3.jpg"];
        [self.collectionView reloadData];
    }
}

- (IBAction)didChangeCircuitsProblemsSegment:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.displayingProblems = YES;
    } else {
        self.displayingProblems = NO;
    }
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
        cell.rounded = NO;
        cell.imageView.image = item.image;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.tickView.hidden = YES;
        return cell;
    } else {
        CircuitCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitListPrototypeCell" forIndexPath:indexPath];
        
        ProblemSetProblemInfo *item = [_problemSet.problems objectAtIndex:indexPath.row];
        cell.rounded = _canHandleRoundedViews;
        if (item.isAccessible) {
            cell.textLabel.text = item.title;
            cell.imageView.image = [UIImage imageNamed:item.imageName];
            cell.textLabel.textColor = [UIColor whiteColor];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"level-locked"];
            cell.textLabel.text = @"Locked";
            cell.textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        }
        cell.tickView.hidden = !item.isCompleted;
        
        return cell;
    }
    
}

- (BOOL) collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_displayingProblems) {
        ProblemSetProblemInfo *item = _problemSet.problems[indexPath.row];
        if (!item.isAccessible) return NO;
    }
    return YES;
}
- (IBAction)didSwipe:(UISwipeGestureRecognizer *)sender {
    // Disabled, as it is a bit confusing. It would need animation, which means not using a UICollectionViewControler...
    return;
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft && self.displayingProblems) {
        self.displayingProblems = NO;
    } else if (sender.direction == UISwipeGestureRecognizerDirectionRight && !self.displayingProblems) {
        self.displayingProblems = YES;
    }
}

- (UIImageView *) backgroundImageView {
    if (!_backgroundImageView) {
        UIImage *img = [UIImage imageNamed:@"bg-blur.jpg"];
        _backgroundImageView = [[UIImageView alloc] initWithImage:img];
        _backgroundImageView.alpha = 0.7;
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _backgroundImageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _displayingProblems = YES;
    self.transitioningDelegate = self;
    self.collectionView.backgroundView = self.backgroundImageView;
    self.collectionView.backgroundColor = [UIColor blackColor];
    
    _canHandleRoundedViews = YES;
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
//            NSString *urlPath = url.path;
            
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
    NSURL *documentsDirectory = delegate.documentsDirectory;
    NSArray *localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsDirectory includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    
    
    
    NSMutableArray *items = [NSMutableArray array];
    
    for (NSURL* fileURL in localDocuments) {
        DocumentListItem *item = [[DocumentListItem alloc] initWithURL:fileURL];
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
