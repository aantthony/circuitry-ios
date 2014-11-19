//
//  BoringInfoViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 19/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "BoringInfoViewController.h"

@interface BoringInfoViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation BoringInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSData *data = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Terms" withExtension:@"rtf"]];
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithData:data options:nil documentAttributes:nil error:nil];
    
    _textView.attributedText = attrString;
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
