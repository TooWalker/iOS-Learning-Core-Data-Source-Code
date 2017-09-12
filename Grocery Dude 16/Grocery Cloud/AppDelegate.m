//
//  AppDelegate.m
//  Grocery Cloud
//
//  Created by Tim Roadley on 28/06/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "AppDelegate.h"
#import "Item.h"
#import "Unit.h"
#import "LocationAtHome.h"
#import "LocationAtShop.h"
#import "Item_Photo.h"

@implementation AppDelegate
#define debug 1

- (void)showUnitAndItemCount {
    // List how many items there are in the database
    NSFetchRequest *items =
    [NSFetchRequest fetchRequestWithEntityName:@"Item"];
    NSError *itemsError = nil;
    NSArray *fetchedItems =
    [[[self cdh] context] executeFetchRequest:items error:&itemsError];
    if (!fetchedItems) {NSLog(@"%@", itemsError);}
    else {NSLog(@"Found %i item(s) ",fetchedItems.count);}
    
    // List how many units there are in the database
    NSFetchRequest *units =
    [NSFetchRequest fetchRequestWithEntityName:@"Unit"];
    NSError *unitsError = nil;
    NSArray *fetchedUnits =
    [[[self cdh] context] executeFetchRequest:units error:&unitsError];
    if (!fetchedUnits) {NSLog(@"%@", unitsError);}
    else {NSLog(@"Found %i unit(s) ",fetchedUnits.count);}
}
- (void)demo {

}
- (CoreDataHelper*)cdh {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    if (!_coreDataHelper) {
        static dispatch_once_t predicate;
        dispatch_once(&predicate, ^{
            _coreDataHelper = [CoreDataHelper new];
        });
        [_coreDataHelper setupCoreData];
    }
    return _coreDataHelper;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    // Override point for customization after application launch.
    
    //Bread[self generateStackMobSchema];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[self cdh] saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [self cdh];
    [self demo];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[self cdh] saveContext];
}

- (void)generateStackMobSchema {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    CoreDataHelper *cdh = [self cdh];
    NSManagedObjectContext *stackMobContext = [cdh.stackMobStore contextForCurrentThread];
    
    // Create new objects for each entity
    LocationAtHome *locationAtHome = [NSEntityDescription insertNewObjectForEntityForName:@"LocationAtHome" inManagedObjectContext:stackMobContext];
    LocationAtShop *locationAtShop = [NSEntityDescription insertNewObjectForEntityForName:@"LocationAtShop" inManagedObjectContext:stackMobContext];
    Unit *unit = [NSEntityDescription insertNewObjectForEntityForName:@"Unit" inManagedObjectContext:stackMobContext];
    Item *item = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:stackMobContext];
    Item_Photo *item_photo = [NSEntityDescription insertNewObjectForEntityForName:@"Item_Photo" inManagedObjectContext:stackMobContext];
    
    // Set Primary Key Fields
    [locationAtHome setValue:[locationAtHome assignObjectId] forKey:[locationAtHome primaryKeyField]];
    [locationAtShop setValue:[locationAtShop assignObjectId] forKey:[locationAtShop primaryKeyField]];
    [unit           setValue:[unit assignObjectId]           forKey:[unit primaryKeyField]];
    [item           setValue:[item assignObjectId]           forKey:[item primaryKeyField]];
    [item_photo     setValue:[item_photo assignObjectId]     forKey:[item_photo primaryKeyField]];
    
    // Give each attribute a value so the StackMob schema is generated automatically
    locationAtHome.storedIn = @"Fridge";
    locationAtShop.aisle = @"Cold Section";
    unit.name = @"L";
    item.name = @"Milk";
    item.collected = [NSNumber numberWithBool:NO];
    item.listed = [NSNumber numberWithBool:YES];
    item.quantity = [NSNumber numberWithInt:1];
    item.storedIn = @"Fridge"; //sectionNameKeyPath WORKAROUND (See Appendix B)
    item.aisle = @"Cold Section"; //sectionNameKeyPath WORKAROUND (See Appendix B)
    
    // Always save objects before relationships are created to avoid corruption
    [cdh saveContext];
    
    // Create relationships and then save again
    item.unit = unit;
    item.locationAtHome = locationAtHome;
    item.locationAtShop = locationAtShop;
    item.photo = item_photo;
    [cdh saveContext];
}
@end
