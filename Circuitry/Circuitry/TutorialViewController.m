//
//  TutorialViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 9/09/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController ()
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
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
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;

    UIViewController *startingViewController = [self viewControllerAtIndex:0 storyboard:self.storyboard];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    self.pageViewController.dataSource = self;
    
    [self addChildViewController:self.pageViewController];
    [self.view insertSubview:self.pageViewController.view atIndex:0];
    
    self.pageViewController.view.frame = self.view.bounds;
    
    [self.pageViewController didMoveToParentViewController:self];
    
    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
}
- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void) pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    _pageControl.currentPage = [self indexOfViewController:[pageViewController.viewControllers lastObject]];
}
- (IBAction)continue:(id)sender {
    [self.delegate tutorialViewController:self didFinishWithResult:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSUInteger)indexOfViewController:(UIViewController *)viewController
{   
    // Return the index of the given data view controller.
    // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
    if ([viewController.restorationIdentifier isEqualToString:@"Tutorial-Page-1"]) return 0;
    if ([viewController.restorationIdentifier isEqualToString:@"Tutorial-Page-2"]) return 1;
    if ([viewController.restorationIdentifier isEqualToString:@"Tutorial-Page-3"]) return 2;
    
    return NSNotFound;
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == pageCount) {
        return nil;
    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}
- (NSInteger) presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return pageCount;
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
