//
//  AppDelegate.h
//  Grocery Cloud
//
//  Created by Tim Roadley on 28/06/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataHelper.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) CoreDataHelper *coreDataHelper;
- (CoreDataHelper*)cdh;
@end
