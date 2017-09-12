//
//  PrepareTVC.h
//  Grocery Dude
//
//  Created by Tim Roadley on 9/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTVC.h"
@interface PrepareTVC : CoreDataTVC <UIActionSheetDelegate>
@property (strong, nonatomic) UIActionSheet *clearConfirmActionSheet;
@end
