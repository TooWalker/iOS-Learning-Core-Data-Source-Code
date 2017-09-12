//
//  CoreDataTVC.m
//  Grocery Cloud
//
//  Created by Tim Roadley on 8/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "CoreDataTVC.h"
@implementation CoreDataTVC
#define debug 0

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

#pragma mark - VIEW
- (void)viewDidLoad {
    [super viewDidLoad];
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(performFetch) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
}

#pragma mark - FETCHING
- (void)performFetch {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    } else {
        [self showWait:YES];
    }
    if (self.frc) {
        [self.frc.managedObjectContext performBlock:^{
            
            NSError *error = nil;
            if (![self.frc performFetch:&error]) {
                
                NSLog(@"%@ '%@' %@",self.class, NSStringFromSelector(_cmd), error);
                
                if ([error.domain isEqualToString:@"HTTP"] && error.code == 401) {
                    
                    [self showAlertWithTitle:@"Access Denied"
                                     message:@"Please Create or Enter a Shared List on the More tab"];
                } else {
                    
                    if (error) {
                        [self showAlertWithTitle:@"Fetch Failed"
                                         message:[NSString stringWithFormat:@"%@", error.localizedDescription]];
                    }
                    
                }
            }
            [self.tableView reloadData];
            [self showWait:NO];
        }];
    } else {
        NSLog(@"Failed to perform fetch: The fetched results controller is nil.");
    }
}

#pragma mark - DATASOURCE: UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    return [[[[self frcFromTV:tableView]sections] objectAtIndex:section] numberOfObjects];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    return [[[self frcFromTV:tableView] sections] count];
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    return [[self frcFromTV:tableView] sectionForSectionIndexTitle:title atIndex:index];
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	
    return [[[[self frcFromTV:tableView] sections] objectAtIndex:section] name];
}
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    return [[self frcFromTV:tableView] sectionIndexTitles];
}

#pragma mark - DELEGATE: NSFetchedResultsController
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [[self TVFromFRC:controller] beginUpdates];
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [[self TVFromFRC:controller] endUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self TVFromFRC:controller] insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                                       withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [[self TVFromFRC:controller] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                                       withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [[self TVFromFRC:controller] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                               withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [[self TVFromFRC:controller] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                               withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            if (!newIndexPath) {
                [[self TVFromFRC:controller] reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                                   withRowAnimation:UITableViewRowAnimationNone];
            }
            else {
                [[self TVFromFRC:controller] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                                   withRowAnimation: UITableViewRowAnimationNone];
                [[self TVFromFRC:controller] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                                   withRowAnimation: UITableViewRowAnimationNone];
            }
            break;
            
        case NSFetchedResultsChangeMove:
            [[self TVFromFRC:controller] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                               withRowAnimation:UITableViewRowAnimationAutomatic];
            [[self TVFromFRC:controller] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                               withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

#pragma mark - GENERAL
- (NSFetchedResultsController*)frcFromTV:(UITableView*)tableView {
	// If the given tableView is self.tableview return self.frc, otherwise self.searchFRC
    return (tableView == self.tableView) ? self.frc : self.searchFRC;
}
- (UITableView*)TVFromFRC:(NSFetchedResultsController*)frc {
    // If the given fetched results controller is self.frc return self.tableView, otherwise self.searchDC.searchResultsTableView
    return (frc == self.frc) ? self.tableView : self.searchDC.searchResultsTableView;
}

#pragma mark - DELEGATE: UISearchDisplayController
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.searchFRC.delegate = nil;
    self.searchFRC = nil;
}

#pragma mark - SEARCH
- (void)reloadSearchFRCForPredicate:(NSPredicate*)predicate
                         withEntity:(NSString*)entity
                          inContext:(NSManagedObjectContext*)context
                withSortDescriptors:(NSArray*)sortDescriptors
             withSectionNameKeyPath:(NSString*)sectionNameKeyPath {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
    request.sortDescriptors = sortDescriptors;
    request.predicate = predicate;
    request.fetchBatchSize = 20;
    
    self.searchFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                         managedObjectContext:context
                                                           sectionNameKeyPath:sectionNameKeyPath
                                                                    cacheName:nil];
    self.searchFRC.delegate = self;
    
    [self.searchFRC.managedObjectContext performBlockAndWait:^{
        NSError *error;
        [self.searchFRC performFetch:&error];
        if (error) NSLog(@"%@ '%@' %@ (Reason: %@)",
                         self.class, NSStringFromSelector(_cmd),
                         error.localizedDescription, error.localizedFailureReason);
    }];
}
- (void)configureSearch {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44.0)];
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tableView.tableHeaderView = searchBar;
    
    self.searchDC = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    self.searchDC.delegate = self;
    self.searchDC.searchResultsDataSource = self;
    self.searchDC.searchResultsDelegate = self;
}

@end 
