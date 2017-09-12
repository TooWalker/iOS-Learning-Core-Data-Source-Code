//
//  LoginVC.h
//  Grocery Cloud
//
//  Created by Tim Roadley on 19/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface LoginVC : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIView *activityIndicatorBackground;

- (IBAction)create:(id)sender;
- (IBAction)authenticate:(id)sender;
@end
