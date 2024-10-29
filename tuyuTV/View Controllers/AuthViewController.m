//
//  AuthViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 10/31/18.
//  Copyright © 2018 nito. All rights reserved.
//

#import "AuthViewController.h"
#import "TYAuthUserManager.h"
#import "UIColor+Additions.h"

@interface AuthViewController()

@property (nonatomic, strong) UILabel *generalInfoLabel;
@property (nonatomic, strong) UILabel *authCodeLabel;
@property (nonatomic, strong) UILabel *webSiteLabel;
@property (nonatomic, strong) NSDictionary *userCodeDetails;

@end

@implementation AuthViewController

- (id)initWithUserCodeDetails:(NSDictionary *)userCodeDetails {
    
    self = [super init];
    self.userCodeDetails = userCodeDetails;
    [self layoutView];
    return self;
    
}
/*
 verification_url
*/

- (void)layoutView {
    
    self.generalInfoLabel = [[UILabel alloc] initForAutoLayout];
    //self.webSiteLabel = [UIButton buttonWithType:UIButtonTypeSystem];
    //[self.webSiteLabel configureForAutoLayout];
    self.webSiteLabel = [[UILabel alloc] initForAutoLayout];
    self.authCodeLabel = [[UILabel alloc] initForAutoLayout];
    [self.view addSubview:self.generalInfoLabel];
    [self.view addSubview:self.authCodeLabel];
    [self.view addSubview:self.webSiteLabel];
    
    //self.generalInfoLabel.text = @"Please go to the following website and enter the user code below to enable the nitoTV store to use your Amazon account for purchases";
    self.generalInfoLabel.text = @"From a browser on a different device visit the following website and enter the code below to login to YouTube";
#ifdef OLD_SHIT
    self.authCodeLabel.text = self.userCodeDetails[@"user_code"];
    self.webSiteLabel.text = self.userCodeDetails[@"verification_uri"];
#else
    self.authCodeLabel.text = self.userCodeDetails[@"user_code"];
    NSString *authURL = self.userCodeDetails[@"verification_url"];
    //[self.webSiteLabel setTitle:authURL forState:UIControlStateNormal];
    //[self.webSiteLabel setTitle:authURL forState:UIControlStateFocused];
    
    self.webSiteLabel.text = authURL;
#endif
    [self.generalInfoLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.authCodeLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.webSiteLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    [self.generalInfoLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:100];
    [self.webSiteLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.generalInfoLabel withOffset:45];
    [self.authCodeLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.webSiteLabel withOffset:55];
    
    self.generalInfoLabel.numberOfLines = 0;
    [self.generalInfoLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:0.7];
    self.generalInfoLabel.lineBreakMode = NSLineBreakByWordWrapping;
#if TARGET_OS_TV
    self.generalInfoLabel.font = [UIFont systemFontOfSize:52];
    self.authCodeLabel.font = [UIFont boldSystemFontOfSize:180];
    self.webSiteLabel.font = [UIFont systemFontOfSize:48];
#else
    self.generalInfoLabel.font = [UIFont systemFontOfSize:18];
    self.authCodeLabel.font = [UIFont boldSystemFontOfSize:42];
    self.webSiteLabel.font = [UIFont systemFontOfSize:16];
    self.view.backgroundColor = [UIColor blackColor];
#endif
    self.generalInfoLabel.textColor = [UIColor grayColor];
    self.authCodeLabel.textColor = [UIColor colorFromHex:@"FF0000"];
    //self.webSiteLabel.textColor = [UIColor colorFromHex:@"FFBD24"];
    self.webSiteLabel.textColor = [UIColor colorFromHex:@"EAAD06"];
    //[self.webSiteLabel setTitleColor:[UIColor colorFromHex:@"EAAD06"] forState:UIControlStateNormal];
    //[self.webSiteLabel setTitleColor:[UIColor colorFromHex:@"EAAD06"] forState:UIControlStateFocused];
    //[self.webSiteLabel setPrimaryTarget:self action:@selector(bro)];
    
}


@end
