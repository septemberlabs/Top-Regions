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
@property (strong, nonatomic) NSURLSession *flickrDownloadSession; // for fetch of photo dictionary
@property (strong, nonatomic) NSURLSession *flickrRegionInfoDownloadTasks; // for fetches of region info for multiple photos
@property (strong, nonatomic) NSTimer *flickrForegroundFetchTimer;
@property (strong, nonatomic) NSManagedObjectContext *photoDatabaseContext;
@property (strong, nonatomic) UIManagedDocument *document;
@end

// name of the Flickr fetching background download session
#define FLICKR_FETCH @"Flickr just uploaded fetch"

// how often (in seconds) we fetch new photos if we are in the foreground
#define FOREGROUND_FLICKR_FETCH_INTERVAL (10*1000)

// how long we'll wait for a Flickr fetch to return when we're in the background
#define BACKGROUND_FLICKR_FETCH_TIMEOUT (10)

@implementation AppDelegate

#pragma mark - UIApplicationDelegate

// this is called as soon as our storyboard is read in and we're ready to get started
// but it's still very early in the game (UI is not yet on screen, for example)

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // when we're in the background, fetch as often as possible (which won't be much)
    // forgot to include this line in the demo during lecture, but don't forget to include it in your app!
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // first thing the app should do: create the UIManagedDocument, to create the managed object context used throughout
    [self createManagedDocument];
    
    // add an observer for the user refresh notification, which will trigger a fetch
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startFlickrFetchFromNotification:)
                                                 name:@"userRefresh"
                                               object:nil];
    
    // this return value has to do with handling URLs from other applications
    // don't worry about it for now, just return YES
    return YES;
}

#pragma mark - UIManagedDocument

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

// kick off a Flickr fetch upon launch, but only once the UIManagedDocument open/creates successfully and can thereby provide the managed object context. As the hints for Assignment 6 state, opening/creating a UIManagedDocument happens asynchronously and can block, preventing the managed object context from being available to startFlickrFetch. We therefore call startFlickrFetch from within the completion handler of the UIManagedDocument open/create.
- (void)documentIsReady
{
    //NSLog(@"documentIsReady called");
    if (self.document.documentState == UIDocumentStateNormal) {
        self.photoDatabaseContext = self.document.managedObjectContext;
        [self startFlickrFetch];
    }
    else {
        NSLog(@"document state is not normal.");
    }
}

#pragma mark - Database Context

// we do some stuff when our Photo database's context becomes available
// we kick off our foreground NSTimer so that we are fetching every once in a while in the foreground
// we post a notification to let others know the context is available

- (void)setPhotoDatabaseContext:(NSManagedObjectContext *)photoDatabaseContext
{
    //NSLog(@"setPhotoDatabaseContext called");
    
    _photoDatabaseContext = photoDatabaseContext;
    
    // every time the context changes, we'll restart our timer
    // so kill (invalidate) the current one
    // (we didn't get to this line of code in lecture, sorry!)
    [self.flickrForegroundFetchTimer invalidate];
    self.flickrForegroundFetchTimer = nil;
    
    if (self.photoDatabaseContext) {
        // this is a timer that works only when the app is in the foreground, calling startFlickrFetchFromTimer: every FOREGROUND_FLICKR_FETCH_INTERVAL
        self.flickrForegroundFetchTimer = [NSTimer scheduledTimerWithTimeInterval:FOREGROUND_FLICKR_FETCH_INTERVAL
                                                                           target:self
                                                                         selector:@selector(startFlickrFetchFromTimer:)
                                                                         userInfo:nil
                                                                          repeats:YES];
    }
    
    // let everyone who might be interested know this context is available
    // this happens very early in the running of our application
    // it would make NO SENSE to listen to this radio station in a View Controller that was segued to, for example
    // (but that's okay because a segued-to View Controller would presumably be "prepared" by being given a context to work in)
    NSDictionary *userInfo = self.photoDatabaseContext ? @{ PhotoDatabaseAvailabilityContext : self.photoDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
    
}

#pragma mark - Background Management

// this is called occasionally by the system WHEN WE ARE NOT THE FOREGROUND APPLICATION
// in fact, it will LAUNCH US if necessary to call this method
// the system has lots of smarts about when to do this, but it is entirely opaque to us.
// From the docs: "Implement this method if your app supports the fetch background mode. When an opportunity arises to download data, the system calls this method to give your app a chance to download any data it needs. Your implementation of this method should download the data, prepare that data for use, and call the block in the completionHandler parameter."
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"performFetchWithCompletionHandler called");
    
    // in lecture, we relied on our background flickrDownloadSession to do the fetch by calling [self startFlickrFetch]
    // that was easy to code up, but pretty weak in terms of how much it will actually fetch (maybe almost never)
    // that's because there's no guarantee that we'll be allowed to start that discretionary fetcher when we're in the background
    // so let's simply make a non-discretionary, non-background-session fetch here
    // we don't want it to take too long because the system will start to lose faith in us as a background fetcher and stop calling this as much
    // so we'll limit the fetch to BACKGROUND_FETCH_TIMEOUT seconds (also we won't use valuable cellular data)
    
    if (self.photoDatabaseContext) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration]; // because this was just [self startFlickrFetch] in lecture, the NSURLSessionConfiguration was called with backgroundSessionConfigurationWithIdentifier. That's why that was discretionary and background; ephemeral is non-discretionary, non-background.
        sessionConfig.allowsCellularAccess = NO;
        sessionConfig.timeoutIntervalForRequest = BACKGROUND_FLICKR_FETCH_TIMEOUT; // want to be a good background citizen!
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                        completionHandler:^(NSURL *localFile, NSURLResponse *response, NSError *error) {
                                                            if (error) {
                                                                NSLog(@"Flickr background fetch failed: %@", error.localizedDescription);
                                                                completionHandler(UIBackgroundFetchResultNoData);
                                                            }
                                                            else {
                                                                [self loadFlickrPhotosFromLocalURL:localFile
                                                                                       intoContext:self.photoDatabaseContext
                                                                               andThenExecuteBlock:^{
                                                                                   completionHandler(UIBackgroundFetchResultNewData);
                                                                               }
                                                                 ];
                                                            }
                                                        }];
        [task resume];
    }
    else {
        completionHandler(UIBackgroundFetchResultNoData); // no app-switcher update if no database!
    }
}

