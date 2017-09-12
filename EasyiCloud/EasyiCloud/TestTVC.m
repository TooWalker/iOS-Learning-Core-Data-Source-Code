//
//  TestTVC.m
//  EasyiCloud
//
//  Created by Tim Roadley on 23/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "TestTVC.h"
#import "CoreDataHelper.h"
#import "AppDelegate.h"
#import "Deduplicator.h"
#import "Test.h"

@implementation TestTVC

#pragma mark - DATA
- (void)configureFetch {
    
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    NSFetchRequest *request =
    [NSFetchRequest fetchRequestWithEntityName:@"Test"];
    request.sortDescriptors = [NSArray arrayWithObjects:
                               [NSSortDescriptor sortDescriptorWithKey:@"modified" ascending:NO],nil];
    [request setFetchBatchSize:15];
    self.frc =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:cdh.context
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.frc.delegate = self;
}

#pragma mark - VIEW
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    [Deduplicator deDuplicateEntityWithName:@"Test"
                    withUniqueAttributeName:@"someValue"
                          withImportContext:cdh.importContext];
    
}
- (void)viewDidLoad {
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
    
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                    forIndexPath:indexPath];
    Test *test = [self.frc objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"From: %@",test.device];
    cell.detailTextLabel.text = test.someValue;
    return cell;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *deleteTarget = [self.frc objectAtIndexPath:indexPath];
        [self.frc.managedObjectContext deleteObject:deleteTarget];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    [cdh backgroundSaveContext];
}

#pragma mark - INTERACTION
- (IBAction)add:(id)sender {
    
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    Test *object =
    [NSEntityDescription insertNewObjectForEntityForName:@"Test"
                                  inManagedObjectContext:cdh.context];
    NSError *error = nil;
    if (![cdh.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:object] error:&error]) {
        NSLog(@"Couldn't obtain a permanent ID for object %@", error);
    }
    UIDevice *thisDevice = [UIDevice new];
    object.device = thisDevice.name;
    object.modified = [NSDate date];
    object.someValue = [NSString stringWithFormat:@"Test: %@",[[NSUUID UUID] UUIDString]];
    [cdh backgroundSaveContext];
}
@end
