//
//  Item.h
//  Grocery Dude
//
//  Created by Tim Roadley on 1/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Item : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) NSData * photoData;
@property (nonatomic, retain) NSNumber * listed;
@property (nonatomic, retain) NSNumber * collected;

@end

