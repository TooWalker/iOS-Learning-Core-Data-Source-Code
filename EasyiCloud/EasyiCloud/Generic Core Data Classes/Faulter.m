//
//  Faulter.m
//
//  Created by Tim Roadley on 29/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "Faulter.h"
@implementation Faulter

+ (void)faultObjectWithID:(NSManagedObjectID*)objectID
                inContext:(NSManagedObjectContext*)context {
    
    if (!objectID || !context) {
        return;
    }
    
    [context performBlockAndWait:^{
        
        NSManagedObject *object = [context objectWithID:objectID];
        
        if (object.hasChanges) {
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"ERROR saving: %@", error);
            }
        }
        
        if (!object.isFault) {
            
            NSLog(@"Faulting object %@ in context %@", object.objectID, context);
            [context refreshObject:object mergeChanges:NO];
        } else {
            NSLog(@"Skipped faulting an object that is already a fault");
        }
        
        // Repeat the process if the context has a parent
        if (context.parentContext) {
            [self faultObjectWithID:objectID inContext:context.parentContext];
        }
    }];
}
@end

