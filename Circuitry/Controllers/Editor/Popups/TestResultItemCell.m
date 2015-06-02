//
//  TestResultItemCell.m
//  Circuitry
//
//  Created by Anthony Foster on 18/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

#import "TestResultItemCell.h"
#import "StyleManager.h"
#import "CircuitTestResult.h"

@interface TestResultItemCell()
@property (weak, nonatomic) IBOutlet UIImageView *resultMarkView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightSpacing;
@property (nonatomic) NSMutableArray *columnLabels;
@end


@implementation TestResultItemCell

+ (UIColor *) redBackgroundColor {
    return [StyleManager rgb:0x0FF8383];
}

- (void) setShowResult:(BOOL) showResult animated:(BOOL) animated {
    if (!animated) {
        self.rightSpacing.constant = showResult ? 24 : - 50;
        [self layoutIfNeeded];
        
        self.resultMarkView.alpha = showResult ? 1.0 : 0.5;
        BOOL showRedBackground = !_check.isMatch && showResult;
        self.backgroundColor = showRedBackground ? [TestResultItemCell redBackgroundColor] : [UIColor whiteColor];
        return;
    } else {
        [self setShowResult:showResult animated:NO];
    }
}

- (void) floodLabel:(UILabel *)label withRightSpace:(CGFloat) right {
    CGRect o = label.frame;
    CGFloat viewWidth = 540;
    CGFloat left = CGRectGetMinX(o);
    label.frame = CGRectMake(left, CGRectGetMinY(o), viewWidth - left - right, CGRectGetHeight(o));
}

- (void) setCheck:(CircuitTestResultCheck *)check {
    if (_check == check) return;
    _check = check;
    NSUInteger column = 0;
    for(NSNumber *input in _check.inputs) {
        UILabel *label = [self labelAtColumn:column++];
        label.text = input.boolValue ? @"1" : @"0";
    }
    UILabel *expectedLabel = [self labelAtColumn:column++];
    expectedLabel.text = [check.expectedOutputs componentsJoinedByString:@", "];
    [self floodLabel:expectedLabel withRightSpace:100];
//    expectedLabel.text = @"T";
    BOOL correct = check.isMatch;
    self.resultMarkView.image = [UIImage imageNamed:correct ? @"TestResultMatch" : @"TestResultMismatch"];
    self.backgroundColor = correct ? [UIColor whiteColor] : self.class.redBackgroundColor;
}

- (void) setResult:(CircuitTestResult *)result {
    _result = result;
    [self configureHeader];
}

- (void) configureHeader {
    self.resultMarkView.hidden = YES;
    NSUInteger column = 0;
    UIFont *font = [UIFont boldSystemFontOfSize:17];
    for(NSString *name in _result.inputNames) {
        UILabel *label = [self labelAtColumn:column++];
        label.font = font;
        label.text = name;
    }
    UILabel *expected = [self labelAtColumn:column++];
    [self floodLabel:expected withRightSpace:100];
    expected.font = font;
    if (self.result.outputNames.count && ![self.result.outputNames[0] isEqualToString:@"-"]) {
        expected.text = [NSString stringWithFormat:@"Expected (%@)", [self.result.outputNames componentsJoinedByString:@", "]];
    } else {
        expected.text = @"Expected";
    }
}

static CGFloat const leftMargin = 20;
static CGFloat const columnWidth = 30;

- (UILabel *) labelAtColumn:(NSUInteger) index {
    if (_columnLabels == nil) {
        _columnLabels = [NSMutableArray array];
    }
    if (index < _columnLabels.count) {
        return _columnLabels[index];
    }
    CGRect rect = CGRectMake(leftMargin + index * columnWidth, 0, columnWidth, 50);
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    [self.contentView addSubview:label];
    [_columnLabels insertObject:label atIndex:index];
    return label;
}
@end

