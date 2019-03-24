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
    
    NSDictionary<NSAttributedStringDocumentReadingOptionKey,id> *options = [[NSDictionary alloc] init];
    _textView.attributedText = [[NSAttributedString alloc] initWithData:data options:options documentAttributes:nil error:nil];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
