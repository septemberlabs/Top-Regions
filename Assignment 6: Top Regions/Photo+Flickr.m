//
//  Photo+Flickr.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/21/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "Photo+Flickr.h"
#import "Region+Create.h"
#import "FlickrFetcher.h"
#import "ModelDebugger.h"
#import "Photographer.h"

@implementation Photo (Flickr)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)flickrPhotoDictionary inManagedObjectContext:(NSManagedObjectContext *)context withSession:(NSURLSession *)session {
    
    Photo *photo = nil;
    
    // determine whether the photo already exists by searching with its flickr_id
    NSString *flickr_id = [flickrPhotoDictionary valueForKeyPath:FLICKR_PHOTO_ID];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"id = %@", flickr_id];
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || [matches count] > 1) {
        // either the fetch request returned nil or reported an error or there were multiple matches, which is itself a logic error
        NSLog(@"ERROR");
    }
    else if ([matches count]) {
        // exists
        photo = [matches firstObject];
    }
    else {
        
        // create the photo, along with the accompanying region if it doesn't already exist
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        photo.id = flickr_id;
        photo.title = [flickrPhotoDictionary valueForKeyPath:FLICKR_PHOTO_TITLE];
        photo.owner = [flickrPhotoDictionary valueForKeyPath:FLICKR_PHOTO_OWNER];
        NSString *flickrDateUploaded = [flickrPhotoDictionary valueForKeyPath:FLICKR_PHOTO_UPLOAD_DATE];
        photo.dateUploaded = [NSDate dateWithTimeIntervalSince1970:flickrDateUploaded.doubleValue];
        photo.thumbnailURL = [[FlickrFetcher URLforPhoto:flickrPhotoDictionary format:FlickrPhotoFormatSquare] absoluteString];
        photo.imageURL = [[FlickrFetcher URLforPhoto:flickrPhotoDictionary format:FlickrPhotoFormatLarge] absoluteString];
        
        // determine whether the photographer already exists by searching with the photo's owner string
        Photographer *photographer;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
        request.predicate = [NSPredicate predicateWithFormat:@"username = %@", photo.owner];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        if (!matches || error || [matches count] > 1) {
            // either the fetch request returned nil or reported an error or there were multiple matches, which is itself a logic error
            NSLog(@"ERROR");
        }
        else if ([matches count]) {
            // exists
            photographer = [matches firstObject];
        }
        else {
            // doesn't exist, create it
            photographer = [NSEntityDescription insertNewObjectForEntityForName:@"Photographer" inManagedObjectContext:context];
            photographer.username = photo.owner;
        }
        // point the photo and photographer at each other
        photo.photographer = photographer;
        
        // get the region info about the photo
        //NSLog(@"%@", flickrPhotoDictionary);
        NSString *place_id = [flickrPhotoDictionary objectForKey:FLICKR_PHOTO_PLACE_ID];

        /*
         Instead of the following, decided to use a single session to managed these many download tasks. The session exists as a property of AppDelegate.
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        //NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
         */
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[FlickrFetcher URLforInformationAboutPlace:place_id]];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:urlRequest
            completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                if (!error) {
                    NSData *jsonData = [NSData dataWithContentsOfURL:localfile];
                    error = nil;
                    NSDictionary *placeInfo = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
                    //NSDictionary *regionInfo = [placeInfo valueForKeyPath:@"place.region"];
                    NSString *regionName = [FlickrFetcher extractRegionNameFromPlaceInformation:placeInfo];
                    photo.region = [Region regionWithName:regionName withPhotographer:photographer inManagedObjectContext:context]; // connect the photo and region (either new or existing)
                    //NSLog(@"%@", placeInfo);
                    //NSLog(@"%@", regionInfo);
                    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
                        NSLog(@"current tasks: %d", [downloadTasks count]);
                        if (![downloadTasks count]) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadsComplete" object:nil];
                        }
                    }];
                }
            }];
        [task resume];
    }
    
    return photo;
    
}

+ (void)loadPhotosFromFlickrArray:(NSArray *)photos intoManagedObjectContext:(NSManagedObjectContext *)context withSession:(NSURLSession *)session
{
    for (NSDictionary *photo in photos) {
        [self photoWithFlickrInfo:photo inManagedObjectContext:context withSession:session];
    }
}

@end
