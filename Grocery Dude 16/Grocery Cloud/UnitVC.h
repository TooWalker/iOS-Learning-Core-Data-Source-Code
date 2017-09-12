//
//  UnitVC.h
//  Grocery Cloud
//
//  Created by Tim Roadley on 12/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataHelper.h"
@interface UnitVC : UIViewController <UITextFieldDelegate>
@property (strong, nonatomic) NSManagedObjectID *selectedObjectID;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@end
