//
//  TutorialViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 24/06/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIImageView *bg3;
@property (nonatomic) BOOL isScrollingToPage;
@end

@implementation TutorialViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _isScrollingToPage = NO;
    
}


- (void) setCurrentPage:(int)currentPage {
    NSString *nextNumberLabel;
    NSString *nextInstructionLabel;
    [UIView animateWithDuration:0.2 animations:^{
        _bg3.alpha = currentPage > 1;
    }];
}
- (IBAction)changePage:(id)sender {
    _isScrollingToPage = YES;
    CGRect pageRect = CGRectMake(_pageControl.currentPage * _scrollView.frame.size.width, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
    [_scrollView scrollRectToVisible:pageRect animated:YES];
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    _isScrollingToPage = NO;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offset = _scrollView.contentOffset.x;
    CGFloat pageSize = _scrollView.frame.size.width;
    int page = floor((offset + pageSize / 2) / pageSize);
    
    if (!_isScrollingToPage) {
        _pageControl.currentPage = page;
    }
    self.currentPage = page;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame) * 3.0, CGRectGetHeight(self.view.frame));
    [_scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
