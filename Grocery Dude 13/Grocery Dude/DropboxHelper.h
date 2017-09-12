//
//  DropboxHelper.h
//  Grocery Dude
//
//  Created by Tim Roadley on 1/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Dropbox/Dropbox.h>
#import "CoreDataHelper.h"

@interface DropboxHelper : NSObject

#pragma mark - DROPBOX ACCOUNT
+ (void)linkToDropboxWithUI:(UIViewController*)controller;
+ (void)unlinkFromDropbox;

#pragma mark - LOCAL FILE MANAGEMENT
+ (NSURL*)renameLastPathComponentOfURL:(NSURL*)url toName:(NSString*)name;
+ (BOOL)deleteFileAtURL:(NSURL*)url;
+ (void)createParentFolderForFile:(NSURL*)url;

#pragma mark - DROPBOX FILE MANAGEMENT
+ (BOOL)fileExistsAtDropboxPath:(DBPath*)dropboxPath;
+ (void)listFilesAtDropboxPath:(DBPath*)dropboxPath;
+ (void)deleteFileAtDropboxPath:(DBPath*)dropboxPath;
+ (void)copyFileAtDropboxPath:(DBPath*)dropboxPath toURL:(NSURL*)url;
+ (void)copyFileAtURL:(NSURL*)url toDropboxPath:(DBPath*)dropboxPath;

#pragma mark - BACKUP / RESTORE
+ (NSURL*)zipFolderAtURL:(NSURL*)url withZipfileName:(NSString*)zipFileName;
+ (void)unzipFileAtURL:(NSURL*)zipFileURL toURL:(NSURL*)unzipURL;
+ (void)restoreFromDropboxStoresZip:(NSString*)fileName
                 withCoreDataHelper:(CoreDataHelper*)cdh;

@end
