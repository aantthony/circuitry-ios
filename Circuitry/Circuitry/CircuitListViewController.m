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


@interface DocumentListItem : NSObject
@property NSURL *url;
@end
@implementation DocumentListItem
@end

@interface CircuitListViewController ()
@property NSMutableArray *items;
@property ViewController *documentViewController;
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitCreatePrototypeCell" forIndexPath:indexPath];
    }
    
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CircuitListPrototypeCell" forIndexPath:indexPath];
    
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
        DocumentListItem *item = [[DocumentListItem alloc] init];
        
        item.url = [NSURL fileURLWithPath:[directoryPath
                                             stringByAppendingPathComponent:document]];
        
        [_items addObject:item];
    }
    
//    [self.collectionView reloadData];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
