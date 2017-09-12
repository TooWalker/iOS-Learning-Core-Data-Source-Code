//
//  ShopTVC.m
//  Grocery Dude
//
//  Created by Tim Roadley on 9/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "ShopTVC.h"
#import "CoreDataHelper.h"
#import "Item.h"
#import "Unit.h"
#import "AppDelegate.h"
#import "ItemVC.h"

@implementation ShopTVC
#define debug 0

#pragma mark - DATA
- (void)configureFetch {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    NSFetchRequest *request =
    [[cdh.model fetchRequestTemplateForName:@"ShoppingList"] copy];
    
    request.sortDescriptors =
    [NSArray arrayWithObjects:
     [NSSortDescriptor sortDescriptorWithKey:@"locationAtShop.aisle"
                                   ascending:YES],
     [NSSortDescriptor sortDescriptorWithKey:@"name"
                                   ascending:YES],
     nil];
    [request setFetchBatchSize:50];
    
    self.frc =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:cdh.context
                                          sectionNameKeyPath:@"locationAtShop.aisle"
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
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    static NSString *cellIdentifier = @"Shop Cell";
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                    forIndexPath:indexPath];
    
    Item *item = [self.frc objectAtIndexPath:indexPath];
    NSMutableString *title = [NSMutableString stringWithFormat:@"%@%@ %@",
                              item.quantity, item.unit.name, item.name];
    [title replaceOccurrencesOfString:@"(null)"
                           withString:@""
                              options:0
                                range:NSMakeRange(0, [title length])];
    cell.textLabel.text = title;
    
    // make collected items gray
    if (item.collected.boolValue) {
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:16]];
        [cell.textLabel setTextColor:[UIColor grayColor]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:18]];
        cell.textLabel.textColor = [UIColor orangeColor];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    return cell;
}
- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    return nil; // prevent section index.
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    Item *item = [self.frc objectAtIndexPath:indexPath];
    if (item.collected.boolValue) {
        item.collected = [NSNumber numberWithBool:NO];
    }
    else {
        item.collected = [NSNumber numberWithBool:YES];
    }
}

#pragma mark - INTERACTION
- (IBAction)clear:(id)sender {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([self.frc.fetchedObjects count] == 0) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nothing to Clear"
                                                        message:@"Add items using the Prepare tab"
                                                       delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        return;
    }
    BOOL nothingCleared = YES;
    for (Item *item in self.frc.fetchedObjects) {
        
        if (item.collected.boolValue)
        {
            item.listed = [NSNumber numberWithBool:NO];
            item.collected = [NSNumber numberWithBool:NO];
            nothingCleared = NO;
        }
    }
    if (nothingCleared) {
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:nil
                                   message:@"Select items to be removed from the list before pressing Clear"
                                  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - SEGUE
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    ItemVC *itemVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ItemVC"];
    itemVC.selectedItemID = [[self.frc objectAtIndexPath:indexPath] objectID];
    [self.navigationController pushViewController:itemVC animated:YES];
}
@end
