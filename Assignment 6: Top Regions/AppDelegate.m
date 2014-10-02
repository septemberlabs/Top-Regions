//
//  AppDelegate.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/12/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "AppDelegate.h"
#import "Photo+Flickr.h"
#import "FlickrFetcher.h"
#import "PhotoDatabaseAvailability.h"

@interface AppDelegate() <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^flickrDownloadBackgroundURLSessionCompletionHandler)();
@property (strong, nonatomic) NSURLSession *flickrDownloadSession;
@property (strong, nonatomic) NSTimer *flickrForegroundFetchTimer;
@property (strong, nonatomic) NSManagedObjectContext *photoDatabaseContext;
@property (strong, nonatomic) UIManagedDocument *document;
@end

// name of the Flickr fetching background download session
#define FLICKR_FETCH @"Flickr just uploaded fetch"

// how often (in seconds) we fetch new photos if we are in the foreground
#define FOREGROUND_FLICKR_FETCH_INTERVAL (20*60)

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // first thing the app should do: create the UIManagedDocument, to create the managed object context used throughout
    [self createManagedDocument];
    [self startFlickrFetch]; // kick off a Flickr fetch upon launch
    return YES;

}

- (void)createManagedDocument {
    
    // the UIManagedDocument approach to getting a managed object context (different than how it was done in lecture)
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSString *documentName = @"FlickrDatabase";
    NSURL *url = [documentsDirectory URLByAppendingPathComponent:documentName];
    self.document = [[UIManagedDocument alloc] initWithFileURL:url]; // this creates the UIManagedDocument in memory, but we need the code below to actually put the data on disk
    
    // if document exists, open it; if not, create it.
    if ([fileManager fileExistsAtPath:[url path]]) {
        [self.document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                [self documentIsReady];
                NSLog(@"opened document at %@", url);
            }
            if (!success) NSLog(@"couldn't open document at %@", url);
        }];
    }
    else {
        [self.document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                [self documentIsReady];
                NSLog(@"created document at %@", url);
            }
            if (!success) NSLog(@"couldn't create document at %@", url);
        }];
    }

}

- (void)documentIsReady {
    if (self.document.documentState == UIDocumentStateNormal) {
        self.photoDatabaseContext = self.document.managedObjectContext;
    }
    else {
        NSLog(@"document state is not normal.");
    }
}

- (void)setPhotoDatabaseContext:(NSManagedObjectContext *)photoDatabaseContext {
    
    _photoDatabaseContext = photoDatabaseContext;
    
    NSDictionary *userInfo = self.photoDatabaseContext ? @{ PhotoDatabaseAvailabilityContext : self.photoDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
    
}


// this might not work if we're in the background (discretionary), but that's OK
- (void)startFlickrFetch {
    
    [self.flickrDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if (![downloadTasks count]) {
            NSURLSessionDownloadTask *task = [self.flickrDownloadSession downloadTaskWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
            task.taskDescription = FLICKR_FETCH;
            [task resume];
        }
        else {
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];

}

// the NSURLSession we will use to fetch Flickr data in the background
- (NSURLSession *)flickrDownloadSession {
    
    if (!_flickrDownloadSession) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:FLICKR_FETCH];
            urlSessionConfig.allowsCellularAccess = NO; // for example
            _flickrDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:self
                                                              delegateQueue:nil];
        });
    }
    return _flickrDownloadSession;
    
}

- (NSArray *)flickrPhotosAtURL:(NSURL *)url {
    NSData *flickrJSONData = [NSData dataWithContentsOfURL:url];
    NSDictionary *flickrPropertyList = [NSJSONSerialization JSONObjectWithData:flickrJSONData options:0 error:NULL];
    NSArray *photos = [flickrPropertyList valueForKeyPath:FLICKR_RESULTS_PHOTOS];
    //NSLog(@"results: %@", flickrPropertyList);
    //NSLog(@"photos: %@", photos);
    return photos;
}

#pragma mark - NSURLSessionDownloadDelegate

// required by the protocol
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)localFile {

    if ([downloadTask.taskDescription isEqualToString:FLICKR_FETCH]) {
        NSManagedObjectContext *context = self.photoDatabaseContext;
        if (context) {
            NSArray *photos = [self flickrPhotosAtURL:localFile];
            [context performBlock:^{
                [Photo loadPhotosFromFlickrArray:photos intoManagedObjectContext:context];
                [context save:NULL];
            }];
        }
        else {
            [self flickrDownloadTasksMightBeComplete];
        }
    }
    
}

// required by the protocol
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {}

// required by the protocol
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {}


- (void)flickrDownloadTasksMightBeComplete {}

@end
