//
//  CoreDataHelper.m
//  Grocery Dude
//
//  Created by Tim Roadley on 30/06/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "CoreDataHelper.h"

@implementation CoreDataHelper

#define debug 1

#pragma mark - FILES
NSString *storeFilename = @"Grocery-Dude.sqlite";

#pragma mark - PATHS
- (NSString *)applicationDocumentsDirectory {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES) lastObject];
}
- (NSURL *)applicationStoresDirectory {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    NSURL *storesDirectory = [[NSURL fileURLWithPath:[self applicationDocumentsDirectory]] URLByAppendingPathComponent:@"Stores"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[storesDirectory path]]) {
        NSError *error = nil;
        if ([fileManager createDirectoryAtURL:storesDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
            if (debug==1) {NSLog(@"Successfully created Stores directory");}
        }
        else {NSLog(@"FAILED to create Stores directory: %@", error);}
    }
    return storesDirectory;
}
- (NSURL *)storeURL {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    return [[self applicationStoresDirectory] URLByAppendingPathComponent:storeFilename];
}

#pragma mark - SETUP
- (id)init {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self = [super init];
    if (!self) {return nil;}
    
    _model = [NSManagedObjectModel mergedModelFromBundles:nil];
    _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_context setPersistentStoreCoordinator:_coordinator];
    return self;
}
- (void)loadStore {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    if (_store) {return;} // Don’t load store if it’s already loaded
    
    BOOL useMigrationManager = NO;
    if (useMigrationManager && [self isMigrationNecessaryForStore:[self storeURL]]) {
        [self performBackgroundManagedMigrationForStore:[self storeURL]];
    } else {
        NSDictionary *options =
        @{
          NSMigratePersistentStoresAutomaticallyOption:@YES
          ,NSInferMappingModelAutomaticallyOption:@YES
          };
        NSError *error = nil;
        _store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                            configuration:nil
                                                      URL:[self storeURL]
                                                  options:options error:&error];
        if (!_store) {NSLog(@"Failed to add store. Error: %@", error);abort();}
        else         {NSLog(@"Successfully added store: %@", _store);}
    }
}
- (void)setupCoreData {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self loadStore];
}

#pragma mark - SAVING
- (void)saveContext {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([_context hasChanges]) {
        NSError *error = nil;
        if ([_context save:&error]) {NSLog(@"_context SAVED changes to persistent store");}
        else {NSLog(@"Failed to save _context: %@", error);[self showValidationError:error];}
    } else {
        NSLog(@"SKIPPED _context save, there are no changes!");
    }
}

#pragma mark - MIGRATION MANAGER
- (BOOL)isMigrationNecessaryForStore:(NSURL*)storeUrl {
    
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self storeURL].path]) {
        if (debug==1) {NSLog(@"SKIPPED MIGRATION: Source database missing.");}
        return NO;
    }
    NSError *error = nil;
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeUrl error:&error];
    NSManagedObjectModel *destinationModel = _coordinator.managedObjectModel;
    if ([destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]) {
        if (debug==1) {NSLog(@"SKIPPED MIGRATION: Source is aleady compatible");}
        return NO;
    }
    return YES;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"migrationProgress"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            float progress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
            self.migrationVC.progressView.progress = progress;
            int percentage = progress * 100;
            NSString *string = [NSString stringWithFormat:@"Migration Progress: %i%%",percentage];
            NSLog(@"%@",string);
            self.migrationVC.label.text = string;
        });
    }
}
- (BOOL)replaceStore:(NSURL*)old withStore:(NSURL*)new {
    
    BOOL success = NO;
    NSError *Error = nil;
    if ([[NSFileManager defaultManager]
         removeItemAtURL:old error:&Error]) {
        
        Error = nil;
        if ([[NSFileManager defaultManager]
             moveItemAtURL:new toURL:old error:&Error]) {
            success = YES;
        }
        else {
            if (debug==1) {NSLog(@"FAILED to re-home new store %@", Error);}
        }
    }
    else {
        if (debug==1) {NSLog(@"FAILED to remove old store %@: Error:%@", old, Error);}
    }
    return success;
}
- (BOOL)migrateStore:(NSURL*)sourceStore {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    BOOL success = NO;
    NSError *error = nil;
    
    // STEP 1 - Gather the Source, Destination and Mapping Model
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:sourceStore error:&error];
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:sourceMetadata];
    NSManagedObjectModel *destinModel = _model;
    NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:nil forSourceModel:sourceModel destinationModel:destinModel];
    
    // STEP 2 - Perform migration, assuming the mapping model isn't null
    if (mappingModel) {
        NSError *error = nil;
        NSMigrationManager *migrationManager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel
                                                                              destinationModel:destinModel];
        [migrationManager addObserver:self forKeyPath:@"migrationProgress" options:NSKeyValueObservingOptionNew context:NULL];
        
        NSURL *destinStore = [[self applicationStoresDirectory] URLByAppendingPathComponent:@"Temp.sqlite"];
        
        success = [migrationManager migrateStoreFromURL:sourceStore type:NSSQLiteStoreType options:nil
                                       withMappingModel:mappingModel
                                       toDestinationURL:destinStore destinationType:NSSQLiteStoreType destinationOptions:nil
                                                  error:&error];
        if (success) {
            // STEP 3 - Replace the old store with the new migrated store
            if ([self replaceStore:sourceStore withStore:destinStore]) {
                if (debug==1) {NSLog(@"SUCCESSFULLY MIGRATED %@ to the Current Model", sourceStore.path);}
                [migrationManager removeObserver:self forKeyPath:@"migrationProgress"];
            }
        }
        else {
            if (debug==1) {NSLog(@"FAILED MIGRATION: %@",error);}
        }
    }
    else {
        if (debug==1) {NSLog(@"FAILED MIGRATION: Mapping Model is null");}
    }
    return YES; // indicates migration has finished, regardless of outcome
}
- (void)performBackgroundManagedMigrationForStore:(NSURL*)storeURL {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    // Show migration progress view, which prevents the user from using the app
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.migrationVC = [sb instantiateViewControllerWithIdentifier:@"migration"];
    UIApplication *sa = [UIApplication sharedApplication];
    UINavigationController *nc = (UINavigationController*)sa.keyWindow.rootViewController;
    [nc presentViewController:self.migrationVC animated:NO completion:nil];
    
    // Perform migration in the background, so it doesn't freeze the UI.
    // This way progress can be shown to the user
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL done = [self migrateStore:storeURL];
        if(done) {
            // When migration finishes, add the newly migrated store
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = nil;
                _store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                    configuration:nil
                                                              URL:[self storeURL]
                                                          options:nil error:&error];
                if (!_store) {NSLog(@"Failed to add a migrated store. Error: %@", error);abort();}
                else         {NSLog(@"Successfully added a migrated store: %@", _store);}
                
                [self.migrationVC dismissViewControllerAnimated:NO completion:nil];
                self.migrationVC = nil;
            });
        }
    });
}

