//
//  DropboxTVC.h
//  Grocery Dude
//
//  Created by Tim Roadley on 1/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CoreDataHelper.h"
#import "DropboxHelper.h"

@interface DropboxTVC : UITableViewController <UIAlertViewDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) NSMutableArray *contents;
@property (assign, nonatomic) BOOL loading;
@property (strong, nonatomic) UIActionSheet *options;
@property (strong, nonatomic) UIAlertView *confirmRestore;
@property (strong, nonatomic) NSString *selectedZipFileName;

@end
