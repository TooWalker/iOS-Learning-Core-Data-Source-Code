//
//  CoreDataHelper.h
//
//  Created by Tim Roadley on 30/06/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

/*
    USAGE:
 
 1. Add the following code to the top of AppDelegate.h:
 
        #import "CoreDataHelper.h"
 

 2. Add the following code to the bottom of AppDelegate.h, before @end:
 
        @property (nonatomic, strong, readonly) CoreDataHelper *coreDataHelper;
        - (CoreDataHelper*)cdh;
 

 3. Add the following code to the top of AppDelegate.m, after @implementation AppDelegate:

        - (CoreDataHelper*)cdh {
            if (!_coreDataHelper) {
                static dispatch_once_t predicate;
                dispatch_once(&predicate, ^{
                    _coreDataHelper = [CoreDataHelper new];
                });
                [_coreDataHelper setupCoreData];
            }
            return _coreDataHelper;
        }

 
 4. Gain reference to CoreDataHelper in any class by importing AppDelegate.h and CoreDataHelper.h, then adding the following code:

	CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh]; 


 5. Add a Core Data > Data Model and design it as you see fit. For full information, please read Learning Core Data for iOS by Tim Roadley.
 
*/

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
//#import "MigrationVC.h"

@interface CoreDataHelper : NSObject <UIAlertViewDelegate, NSXMLParserDelegate>

@property (nonatomic, readonly) NSManagedObjectContext       *parentContext;
@property (nonatomic, readonly) NSManagedObjectContext       *context;
@property (nonatomic, readonly) NSManagedObjectContext       *importContext; 
@property (nonatomic, readonly) NSManagedObjectModel         *model;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, readonly) NSPersistentStore            *store;

@property (nonatomic, readonly) NSManagedObjectContext       *sourceContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *sourceCoordinator;
@property (nonatomic, readonly) NSPersistentStore            *sourceStore;

@property (nonatomic, readonly) NSManagedObjectContext       *seedContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *seedCoordinator;
@property (nonatomic, readonly) NSPersistentStore            *seedStore;
@property (nonatomic, retain)   UIAlertView                  *seedAlertView;
@property (nonatomic)           BOOL                          seedInProgress;

//@property (nonatomic, retain) MigrationVC *migrationVC;
@property (nonatomic, retain) UIAlertView *importAlertView;
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSTimer *importTimer;

@property (nonatomic, readonly) NSPersistentStore *iCloudStore; 

- (void)setupCoreData;
- (void)saveContext;
- (void)backgroundSaveContext;
+ (void)saveContextHeirarchy:(NSManagedObjectContext*)moc;
- (BOOL)reloadStore;
- (NSURL *)applicationStoresDirectory;
- (BOOL)iCloudAccountIsSignedIn;
- (void)ensureAppropriateStoreIsLoaded;
- (BOOL)iCloudEnabledByUser;
@end
