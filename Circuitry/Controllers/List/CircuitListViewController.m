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

#import <MessageUI/MFMailComposeViewController.h>

@interface DocumentListItem : NSObject
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *lastModified;
@property (nonatomic) NSDate *created;
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
    _created      = [properties objectForKey:NSFileCreationDate];

    return self;
}

- (UIImage *) image {
    if (!_image) {
        _image = [UIImage imageWithContentsOfFile:[_url URLByAppendingPathComponent:@"screenshot.png"].path];
    }
    return _image;
}

@end

@interface CircuitListViewController () <UIActionSheetDelegate, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, CircuitDocumentViewControllerDelegate>
@property (nonatomic) NSMutableArray *circuits;
@property (nonatomic) ProblemSet *problemSet;
@property (nonatomic) ViewController *documentViewController;
@property (nonatomic) NSIndexPath *actionSheetIndexPath;
@property (nonatomic) CGRect selectionRect;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *createButton;
@property (nonatomic) BOOL openDocumentAnimationShouldFadeIn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic) Circuit *presentingCircuit;
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
    
    self.presentingCircuit = circuit;
    [doc saveToURL:doc.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        [self performSegueWithIdentifier:@"presentDocument" sender:self];
    }];
}

- (void) openProblem: (ProblemSetProblemInfo *) problemInfo {
    self.presentingCircuit = [[CircuitDocument alloc] initWithFileURL:nil];
    self.presentingCircuit.problemInfo = problemInfo;
    [self.presentinpresentingCircuitgDocument openWithCompletionHandler:^(BOOL success){
        [self performSegueWithIdentifier:@"presentDocument" sender:self];
    }];
}

- (CircuitDocument *) circuitDocumentViewController:(CircuitDocumentViewController *)viewController nextDocumentAfterDocument:(CircuitDocument *)document {
    ProblemSetProblemInfo *info = document.problemInfo;
    ProblemSet *mainSet = [ProblemSet mainSet];
    [mainSet didCompleteProblem:info];
    [self.collectionView reloadData];
    ProblemSetProblemInfo *nextInfo = [mainSet problemAfterProblem:info];
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
//    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
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
    _displayingProblems = displayingProblems;
    if (_displayingProblems) {
        _segmentControl.selectedSegmentIndex = 0;
        _createButton.enabled = NO;
        self.navigationItem.leftBarButtonItem = nil;
        self.title = @"Problems";
        self.backgroundImageView.image = [UIImage imageNamed:@"tutorial-bg-3.jpg"];
        [self.collectionView reloadData];
        self.collectionView.backgroundColor = [UIColor colorWithRed:109/255.0 green:141/255.0 blue:186/255.0 alpha:1.0];
    } else {
        _segmentControl.selectedSegmentIndex = 1;
        _createButton.enabled = YES;
        self.navigationItem.leftBarButtonItem = _createButton;
        self.title = @"Saved Circuits";
        self.backgroundImageView.image = [UIImage imageNamed:@"bgblur"];
        self.collectionView.backgroundColor = [UIColor blackColor];
        [self.collectionView reloadData];
    }
    
//    self.backgroundImageView.image = nil;
    self.backgroundImageView.backgroundColor = self.collectionView.backgroundColor;
    self.backgroundImageView.backgroundColor = [UIColor blackColor];
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
            if (_actionSheetIndexPath == nil) return;
            CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:_actionSheetIndexPath];
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:cell.textLabel.text delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles: nil];
            CGRect rect = [self.view convertRect:cell.imageView.frame fromView:cell];
            [sheet showFromRect:rect inView:self.view animated:YES];
        }
    }
}

#pragma mark -
#pragma mark UIActionSheetDelegate Methods

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 40) {
        if (buttonIndex == 0) {
            [self performSegueWithIdentifier:@"ShowTutorialAgain" sender:actionSheet];
        } else if (buttonIndex == 1) {
            [self showSendFeedback];
        } else if (buttonIndex == 2) {
            [self performSegueWithIdentifier:@"ShowBoringInfo" sender:actionSheet];
        }
        return;
    }
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 40) {
        return;
    }
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

- (NSString *) versionString {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (void) showSendFeedback {
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:[NSString stringWithFormat:@"Circuitry v%@: Feedback", self.versionString]];
    [controller setToRecipients:@[@"feedback@circuitry.io"]];
    
    if (controller) {
        [self presentViewController:controller animated:YES completion:nil];
    }
    
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)optionsPanel:(UIBarButtonItem *)sender {
        
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"About Circuitry", @"Send Feedback", @"Legal & Attributions", nil];
    actionSheet.tag = 40;
    [actionSheet showFromBarButtonItem:sender animated:YES];
    
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
        cell.imageView.image = item.image ?: [UIImage imageNamed:@"blank"];
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
            cell.enabled = YES;
        } else {
            cell.imageView.image = [UIImage imageNamed:@"level-locked"];
            cell.textLabel.text = @"Locked";
            cell.textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
            cell.enabled = NO;
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
        UIImage *img = [UIImage imageNamed:@"tutorial-bg-3.jpg"];
        _backgroundImageView = [[UIImageView alloc] initWithImage:img];
        _backgroundImageView.alpha = 0.7;
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _backgroundImageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.transitioningDelegate = self;
    self.collectionView.backgroundView = self.backgroundImageView;
    
    self.displayingProblems = YES;
    
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
//            ViewController * controller = (ViewController *) fromVC;
//            NSURL *url = controller.document.fileURL;
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
    self.problemSet = [ProblemSet mainSet];
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
        return [obj2.created compare: obj1.created];
    }] mutableCopy];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
