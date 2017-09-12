//
//  Item.h
//  Grocery Dude
//
//  Created by Tim Roadley on 28/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item_Photo, LocationAtHome, LocationAtShop, Unit;

@interface Item : NSManagedObject

@property (nonatomic, retain) NSNumber * collected;
@property (nonatomic, retain) NSNumber * listed;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) LocationAtHome *locationAtHome;
@property (nonatomic, retain) LocationAtShop *locationAtShop;
@property (nonatomic, retain) Item_Photo *photo;
@property (nonatomic, retain) Unit *unit;

@end