#pragma mark - VALIDATION ERROR HANDLING
- (void)showValidationError:(NSError *)anError {
    
    if (anError && [anError.domain isEqualToString:@"NSCocoaErrorDomain"]) {
        NSArray *errors = nil;  // holds all errors
        NSString *txt = @""; // the error message text of the alert
        
        // Populate array with error(s)
        if (anError.code == NSValidationMultipleErrorsError) {
            errors = [anError.userInfo objectForKey:NSDetailedErrorsKey];
        } else {
            errors = [NSArray arrayWithObject:anError];
        }
        
        // Display the error(s)
        if (errors && errors.count > 0) {
            // Build error message text based on errors
            for (NSError * error in errors) {
                NSString *entity = [[[error.userInfo objectForKey:@"NSValidationErrorObject"] entity] name];
                NSString *property = [error.userInfo objectForKey:@"NSValidationErrorKey"];
                
                switch (error.code) {
                    case NSValidationRelationshipDeniedDeleteError:
                        txt = [txt stringByAppendingFormat:@"%@ delete was denied because there are associated %@ (Error Code %i)\n\n", entity, property, error.code];
                        break;
                    case NSValidationRelationshipLacksMinimumCountError:
                        txt = [txt stringByAppendingFormat:@"the '%@' relationship count is too small (Code %i).", property, error.code];
                        break;
                    case NSValidationRelationshipExceedsMaximumCountError:
                        txt = [txt stringByAppendingFormat:@"the '%@' relationship count is too large (Code %i).", property, error.code];
                        break;
                    case NSValidationMissingMandatoryPropertyError:
                        txt = [txt stringByAppendingFormat:@"the '%@' property is missing (Code %i).", property, error.code];
                        break;
                    case NSValidationNumberTooSmallError:
                        txt = [txt stringByAppendingFormat:@"the '%@' number is too small (Code %i).", property, error.code];
                        break;
                    case NSValidationNumberTooLargeError:
                        txt = [txt stringByAppendingFormat:@"the '%@' number is too large (Code %i).", property, error.code];
                        break;
                    case NSValidationDateTooSoonError:
                        txt = [txt stringByAppendingFormat:@"the '%@' date is too soon (Code %i).", property, error.code];
                        break;
                    case NSValidationDateTooLateError:
                        txt = [txt stringByAppendingFormat:@"the '%@' date is too late (Code %i).", property, error.code];
                        break;
                    case NSValidationInvalidDateError:
                        txt = [txt stringByAppendingFormat:@"the '%@' date is invalid (Code %i).", property, error.code];
                        break;
                    case NSValidationStringTooLongError:
                        txt = [txt stringByAppendingFormat:@"the '%@' text is too long (Code %i).", property, error.code];
                        break;
                    case NSValidationStringTooShortError:
                        txt = [txt stringByAppendingFormat:@"the '%@' text is too short (Code %i).", property, error.code];
                        break;
                    case NSValidationStringPatternMatchingError:
                        txt = [txt stringByAppendingFormat:@"the '%@' text doesn't match the specified pattern (Code %i).", property, error.code];
                        break;
                    case NSManagedObjectValidationError:
                        txt = [txt stringByAppendingFormat:@"generated validation error (Code %i)", error.code];
                        break;
                    default:
                        txt = [txt stringByAppendingFormat:@"Please tell the developer of this application to add a case to the switch statement in the showValidationError method of CoreDataHelper.m for error code %i. They can read 'Learning Core Data' by Tim Roadley for full instructions.", error.code];
                        break;
                }
            }
            // display error message txt message
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Validation Error"
                                                                message:[NSString stringWithFormat:@"%@Please double-tap the home button and close this application by swiping the application screenshot upwards",txt]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}
@end
