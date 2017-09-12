//
//  CoreDataTVC.h
//  Grocery Dude
//
//  Created by Tim Roadley on 8/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataHelper.h"
@interface CoreDataTVC : UITableViewController <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
@property (strong, nonatomic) NSFetchedResultsController *frc;
@property (strong, nonatomic) NSFetchedResultsController *searchFRC;
@property (strong, nonatomic) UISearchDisplayController *searchDC;
- (void)performFetch;
- (NSFetchedResultsController*)frcFromTV:(UITableView*)tableView;
- (UITableView*)TVFromFRC:(NSFetchedResultsController*)frc;
- (void)reloadSearchFRCForPredicate:(NSPredicate*)predicate
                         withEntity:(NSString*)entity
                          inContext:(NSManagedObjectContext*)context
                withSortDescriptors:(NSArray*)sortDescriptors
             withSectionNameKeyPath:(NSString*)sectionNameKeyPath;
- (void)configureSearch;
@end
