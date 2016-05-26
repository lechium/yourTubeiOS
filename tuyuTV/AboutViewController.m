//
//  InstallViewController.m
//  nitoTV4
//
//  Created by Kevin Bradley on 3/15/16.
//  Copyright © 2016 nito. All rights reserved.
//

#import "AboutViewController.h"


@implementation AboutViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(100, 200, self.view.bounds.size.width-200, self.view.bounds.size.height-200)];
    self.view.backgroundColor = [UIColor blackColor];
    self.textView.textColor = [UIColor whiteColor];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.editable = false;
    self.textView.userInteractionEnabled = true;
    self.textView.panGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    self.textView.layoutManager.allowsNonContiguousLayout = NO;
    [self.view addSubview:self.textView];
    NSString *aboutText = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    self.textView.text = aboutText;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:true];
    
    
    
}




@end
