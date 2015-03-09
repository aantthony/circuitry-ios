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
#import "CircuitDocument.h"

@interface CircuitObjectListTableViewController () <UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) CircuitDocument *document;

@property (nonatomic) NSArray *allItems;

@property (nonatomic) NSArray *items;
@property (nonatomic) NSArray *results;
@end

@implementation CircuitObjectListTableViewController


- (void) searchThroughData {
    self.results = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains [search] %@", self.searchBar.text];
    NSLog(@"items: %@", self.items);
    self.results = [[self.items filteredArrayUsingPredicate:predicate] mutableCopy];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchThroughData];
}

- (NSArray *) allItems {
    if (_allItems) return _allItems;
    _allItems = @[
                      [[ToolbeltItem alloc] initWithType:@"button"  image:[UIImage imageNamed:@"switch"]   name:@"Button" subtitle:@"Toggle button"],
                      //                   [[ToolbeltItem alloc] initWithType:@"pbtn"    image:[UIImage imageNamed:@"pushbutton"] name:@"Button" subtitle:@"Push button"],
                      [[ToolbeltItem alloc] initWithType:@"light"   image:[UIImage imageNamed:@"led"]      name:@"Light" subtitle:@"Light Emitting Diode"],
                      [[ToolbeltItem alloc] initWithType:@"or"      image:[UIImage imageNamed:@"or"]       name:@"OR" subtitle:@"2 in, 1 out"],
                      [[ToolbeltItem alloc] initWithType:@"and"     image:[UIImage imageNamed:@"and"]      name:@"AND" subtitle:@"2 in, 1 out"],
                      [[ToolbeltItem alloc] initWithType:@"not"     image:[UIImage imageNamed:@"not"]      name:@"NOT" subtitle:@"1 in, 1 out"],
                      [[ToolbeltItem alloc] initWithType:@"xor"     image:[UIImage imageNamed:@"xor"]      name:@"XOR" subtitle:@"2 in, 1 out"],
                      [[ToolbeltItem alloc] initWithType:@"xnor"    image:[UIImage imageNamed:@"xnor"]     name:@"XNOR" subtitle:@"2 in, 1 out"],
                      [[ToolbeltItem alloc] initWithType:@"nand"    image:[UIImage imageNamed:@"nand"]     name:@"NAND" subtitle:@"2 in, 1 out"],
                      [[ToolbeltItem alloc] initWithType:@"nor"     image:[UIImage imageNamed:@"nor"]      name:@"NOR" subtitle:@"2 in, 1 out"],
                      [[ToolbeltItem alloc] initWithType:@"ha"      image:[UIImage imageNamed:@"ha"]     name:@"Half adder" subtitle:@"2 in, 2 out"],
                      [[ToolbeltItem alloc] initWithType:@"fa"      image:[UIImage imageNamed:@"fa"]     name:@"Full adder" subtitle:@"3 in, 2 out"],
                      [[ToolbeltItem alloc] initWithType:@"add4"    image:[UIImage imageNamed:@"add4"]     name:@"4-bit adder" subtitle:@"8 in, 4 out"],
                      [[ToolbeltItem alloc] initWithType:@"mult4"   image:[UIImage imageNamed:@"mult4"]    name:@"4-bit multiplier" subtitle:@"8 in, 4 out"],
                      [[ToolbeltItem alloc] initWithType:@"add8"    image:[UIImage imageNamed:@"add8"]     name:@"8-bit adder" subtitle:@"16 in, 8 out"],
                      [[ToolbeltItem alloc] initWithType:@"mult8"   image:[UIImage imageNamed:@"mult8"]    name:@"8-bit multiplier" subtitle:@"16 in, 8 out"],
                      [[ToolbeltItem alloc] initWithType:@"bin7seg" image:[UIImage imageNamed:@"bin7seg"]  name:@"7seg Decoder" subtitle:@"4 bit input, 7 display"],
                      [[ToolbeltItem alloc] initWithType:@"7seg"    image:[UIImage imageNamed:@"7seg"]     name:@"7-Segment Display" subtitle:@"Display"],
                      [[ToolbeltItem alloc] initWithType:@"clock"   image:[UIImage imageNamed:@"clock"]    name:@"Clock" subtitle:@"Square wave"]
                      ];
    return _allItems;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    [self configureItems];
}

- (void) configureItems {
    NSArray *allowedTypes = self.document.circuit.meta[@"toolbelt"];
    if (allowedTypes && [allowedTypes isKindOfClass:[NSArray class]]) {
        self.items = [self.allItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type IN %@", allowedTypes]];
    } else {
        self.items = self.allItems;
    }
    self.results = self.items;
}

- (void) setDocument: (CircuitDocument *) document {
    _document = document;
    [self configureItems];
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
    ToolbeltItem *item;
    
    if (tableView == self.tableView) {
        item = _items[indexPath.row];
    } else {
        item = _results[indexPath.row];
    }
    
    [self.delegate tableViewController:self didStartCreatingObject:item];
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
