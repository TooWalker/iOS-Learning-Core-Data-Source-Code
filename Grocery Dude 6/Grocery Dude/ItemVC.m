//
//  ItemVC.m
//  Grocery Dude
//
//  Created by Tim Roadley on 12/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "ItemVC.h"
#import "AppDelegate.h" 
#import "Item.h"
#import "LocationAtHome.h" 
#import "LocationAtShop.h"

@implementation ItemVC
#define debug 1

#pragma mark - INTERACTION
- (IBAction)done:(id)sender {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self hideKeyboard];
    [self.navigationController popViewControllerAnimated:YES];
}
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
    [self.view endEditing:YES];
}

#pragma mark - DELEGATE: UITextField
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    if (textField == self.nameTextField) {
        
        if ([self.nameTextField.text isEqualToString:@"New Item"]) {
            self.nameTextField.text = @"";
        }
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    Item *item = (Item*)[cdh.context existingObjectWithID:self.selectedItemID error:nil];
    
    if (textField == self.nameTextField) {
        if ([self.nameTextField.text isEqualToString:@""]) {
            self.nameTextField.text = @"New Item";
        }
        item.name = self.nameTextField.text;
    }
    else if (textField == self.quantityTextField) {
        item.quantity = [NSNumber numberWithFloat:self.quantityTextField.text.floatValue];
    }
}

#pragma mark - VIEW
- (void)refreshInterface {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    if (self.selectedItemID) {
        CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
        Item *item = (Item*)[cdh.context existingObjectWithID:self.selectedItemID error:nil];
        self.nameTextField.text = item.name;
        self.quantityTextField.text = item.quantity.stringValue;
    }
}
- (void)viewDidLoad {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [super viewDidLoad];
    [self hideKeyboardWhenBackgroundIsTapped];
    self.nameTextField.delegate = self;
    self.quantityTextField.delegate = self;
}
- (void)viewWillAppear:(BOOL)animated {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self ensureItemHomeLocationIsNotNull];
    [self ensureItemShopLocationIsNotNull];
    [self refreshInterface];
    if ([self.nameTextField.text isEqual:@"New Item"]) {
        self.nameTextField.text = @"";
        [self.nameTextField becomeFirstResponder];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self ensureItemHomeLocationIsNotNull];
    [self ensureItemShopLocationIsNotNull];
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    [cdh saveContext];
}

#pragma mark - DATA
- (void)ensureItemHomeLocationIsNotNull {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    if (self.selectedItemID) {
        CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
        Item *item = (Item*)[cdh.context existingObjectWithID:self.selectedItemID error:nil];
        
        if (!item.locationAtHome) {
            NSFetchRequest *request =
            [[cdh model] fetchRequestTemplateForName:@"UnknownLocationAtHome"];
            NSArray *fetchedObjects =
            [cdh.context executeFetchRequest:request error:nil];
            
            if ([fetchedObjects count] > 0) {
                item.locationAtHome = [fetchedObjects objectAtIndex:0];
            }
            else {
                LocationAtHome *locationAtHome =
                [NSEntityDescription insertNewObjectForEntityForName:@"LocationAtHome"
                                              inManagedObjectContext:cdh.context];
                NSError *error = nil;
                if (![cdh.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:locationAtHome] error:&error]) {
                    NSLog(@"Couldn't obtain a permanent ID for object %@", error);
                }
                locationAtHome.storedIn = @"..Unknown Location..";
                item.locationAtHome = locationAtHome;
            }
        }
    }
}
- (void)ensureItemShopLocationIsNotNull {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    if (self.selectedItemID) {
        CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
        Item *item = (Item*)[cdh.context existingObjectWithID:self.selectedItemID error:nil];
        
        if (!item.locationAtShop) {
            NSFetchRequest *request =
            [[cdh model] fetchRequestTemplateForName:@"UnknownLocationAtShop"];
            NSArray *fetchedObjects =
            [cdh.context executeFetchRequest:request error:nil];
            
            if ([fetchedObjects count] > 0) {
                item.locationAtShop = [fetchedObjects objectAtIndex:0];
            }
            else {
                LocationAtShop *locationAtShop =
                [NSEntityDescription insertNewObjectForEntityForName:@"LocationAtShop"
                                              inManagedObjectContext:cdh.context];
                NSError *error = nil;
                if (![cdh.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:locationAtShop] error:&error]) {
                    NSLog(@"Couldn't obtain a permanent ID for object %@", error);
                }
                locationAtShop.aisle = @"..Unknown Location..";
                item.locationAtShop = locationAtShop;
            }
        }
    }
}

@end
