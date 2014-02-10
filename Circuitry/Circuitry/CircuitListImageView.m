//
//  CircuitListImageView.m
//  Circuitry
//
//  Created by Anthony Foster on 7/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitListImageView.h"
#import "ViewController.h"
#import "Viewport.h"
#import <GLKit/GLKit.h>

@interface CircuitListImageView() <GLKViewDelegate>
@property EAGLContext *context;
@property ViewController *controller;
@property GLKView *view;
@end
@implementation CircuitListImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

//    // Clear the framebuffer
//    glClearColor(1.0f, 0.0f, 0.1f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [_controller glkView:view drawInRect:CGRectMake(0, 0, 768, 768)];
}
- (void)awakeFromNib {
    
    _context = [ViewController context];
//    
    NSLog(@"frame: %f, %f, %f, %f", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
    int padding = 4;
    int width = 183;
    CGRect frame = CGRectMake(padding, padding, width - padding, width - padding);
    _view = [[GLKView alloc] initWithFrame:frame context:_context];
    
    _view.delegate = self;
    
    // Configure renderbuffers created by the view
    _view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    _view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    _view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    // Enable multisampling
    _view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    _controller = [[ViewController alloc] init];
    _controller.view.frame = CGRectMake(0, 0, 768, 768);
    [_controller setup];
    
//    return;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    self.layer.shadowOpacity = 0.38;
    self.layer.shadowRadius = 3.0;
    self.clipsToBounds = NO;
}
- (void) loadURL:(NSURL *) url {
    [_controller loadURL:url complete:^(NSError *error) {
        [_controller update];
        [self addSubview:_view];
    }];
}
@end
