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


@interface DocumentListItem : NSObject
@property NSURL *url;
@property NSString *title;
@end
@implementation DocumentListItem
- (id) initWithURL: (NSURL *)url; {
    self = [super init];
    _url = url;
    NSInputStream *stream = [[NSInputStream alloc] initWithURL:[url URLByAppendingPathComponent:@"package.json"]];
    [stream open];
    NSDictionary *package = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:NULL];
    _title = package[@"description"];
    return self;
}
@end

@interface CircuitListViewController () <UIActionSheetDelegate>
@property NSMutableArray *items;
@property ViewController *documentViewController;
@property NSIndexPath *actionSheetIndexPath;

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
    return _items.count + 1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CircuitListHeader" forIndexPath:indexPath];
        
        reusableview = headerView;
    }
    return reusableview;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *docURL = nil;
    if (indexPath.row) {
        DocumentListItem *item = [_items objectAtIndex:indexPath.row - 1];
        docURL = item.url;
    }
    [self performSegueWithIdentifier:@"OpenDocumentFromDocumentsList" sender:docURL];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"OpenDocumentFromDocumentsList"]){
        _documentViewController = (ViewController *)segue.destinationViewController;
        NSURL *docURL = sender;
        if (!docURL) {
            NSString *_id = [MongoID stringWithId:[MongoID id]];
            docURL = [[AppDelegate documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.circuit", _id]];
        }
        _documentViewController.documentURL = docURL;
    }
}
- (IBAction) didLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _actionSheetIndexPath = [self.collectionView indexPathForItemAtPoint: [sender locationInView:self.collectionView]];
        CircuitCollectionViewCell *cell = (CircuitCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:_actionSheetIndexPath];
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:cell.textLabel.text delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Share", nil];
        CGRect rect = [self.view convertRect:cell.imageView.frame fromView:cell];
        [sheet showFromRect:rect inView:self.view animated:YES];
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
    if (indexPath.row == 0) {
        return [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitCreatePrototypeCell" forIndexPath:indexPath];
    }
    
    CircuitCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitListPrototypeCell" forIndexPath:indexPath];
    
    DocumentListItem *item = [_items objectAtIndex:indexPath.row - 1];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)", item.title, indexPath.row];
    return cell;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _items = [NSMutableArray array];
    
    NSString *directoryPath = [AppDelegate.documentsDirectory path];

    NSArray* localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:
                               directoryPath error:nil];
    for (NSString* document in localDocuments) {
        NSURL *url = [NSURL fileURLWithPath:[directoryPath
                                             stringByAppendingPathComponent:document]];
        
        DocumentListItem *item = [[DocumentListItem alloc] initWithURL:url];
        
        [_items addObject:item];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
