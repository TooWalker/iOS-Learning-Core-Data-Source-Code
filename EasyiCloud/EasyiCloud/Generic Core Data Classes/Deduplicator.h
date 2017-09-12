//
//  Deduplicator.h
//
//  Created by Tim Roadley on 13/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h> 

@interface Deduplicator : NSObject

+ (void)deDuplicateEntityWithName:(NSString*)entityName
          withUniqueAttributeName:(NSString*)uniqueAttributeName
                withImportContext:(NSManagedObjectContext*)importContext;

@end
