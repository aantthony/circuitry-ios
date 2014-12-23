//
//  UIAlertView+MKBlockAdditions.h
//  UIKitCategoryAdditions
//
//  Created by Mugunth on 21/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//  Modified by Anthony Foster on 08/02/14
//

#import <Foundation/Foundation.h>

@interface UIAlertView (Block) <UIAlertViewDelegate> 
+ (UIAlertView*) alertViewWithTitle:(NSString*) title 
                            message:(NSString*) message;

+ (UIAlertView*) alertViewWithTitle:(NSString*) title 
                            message:(NSString*) message
                  cancelButtonTitle:(NSString*) cancelButtonTitle;

+ (UIAlertView*) alertViewWithTitle:(NSString*) title                    
                            message:(NSString*) message 
                  cancelButtonTitle:(NSString*) cancelButtonTitle
                  otherButtonTitles:(NSArray*) otherButtons
                          onDismiss:(void (^)(int buttonIndex)) dismissed                   
                           onCancel:(void (^)()) cancelled;

- (void (^)())cancelBlock;
- (void)setCancelBlock:(void (^)())cancelBlock;


- (void)setDismissBlock:(void (^)(int buttonIndex))dismissBlock;
- (void (^)(NSInteger buttonIndex))dismissBlock;
@end