// this is called whenever a URL we have requested with a background session returns and we are in the background
// it is essentially waking us up to handle it
// if we were in the foreground iOS would just call our delegate method and not bother with this
// but this triggers the calling of that same delegate method (the didFinishDownloadingToURL one in our case)

// From the docs: The app calls this method when all background transfers associated with an NSURLSession object are done...Use this method to reconnect any URL sessions and to update your app’s user interface. For example, you might use this method to update progress indicators or to incorporate new content into your views. After processing the events, execute the block in the completionHandler parameter so that the app can take a new snapshot of your user interface.
-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    NSLog(@"handleEventsForBackgroundURLSession called");

    // this completionHandler, when called, will cause our UI to be re-cached in the app switcher
    // but we should not call this handler until we're done handling the URL whose results are now available
    // so we'll stash the completionHandler away in a property until we're ready to call it
    // (see flickrDownloadTasksMightBeComplete for when we actually call it)
    self.flickrDownloadBackgroundURLSessionCompletionHandler = completionHandler;
}

#pragma mark - Flickr Fetching

// this will probably not work (task = nil) if we're in the background, but that's okay
// (we do our background fetching in performFetchWithCompletionHandler:)
// it will always work when we are the foreground (active) application

- (void)startFlickrFetch
{
    NSLog(@"startFlickFetch called. App state: %d.", [[UIApplication sharedApplication] applicationState]);
    
    // getTasksWithCompletionHandler: is ASYNCHRONOUS
    // but that's okay because we're not expecting startFlickrFetch to do anything synchronously anyway
    [self.flickrDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        // let's see if we're already working on a fetch ...
        if (![downloadTasks count]) {
            // ... not working on a fetch, let's start one up
            NSURLSessionDownloadTask *task = [self.flickrDownloadSession downloadTaskWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
            task.taskDescription = FLICKR_FETCH;
            [task resume];
        }
        else {
            // ... we are working on a fetch (let's make sure it (they) is (are) running while we're here)
            for (NSURLSessionDownloadTask *task in downloadTasks) {
                [task resume];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshComplete" object:nil];
    }];

}

- (void)startFlickrFetchFromTimer:(NSTimer *)timer // NSTimer target/action always takes an NSTimer as an argument
{
    NSLog(@"startFlickrFetchFromTimer called. App state: %d.", [[UIApplication sharedApplication] applicationState]);
    [self startFlickrFetch];
}

- (void)startFlickrFetchFromNotification:(NSNotification *)notification // notification observer target selector always takes an NSNotification as an argument
{
    NSLog(@"startFlickrFetchFromNotification called. App state: %d.", [[UIApplication sharedApplication] applicationState]);
    [self startFlickrFetch];
}

// the getter for the flickrDownloadSession @property
- (NSURLSession *)flickrDownloadSession // the NSURLSession we will use to fetch Flickr data in the background
{
    NSLog(@"flickDownloadSession called");

    if (!_flickrDownloadSession) {
        static dispatch_once_t onceToken; // dispatch_once ensures that the block will only ever get executed once per application launch
        dispatch_once(&onceToken, ^{
            // notice the configuration here is "backgroundSessionConfiguration:"
            // that means that we will (eventually) get the results even if we are not the foreground application
            // even if our application crashed, it would get relaunched (eventually) to handle this URL's results!
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:FLICKR_FETCH];
            _flickrDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:self    // we MUST have a delegate for background configurations
                                                              delegateQueue:nil];   // nil means "a random, non-main-queue queue"
        });
    }
    return _flickrDownloadSession;
    
}

