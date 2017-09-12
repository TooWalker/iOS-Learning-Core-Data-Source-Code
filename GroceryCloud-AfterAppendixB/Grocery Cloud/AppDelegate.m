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
    [[self cdh] backgroundSaveContext];
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
    [[self cdh] backgroundSaveContext];
}

@end
