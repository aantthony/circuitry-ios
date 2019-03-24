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
#import "ProblemSet.h"
#import "ProblemSetProblemInfo.h"

@interface CircuitObjectListTableViewController () <UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) CircuitDocument *document;

@property (nonatomic) BOOL isProblem;
@property (nonatomic) NSArray *items;
@property (nonatomic) NSArray *results;
@property (nonatomic) ProblemSet *set;
@end

@implementation CircuitObjectListTableViewController

- (void) searchThroughData {
    self.results = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains [search] %@", self.searchBar.text];
    self.results = [[self.items filteredArrayUsingPredicate:predicate] mutableCopy];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchThroughData];
}

- (NSArray *) allItems {
    return [ToolbeltItem all];
}

- (BOOL) hasCompletedProblemNumber:(NSUInteger) problemNumber {
    if (problemNumber == 0) return YES;
    
    if (problemNumber > _set.problems.count) {
        return NO;
    }
    ProblemSetProblemInfo *info = _set.problems[problemNumber - 1];
    return info.isCompleted;
}

- (void) configureItems {
    NSArray *allowedTypes = self.document.circuit.meta[@"toolbelt"];
    if (allowedTypes && [allowedTypes isKindOfClass:[NSArray class]]) {
        self.items = [self.allItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type IN %@", allowedTypes]];
    } else {
        self.items = self.allItems;
    }
    
    [self.items enumerateObjectsUsingBlock:^(ToolbeltItem *item, NSUInteger idx, BOOL *stop) {
        if (self.isProblem) {
            item.isAvailable = YES;
        } else {
            item.isAvailable = [self hasCompletedProblemNumber:item.level];
            if (!item.isAvailable) {
//                NSLog(@"%@ not available until completed level: %lu", item.type, (unsigned long)item.level);
            }
        }
    }];
    
    self.results = self.items;
    [self.tableView reloadData];
}

- (void) setDocument: (CircuitDocument *) document {
    _document = document;
    _isProblem = document.isProblem;
    if (!_isProblem) _set = [ProblemSet mainSet];
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
    
    ToolbeltItem *item;
    
    if (tableView == self.tableView) {
        item = _items[indexPath.row];
    } else {
        item = _results[indexPath.row];
    }
    
    if (!item.isAvailable) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.delegate tableViewController:self didStartCreatingObject:item];
}

@end