// the getter for the flickrRegionInfoDownloadTasks @property
- (NSURLSession *)flickrRegionInfoDownloadTasks // the NSURLSession we will use to fetch Flickr data in the background
{
    NSLog(@"flickrRegionInfoDownloadTasks called");
    
    if (!_flickrRegionInfoDownloadTasks) {
        static dispatch_once_t onceToken; // dispatch_once ensures that the block will only ever get executed once per application launch
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            _flickrRegionInfoDownloadTasks = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:nil
                                                              delegateQueue:nil]; // nil means "a random, non-main-queue queue"
        });
    }
    return _flickrRegionInfoDownloadTasks;
}

// standard "get photo information from Flickr URL" code

- (NSArray *)flickrPhotosAtURL:(NSURL *)url
{
    //NSLog(@"flickrPhotosAtURL called");
    
    NSDictionary *flickrPropertyList;
    NSData *flickrJSONData = [NSData dataWithContentsOfURL:url];  // will block if url is not local!
    if (flickrJSONData) {
         flickrPropertyList = [NSJSONSerialization JSONObjectWithData:flickrJSONData options:0 error:NULL];
    }
    NSArray *photos = [flickrPropertyList valueForKeyPath:FLICKR_RESULTS_PHOTOS];
    //NSLog(@"results: %@", flickrPropertyList);
    //NSLog(@"photos: %@", photos);
    return photos;
}


// gets the Flickr photo dictionaries out of the url and puts them into Core Data
// this was moved here after lecture to give you an example of how to declare a method that takes a block as an argument
// and because we now do this both as part of our background session delegate handler and when background fetch happens

- (void)loadFlickrPhotosFromLocalURL:(NSURL *)localFile
                         intoContext:(NSManagedObjectContext *)context
                 andThenExecuteBlock:(void(^)())whenDone
{
    //NSLog(@"loadFlickrPhotosFromLocalURL called");

    if (context) {
        NSArray *photos = [self flickrPhotosAtURL:localFile];
        [context performBlock:^{
            [Photo loadPhotosFromFlickrArray:photos intoManagedObjectContext:context withSession:self.flickrRegionInfoDownloadTasks];
            //[context save:NULL]; // NOT NECESSARY if this is a UIManagedDocument's context
            if (whenDone) whenDone();
        }];
    } else {
        if (whenDone) whenDone();
    }
}


#pragma mark - NSURLSessionDownloadDelegate

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)localFile
{
    NSLog(@"didFinishDownloadingToURL called");
    
    // we shouldn't assume we're the only downloading going on ...
    if ([downloadTask.taskDescription isEqualToString:FLICKR_FETCH]) {
        // ... but if this is the Flickr fetching, then process the returned data
        [self loadFlickrPhotosFromLocalURL:localFile
                               intoContext:self.photoDatabaseContext
                       andThenExecuteBlock:^{
                           [self flickrDownloadTasksMightBeComplete];
                       }
         ];
        
        /* FROM LECTURE; REMOVED IN POSTED CODE
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
         */
    }
}

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    // we don't support resuming an interrupted download task
}

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // we don't report the progress of a download in our UI, but this is a cool method to do that with
}

#pragma mark - NSURLSessionTaskDelegate

// not required by the protocol, but we should definitely catch errors here
// so that we can avoid crashes
// and also so that we can detect that download tasks are (might be) complete
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"didCompleteWithError called. App state: %d.", [[UIApplication sharedApplication] applicationState]);

    if (error && (session == self.flickrDownloadSession)) {
        NSLog(@"Flickr background download session failed: %@", error.localizedDescription);
        [self flickrDownloadTasksMightBeComplete];
    }
}

// this is "might" in case some day we have multiple downloads going on at once
- (void)flickrDownloadTasksMightBeComplete
{
    //NSLog(@"flickrDownloadTasksMightBeComplete called");
    
    if (self.flickrDownloadBackgroundURLSessionCompletionHandler) {
        [self.flickrDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            // we're doing this check for other downloads just to be theoretically "correct"
            //  but we don't actually need it (since we only ever fire off one download task at a time)
            // in addition, note that getTasksWithCompletionHandler: is ASYNCHRONOUS
            //  so we must check again when the block executes if the handler is still not nil
            //  (another thread might have sent it already in a multiple-tasks-at-once implementation)
            if (![downloadTasks count]) {  // any more Flickr downloads left?
                // nope, then invoke flickrDownloadBackgroundURLSessionCompletionHandler (if it's still not nil)
                void (^completionHandler)() = self.flickrDownloadBackgroundURLSessionCompletionHandler;
                self.flickrDownloadBackgroundURLSessionCompletionHandler = nil;
                if (completionHandler) {
                    NSLog(@"Called completionHandler()");
                    completionHandler();
                }
            } // else other downloads going, so let them call this method when they finish
        }];
    }
}

@end
