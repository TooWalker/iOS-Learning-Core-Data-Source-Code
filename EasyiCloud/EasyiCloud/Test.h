//
//  Test.h
//  EasyiCloud
//
//  Created by Tim Roadley on 23/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Test : NSManagedObject

@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSString * device;
@property (nonatomic, retain) NSString * someValue;

@end
