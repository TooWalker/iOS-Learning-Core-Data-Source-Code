//
//  DropboxTVC.m
//  Grocery Dude
//
//  Created by Tim Roadley on 1/08/13.
//  Copyright (c) 2013 Tim Roadley. All rights reserved.
//

#import "DropboxTVC.h"
@implementation DropboxTVC

#pragma mark - DATA
NSInteger sort(DBFileInfo *a, DBFileInfo *b, void *ctx) {
    return [[b modifiedTime] compare:[a modifiedTime]];
}
- (void)reload {
    [self refreshStatus];
    if (_loading) return;_loading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^() {
        NSArray *actualContents = [[DBFilesystem sharedFilesystem] listFolder:[DBPath root] error:nil];
        NSMutableArray *updatedContents = [NSMutableArray arrayWithArray:actualContents];
        
        // Don't list folders
        NSMutableArray *folders = [NSMutableArray new];
        for (DBFileInfo *info in updatedContents) {
            if (info.isFolder) {[folders addObject:info];}
        }
        [updatedContents removeObjectsInArray:folders];
        
        // Don't list files that don't end with 'Stores.zip'
        NSMutableArray *notValid = [NSMutableArray new];
        for (DBFileInfo *info in updatedContents) {
            if (![[[info path] stringValue] hasSuffix:@"Stores.zip"]) {
                NSLog(@"Not listing invalid file: %@", [[info path] stringValue]);
                [notValid addObject:info];
            }
        }
        [updatedContents removeObjectsInArray:notValid];
        
        [updatedContents sortUsingFunction:sort context:NULL];
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.contents = updatedContents;
            _loading = NO;
            [self.tableView reloadData];
            [self refreshStatus];
        });
    });
}
- (void)refreshStatus {
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (!account.isLinked) {
        self.navigationItem.title = @"Unlinked";
    } else if ([[DBFilesystem sharedFilesystem] status] > DBSyncStatusActive) {
        self.navigationItem.title = @"Syncing";
    } else {
        self.navigationItem.title = @"Backups";
    }
}

#pragma mark - VIEW
- (void)viewDidLoad {
    _contents = [NSMutableArray new];
    _loading = NO;
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (!account.isLinked) {
        [DropboxHelper linkToDropboxWithUI:self];
    }
    [super viewDidLoad];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __block DropboxTVC *DropboxTVC = self;
    [[DBFilesystem sharedFilesystem] addObserver:self block:^(){[self reload];}];
    [[DBFilesystem sharedFilesystem] addObserver:self forPathAndChildren:[DBPath root] block:^() {
        [DropboxTVC reload];
    }];
    [DropboxTVC reload];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[DBFilesystem sharedFilesystem] removeObserver:self];
}

