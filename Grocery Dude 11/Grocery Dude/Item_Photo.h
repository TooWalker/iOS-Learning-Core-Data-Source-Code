//
//  Item_Photo.h
//  Grocery Dude
//
//  Created by Tim Roadley on 28/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item;

@interface Item_Photo : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) Item *item;

@end
