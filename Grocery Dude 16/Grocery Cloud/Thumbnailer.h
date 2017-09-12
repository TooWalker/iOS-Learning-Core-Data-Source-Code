//
//  Thumbnailer.h
//  Grocery Cloud
//
//  Created by Tim Roadley on 29/07/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Thumbnailer : NSObject

+ (void)createMissingThumbnailsForEntityName:(NSString*)entityName
                  withThumbnailAttributeName:(NSString*)thumbnailAttributeName
                   withPhotoRelationshipName:(NSString*)photoRelationshipName
                      withPhotoAttributeName:(NSString*)photoAttributeName
                         withSortDescriptors:(NSArray*)sortDescriptors
                           withImportContext:(NSManagedObjectContext*)importContext;
@end
