//
//  CoreDataTVC.h
//  Grocery Dude
//
//  Created by Tim Roadley on 8/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataHelper.h"
@interface CoreDataTVC : UITableViewController <NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController *frc;
- (void)performFetch;
@end
