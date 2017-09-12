//
//  Deduplicator.m
//  Grocery Dude
//
//  Created by Tim Roadley on 23/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "Deduplicator.h"
#import "Faulter.h" 

@implementation Deduplicator

+ (NSArray*)duplicatesForEntityWithName:(NSString*)entityName
                withUniqueAttributeName:(NSString*)uniqueAttributeName
                            withContext:(NSManagedObjectContext*)context {
    
    // GET UNIQUE ATTRIBUTE
    NSDictionary *allEntities = [[context.persistentStoreCoordinator managedObjectModel] entitiesByName];
    NSAttributeDescription *uniqueAttribute = [[[allEntities objectForKey:entityName] propertiesByName] objectForKey:uniqueAttributeName];
    
    // CREATE COUNT EXPRESSION
    NSExpressionDescription *countExpression = [NSExpressionDescription new];
    [countExpression setName:@"count"];
    [countExpression setExpression:[NSExpression expressionWithFormat:@"count:(%K)",uniqueAttributeName]];
    [countExpression setExpressionResultType:NSInteger64AttributeType];
    
    // CREATE ARRAY OF DICTIONARIES WITH COUNTS OF EACH UNIQUE VALUE
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setIncludesPendingChanges:NO];
    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:uniqueAttribute, countExpression, nil]];
    [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObject:uniqueAttribute]];
    [fetchRequest setResultType:NSDictionaryResultType];
    
    NSError *error;
    
    NSArray *instances = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {NSLog(@"Fetch Error: %@", error);}
    
    // RETURN AN ARRAY OF _DUPLICATE_ ATTRIBUTE VALUES
    NSArray *duplicates = [instances filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"count > 1"]];
    return duplicates;
}
+ (void)deDuplicateEntityWithName:(NSString*)entityName
          withUniqueAttributeName:(NSString*)uniqueAttributeName
                withImportContext:(NSManagedObjectContext*)importContext {
    
    [importContext performBlock:^{
        
        NSArray *duplicates = [Deduplicator duplicatesForEntityWithName:entityName
                                                withUniqueAttributeName:uniqueAttributeName
                                                            withContext:importContext];
        // FETCH DUPLICATE OBJECTS
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:uniqueAttributeName ascending:YES],nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K IN (%@.%K)", uniqueAttributeName, duplicates, uniqueAttributeName]];
        [fetchRequest setFetchBatchSize:100];
        [fetchRequest setIncludesPendingChanges:NO];
        NSError *error;
        NSArray *duplicateObjects = [importContext executeFetchRequest:fetchRequest error:&error];
        if (error) {NSLog(@"Fetch Error: %@", error);}
        
        // DELETE DUPLICATES
        NSManagedObject *lastObject;
        for (NSManagedObject *object in duplicateObjects) {
            if (lastObject) {
                if ([[object valueForKey:uniqueAttributeName] isEqual:[lastObject valueForKey:uniqueAttributeName]]) {
                    
                    NSLog(@"*** Deleting Duplicate %@ with %@ '%@' ***", entityName, uniqueAttributeName, [object valueForKey:uniqueAttributeName]);
                    
                    // DELETE OLDEST DUPLICATE...
                    NSDate *date1 = [object valueForKey:@"modified"];
                    NSDate *date2 = [lastObject valueForKey:@"modified"];
                    
                    if ([date1 compare:date2] == NSOrderedAscending) {
                        [importContext deleteObject:object];
                    } else if ([date1 compare:date2] == NSOrderedDescending) {
                        [importContext deleteObject:lastObject];
                    }
                    
                    // ..or.. DELETE DUPLICATE WITH LESS ATTRIBUTE VALUES (if dates match)
                    else if ([[object committedValuesForKeys:nil] count] > [[lastObject committedValuesForKeys:nil] count]) {
                        [importContext deleteObject:lastObject];
                    } else {
                        [importContext deleteObject:object];
                    }
                    [self saveContextHeirarchy:importContext];
                    
                    // Save & fault objects
                    [Faulter faultObjectWithID:object.objectID inContext:importContext];
                    [Faulter faultObjectWithID:lastObject.objectID inContext:importContext];
                }
            }
            lastObject = object;
        }
    }];
}

#pragma mark - SAVING
+ (void)saveContextHeirarchy:(NSManagedObjectContext*)moc {
    [moc performBlockAndWait:^{
        if ([moc hasChanges]) {
            [moc processPendingChanges];
            NSError *error;
            if (![moc save:&error]) {
                NSLog(@"ERROR Saving: %@",error);
            }
        }
        // Save the parent context, if any.
        if ([moc parentContext]) {
            [self saveContextHeirarchy:moc.parentContext];
        }
    }];
}
@end