#pragma mark - BACKUP
- (IBAction)backup:(id)sender {
    [DropboxHelper linkToDropboxWithUI:self];
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account.isLinked) {
        CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
        [cdh.context performBlock:^{
            // Save all contexts
            [cdh.sourceContext performBlockAndWait:^{[cdh.sourceContext save:nil];}];
            [cdh.importContext performBlockAndWait:^{[cdh.importContext save:nil];}];
            [cdh.context performBlockAndWait:^{[cdh.context save:nil];}];
            [cdh.parentContext performBlockAndWait:^{[cdh.parentContext save:nil];}];
            
            NSLog(@"Creating a dated backup of the Stores directory...");
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setDateFormat:@"[yyyy-MMM-dd] hh.mm a"];
            NSString *date = [formatter stringFromDate:[NSDate date]];
            NSString *zipFileName = [NSString stringWithFormat:@"%@ Stores.zip", date];
            NSURL *zipFile = [DropboxHelper zipFolderAtURL:[cdh applicationStoresDirectory] withZipfileName:zipFileName];
            
            NSLog(@"Copying the backup zip to Dropbox...");
            DBPath *zipFileInDropbox = [[DBPath root] childPath:zipFile.lastPathComponent];
            if ([DropboxHelper fileExistsAtDropboxPath:zipFileInDropbox]) {
                NSLog(@"Removing existing backup with same name...");
                [DropboxHelper deleteFileAtDropboxPath:zipFileInDropbox];
            }
            [DropboxHelper copyFileAtURL:zipFile toDropboxPath:zipFileInDropbox];
            NSLog(@"Deleting the local backup zip...");
            [DropboxHelper deleteFileAtURL:zipFile];
            [DropboxHelper listFilesAtDropboxPath:[DBPath root]];
            [self alertSuccess:YES];
        }];
    } else {
        [self alertSuccess:NO];
    }
}
- (void)alertSuccess:(BOOL)success {
    NSString *title;
    NSString *message;
    if (success) {
        title = [NSString stringWithFormat:@"Success"];
        message = [NSString stringWithFormat:@"A backup has been created. It will appear in the Apps/Grocery Dude directory of your Dropbox. Consider removing old backups when you no longer require them"];
    } else {
        title = [NSString stringWithFormat:@"Fail"];
        message = [NSString stringWithFormat:@"You must be logged in to Dropbox to create backups"];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    [alert show];
}

#pragma mark - DATASOURCE: UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_contents count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Backup Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    DBFileInfo *info = [_contents objectAtIndex:[indexPath row]];
	NSString *string = info.path.name;
    cell.textLabel.text = [string stringByReplacingOccurrencesOfString:@" Stores.zip" withString:@""];
    float fileSize = info.size;
    
    NSMutableString *subtitle = [NSMutableString new];
    
    // Show transfer progress
    DBError *openError = nil;
    DBFile *file = [[DBFilesystem sharedFilesystem] openFile:info.path error:&openError];
    if (!file) {NSLog(@"Error opening file '%@': %@", info.path.stringValue, openError);}
    int progress = [[file status] progress] * 100;
    if (progress != 100) {
        if ([[file status] state] == DBFileStateDownloading) {
            [subtitle appendString:[NSString stringWithFormat:@"Downloaded %i%% of ",progress]];
        } else if ([[file status] state] == DBFileStateUploading) {
            [subtitle appendString:[NSString stringWithFormat:@"Uploaded %i%% of ",progress]];
        }
    }
    
    // Show File Size
    [subtitle appendString:[NSString stringWithFormat:@"%.2f Megabytes", fileSize/1024/1024]];
    cell.detailTextLabel.text = subtitle;
    
    return cell;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView && editingStyle == UITableViewCellEditingStyleDelete) {
        DBFileInfo *deleteTarget = [_contents objectAtIndex:indexPath.row];
        [DropboxHelper deleteFileAtDropboxPath:deleteTarget.path];
        [_contents removeObjectAtIndex:indexPath.row];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - RESTORE
- (void)restore {
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (!account.isLinked) {[DropboxHelper linkToDropboxWithUI:self];}
    if (account) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            DBFileInfo *info = [_contents objectAtIndex:indexPath.row];
            
            // Don't restore partially downloaded files
            if (![[[[DBFilesystem sharedFilesystem] openFile:info.path error:nil] status] cached] ||
                [[[DBFilesystem sharedFilesystem] openFile:info.path error:nil] newerStatus]
                
                ) {
                
                UIAlertView *failAlert = [[UIAlertView alloc] initWithTitle:@"Failed to Restore"
                                                                    message:@"The file is not ready"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"Close", nil];
                [failAlert show];
                return;
            }
            _selectedZipFileName = info.path.name;
            NSLog(@"Selected '%@' for restore", _selectedZipFileName);
            
            NSString *restorePoint = [_selectedZipFileName stringByReplacingOccurrencesOfString:@" Stores.zip" withString:@""];
            
            NSString *message = [NSString stringWithFormat:@"Are you sure want to restore from %@ backup? Existing data will be lost. The application may pause for the duration of the restore.", restorePoint];
            
            _confirmRestore = [[UIAlertView alloc] initWithTitle:nil
                                                         message:message
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Restore", nil];
            [_confirmRestore show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"Please select a backup to restore"
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}
- (IBAction)options:(id)sender {
    NSString *title, *toggleLink, *restore;
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account.isLinked) {
        restore = [NSString stringWithFormat:@"Restore Selected Backup"];
        toggleLink = [NSString stringWithFormat:@"Unlink from Dropbox"];
        if (account.info.displayName) {
            title = [NSString stringWithFormat:@"Dropbox: %@", account.info.displayName];
        } else {
            title = [NSString stringWithFormat:@"Dropbox: Linked"];
        }
    } else {
        toggleLink = [NSString stringWithFormat:@"Link to Dropbox"];
        title = [NSString stringWithFormat:@"Dropbox: Not Linked"];
    }
    _options = [[UIActionSheet alloc] initWithTitle:title
                                           delegate:self
                                  cancelButtonTitle:@"Cancel"
                             destructiveButtonTitle:nil
                                  otherButtonTitles:toggleLink,restore, nil];
    [_options showFromTabBar:self.navigationController.tabBarController.tabBar];
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (actionSheet == _options) {
        switch (buttonIndex) {
            case 0:
                if (account.isLinked) {
                    [DropboxHelper unlinkFromDropbox];
                    [self reload];
                } else {
                    [DropboxHelper linkToDropboxWithUI:self];
                    [self reload];
                }
                break;
            case 1:
                [self restore];
                break;
            default:
                break;
        }
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == _confirmRestore && buttonIndex == 1) {
        CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
        [DropboxHelper restoreFromDropboxStoresZip:_selectedZipFileName withCoreDataHelper:cdh];
    }
}

@end
