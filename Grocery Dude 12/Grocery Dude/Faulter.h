//
//  Faulter.h
//  Grocery Dude
//
//  Created by Tim Roadley on 29/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Faulter : NSObject

+ (void)faultObjectWithID:(NSManagedObjectID*)objectID
                inContext:(NSManagedObjectContext*)context;

@end
