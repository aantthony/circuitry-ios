//
//  TutorialViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 9/09/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "TutorialViewController.h"

#import "Analytics.h"

@interface TutorialViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *image1;
@property (weak, nonatomic) IBOutlet UIImageView *image2;
@property (weak, nonatomic) IBOutlet UIImageView *image3;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (nonatomic) BOOL buttonEnabled;
@end

@implementation TutorialViewController

static int pageCount = 3;
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
    [self initScrollView];
    _buttonEnabled = NO;
    _button.alpha = 0.0;
    _button.layer.cornerRadius = 4.0;
    _button.layer.borderColor = [[UIColor whiteColor] CGColor];
    _button.layer.borderWidth = 2.0;
}

- (UIImageView *) imageViewForIndex:(int)index {
    if (index == 0) return _image1;
    if (index == 1) return _image2;
    if (index == 2) return _image3;
    return nil;
}

- (void) configureBackgroundFade {
    CGFloat width = self.view.bounds.size.width;
    CGFloat x = _scrollView.contentOffset.x;
    int page = x / width;
    double offset = fmod(x, width) / width;
    int i;
    for (i = 0; i <= page; i++) {
        [self imageViewForIndex:i].alpha = 1.0;
    }
    [self imageViewForIndex:i].alpha = offset;
    i++;
    for (; i < pageCount; i++) {
        [self imageViewForIndex:i].alpha = 0.0;
    }
    BOOL buttonEnabled = (page >= 2 || (page >=1 && offset > 0.3));
    self.buttonEnabled = buttonEnabled;
}

- (void) setButtonEnabled:(BOOL) buttonEnabled {
    if (_buttonEnabled == buttonEnabled) return;
    _button.enabled = buttonEnabled;
    [UIView animateWithDuration:0.3 animations:^{
        _button.alpha = buttonEnabled ? 1.0 : 0.0;
    }];
    _buttonEnabled = buttonEnabled;
}

- (void) configureSubviewLayouts {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    _image1.frame = CGRectMake(0, 0, width, height);
    _image2.frame = CGRectMake(0, 0, width, height);
    _image3.frame = CGRectMake(0, 0, width, height);
    
    _scrollView.frame = CGRectMake(0, 0, width, height);
    _scrollView.contentSize = CGSizeMake(pageCount * width, height);
    
    for(int i = 0; i < pageCount; i++) {
        UIView *v  = [[_scrollView subviews] objectAtIndex:i];
        v.frame = CGRectMake(i * width, 0, width, height);
    }
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    _pageControl.currentPage = _scrollView.contentOffset.x / self.view.bounds.size.width;
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _pageControl.currentPage = _scrollView.contentOffset.x / self.view.bounds.size.width;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [self configureBackgroundFade];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self configureSubviewLayouts];
}
- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configureSubviewLayouts];
}

- (void) initScrollView {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    _scrollView.contentSize = CGSizeMake(pageCount * width, height);
    
    for(int i = 0; i < pageCount; i++) {
        UIViewController *v1 = [self viewControllerAtIndex:i storyboard:self.storyboard];
        [self addChildViewController:v1];
        v1.view.backgroundColor = [UIColor clearColor];
        v1.view.frame = CGRectMake(i * width, 0, width, height);
        [_scrollView addSubview:v1.view];
        [v1 didMoveToParentViewController:self];
    }
    [self configureBackgroundFade];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (IBAction)continue:(id)sender {
    [[Analytics shared] track:@"Finish splash" properties:@{}];
    [self.delegate tutorialViewController:self didFinishWithResult:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard {
    
    if (index == 0) {
        return [storyboard instantiateViewControllerWithIdentifier:@"Tutorial-Page-1"];
    } else if (index == 1) {
        return [storyboard instantiateViewControllerWithIdentifier:@"Tutorial-Page-2"];
    } else if (index == 2) {
        return [storyboard instantiateViewControllerWithIdentifier:@"Tutorial-Page-3"];
    }
    return nil;
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
