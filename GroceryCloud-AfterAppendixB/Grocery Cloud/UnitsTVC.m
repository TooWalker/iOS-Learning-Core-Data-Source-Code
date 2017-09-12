//
//  UnitsTVC.m
//  Grocery Cloud
//
//  Created by Tim Roadley on 12/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "UnitsTVC.h"
#import "CoreDataHelper.h"
#import "AppDelegate.h"
#import "Unit.h"
#import "UnitVC.h"
@implementation UnitsTVC
#define debug 0
#pragma mark - DATA
- (void)configureFetch {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    NSFetchRequest *request =
    [NSFetchRequest fetchRequestWithEntityName:@"Unit"];
    request.sortDescriptors = [NSArray arrayWithObjects:
                               [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],nil];
    [request setFetchBatchSize:15];
    self.frc =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:cdh.context
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.frc.delegate = self;
}

#pragma mark - VIEW
- (void)viewDidLoad {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [super viewDidLoad];
    [self configureFetch];
    [self performFetch];
    // Respond to changes in underlying store
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(performFetch)
                                                 name:@"SomethingChanged"
                                               object:nil];
}
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    static NSString *cellIdentifier = @"Unit Cell";
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                    forIndexPath:indexPath];
    Unit *unit = [self.frc objectAtIndexPath:indexPath];
    cell.textLabel.text = unit.name;
    return cell;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Unit *deleteTarget = [self.frc objectAtIndexPath:indexPath];
        [self.frc.managedObjectContext deleteObject:deleteTarget];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    [cdh backgroundSaveContext];
}

#pragma mark - INTERACTION
- (IBAction)done:(id)sender {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SEGUE
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    UnitVC *unitVC = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"Add Object Segue"])
    {
        CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
        Unit *newUnit =
        [NSEntityDescription insertNewObjectForEntityForName:@"Unit"
                                      inManagedObjectContext:cdh.context];
        NSError *error = nil;
        if (![cdh.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:newUnit] error:&error]) {
            NSLog(@"Couldn't obtain a permanent ID for object %@", error);
        }
        unitVC.selectedObjectID = newUnit.objectID;
    }
    else if ([segue.identifier isEqualToString:@"Edit Object Segue"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        unitVC.selectedObjectID = [[self.frc objectAtIndexPath:indexPath] objectID];
    }
    else {
        NSLog(@"Unidentified Segue Attempted!");
    }
}

@end
