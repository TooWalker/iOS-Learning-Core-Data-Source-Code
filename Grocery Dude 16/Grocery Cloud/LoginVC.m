//
//  LoginVC.m
//  Grocery Cloud
//
//  Created by Tim Roadley on 19/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "LoginVC.h"
#import "CoreDataHelper.h"
#import "AppDelegate.h"
#import "User.h"

@implementation LoginVC
#define debug 1

#pragma mark - ACCOUNT
- (IBAction)create:(id)sender {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    NSManagedObjectContext *stackMobContext = [cdh.stackMobStore contextForCurrentThread];
    
    [self showWait:YES];
    if ([self textFieldIsBlank]) {
        return;
    }
    
    // ENSURE NETWORK IS REACHABLE
    if (!cdh.stackMobClient.networkMonitor.currentNetworkStatus == SMNetworkStatusReachable) {
        
        [self showAlertWithTitle:@"Failed to Create Shared List"
                         message:@"The Internet connection appears to be offline."];
        [self updateStatus];
        return;
    }
    
    // ENSURE USER DOESN'T EXIST
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"username==%@", self.usernameTextField.text]];
    
    [stackMobContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
        
        if (results.count > 0) {
            // USER ALREADY EXISTS
            [self showAlertWithTitle:@"Please choose another Shared List Name"
                             message:[NSString stringWithFormat:@"Someone has already created a list with the name '%@'",_usernameTextField.text]];
        } else {
            
            // CREATE USER
            self.statusLabel.text = [NSString stringWithFormat:@"Creating Shared List '%@'...", _usernameTextField.text];
            User *newUser = [[User alloc] initIntoManagedObjectContext:stackMobContext];
            [newUser setValue:_usernameTextField.text forKey:[newUser primaryKeyField]];
            [newUser setPassword:_passwordTextField.text];
            
            [stackMobContext saveOnSuccess:^{
                
                // USER CREATED SUCCESSFULLY
                [self updateStatus];
                [self showWait:NO];
                [self authenticate:self];
                
            } onFailure:^(NSError *error) {
                
                // USER CREATION FAILED
                [stackMobContext deleteObject:newUser];
                [newUser removePassword];
                [self updateStatus];
                [self showWait:NO];
                [self showAlertWithTitle:@"Failed to Create Shared List"
                                 message:[NSString stringWithFormat:@"%@",error]];
            }];
        }
    } onFailure:^(NSError *error) {
        
        // UNSURE IF USER EXISTS
        [self showAlertWithTitle:@"Failed to Check if Shared List Exists"
                         message:[NSString stringWithFormat:@"%@",error]];
    }];
}
- (IBAction)authenticate:(id)sender {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([self textFieldIsBlank]) {
        return;
    }
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    
    self.statusLabel.text = [NSString stringWithFormat:@"Connecting to Shared List '%@'...",_usernameTextField.text];
    
    [self showWait:YES];
    
    [[cdh.stackMobStore contextForCurrentThread] saveOnSuccess:^{ // ensure new objects are saved prior to an account switch
        
        [cdh.stackMobClient loginWithUsername:_usernameTextField.text password:_passwordTextField.text onSuccess:^(NSDictionary *results) {
            
            [self showAlertWithTitle:@"Success!"
                             message:[NSString stringWithFormat:@"You're now using Shared List '%@'", [results valueForKey:@"username"]]];
            [self updateStatus];
            [self showWait:NO];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged"
                                                                object:nil
                                                              userInfo:nil];
        } onFailure:^(NSError *error) {
            
            if (error.code == 401) {
                [self showAlertWithTitle:@"Failed to Enter Shared List"
                                 message:@"Access Denied"];
            } else {
                [self showAlertWithTitle:@"Failed to Enter Shared List"
                                 message:[NSString stringWithFormat:@"%@",error.localizedDescription]];
            }
            [self updateStatus];
            [self showWait:NO];
        }];
    } onFailure:^(NSError *error) {
        NSLog(@"Failed to save context prior to account switch");
    }];
}

#pragma mark - VIEW
- (void)updateStatus {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    
    if([cdh.stackMobClient isLoggedIn]) {
        
        [cdh.stackMobClient getLoggedInUserOnSuccess:^(NSDictionary *result) {
            self.statusLabel.text = [NSString stringWithFormat:@"You're using '%@'", [result objectForKey:@"username"]];
        } onFailure:^(NSError *error) {
            self.statusLabel.text = @"Create or Enter a Shared List";
        }];
        
    } else {
        self.statusLabel.text = @"Create or Enter a Shared List";
    }
}
- (void)viewDidLoad {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [super viewDidLoad];
    [_usernameTextField setDelegate:self];
    [_passwordTextField setDelegate:self];
    [self hideKeyboardWhenBackgroundIsTapped];
    [self updateStatus];
}

#pragma mark - WAITING
- (void)showWait:(BOOL)visible {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (!_activityIndicatorBackground) {
        _activityIndicatorBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        
    }
    [_activityIndicatorBackground setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2)];
    [_activityIndicatorBackground setBackgroundColor:[UIColor blackColor]];
    [_activityIndicatorBackground setAlpha:0.5];
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activityIndicatorView.center = CGPointMake(_activityIndicatorBackground.frame.size.width/2, _activityIndicatorBackground.frame.size.height/2);
    
    if (visible) {
        [self.view addSubview:_activityIndicatorBackground];
        [_activityIndicatorBackground addSubview:_activityIndicatorView];
        [_activityIndicatorView startAnimating];
        
    } else {
        [_activityIndicatorView stopAnimating];
        [_activityIndicatorView removeFromSuperview];
        [_activityIndicatorBackground removeFromSuperview];
    }
}

#pragma mark - ALERTING
- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    [alert show];
    [self showWait:NO];
}

#pragma mark - VALIDATION
- (BOOL)textFieldIsBlank {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([_usernameTextField.text isEqualToString:@""] ||
        [_passwordTextField.text isEqualToString:@""]) {
        
        [self showAlertWithTitle:@"Please Enter a Shared List Name and Password"
                         message:@"If you don't have a Shared List you can create one by filling in a Shared List Name and a Password, then clicking Create"];
        return YES;
    }
    return NO;
}

#pragma mark - DELEGATE: UITextField
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - INTERACTION
- (void)hideKeyboardWhenBackgroundIsTapped {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    UITapGestureRecognizer *tgr =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(hideKeyboard)];
    [tgr setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tgr];
}
- (void)hideKeyboard {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self.view endEditing:TRUE];
}
@end
