//
//  CircuitObjectListTableViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 6/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitObjectListTableViewController.h"
#import "ToolbeltItem.h"
#import "ToolbeltItemTableViewCell.h"

@interface CircuitObjectListTableViewController () <UISearchBarDelegate> {
    CircuitDocument *_document;
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic) NSArray *items;
@property (nonatomic) NSArray *results;
@end

@implementation CircuitObjectListTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) searchThroughData {
    self.results = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains [search] %@", self.searchBar.text];
    NSLog(@"items: %@", self.items);
    self.results = [[self.items filteredArrayUsingPredicate:predicate] mutableCopy];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchThroughData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    ToolbeltItem *item = [ToolbeltItem new];
    item.name = @"OR";
    item.type = @"or";
    item.subtitle = @"2 in, 1 out";
    item.image = [UIImage imageNamed:@"or.png"];
    
    ToolbeltItem *item2 = [ToolbeltItem new];
    item2.name = @"AND";
    item.type = @"or";
    item2.subtitle = @"2 in, 1 out";
    item2.image = [UIImage imageNamed:@"and.png"];
    
    ToolbeltItem *item3 = [ToolbeltItem new];
    item3.name = @"NOT";
    item3.type = @"not";
    item3.subtitle = @"1 in, 1 out";
    item3.image = [UIImage imageNamed:@"not.png"];
    
    ToolbeltItem *item4 = [ToolbeltItem new];
    item4.name = @"XOR";
    item4.type = @"xor";
    item4.subtitle = @"2 in, 1 out";
    item4.image = [UIImage imageNamed:@"xor.png"];
    
    ToolbeltItem *item5 = [ToolbeltItem new];
    item5.name = @"XNOR";
    item5.type = @"xnor";
    item5.subtitle = @"1 in, 1 out";
    item5.image = [UIImage imageNamed:@"xnor.png"];
    
    ToolbeltItem *item6 = [ToolbeltItem new];
    item6.name = @"NAND";
    item6.type = @"nand";
    item6.subtitle = @"2 in, 1 out";
    item6.image = [UIImage imageNamed:@"nand.png"];
    
    ToolbeltItem *item7 = [ToolbeltItem new];
    item7.name = @"NOR";
    item7.type = @"nor";
    item7.subtitle = @"2 in, 1 out";
    item7.image = [UIImage imageNamed:@"nor.png"];

    self.items = @[item, item2, item3, item4, item5, item6, item7];
    self.results = self.items;
}

- (void) setDocument: (CircuitDocument *) document {
    _document = document;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return _items.count;
    } else {
        [self searchThroughData];
        return _results.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CircuitObjectItemIdentifier";
    ToolbeltItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

    if (!cell) {
        cell = (ToolbeltItemTableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    
    if (tableView == self.tableView) {
        [cell configureForToolbeltItem: _items[indexPath.row]];
    } else {
        [cell configureForToolbeltItem: _results[indexPath.row]];
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
