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

@implementation Photo (Flickr)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)flickrPhotoDictionary inManagedObjectContext:(NSManagedObjectContext *)context {
    
    Photo *photo = nil;
    
    // determine whether the photo already exists by searching with its flickr_id
    NSString *flickr_id = flickrPhotoDictionary[FLICKR_PHOTO_ID];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"id = %d", flickr_id];
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || [matches count] > 1) {
        // either the fetch request returned nil or reported an error or there were multiple matches, which is itself a logic error
    }
    else if ([matches count]) {
        // exists
        photo = [matches firstObject];
    }
    else {
        
        // create the photo, along with the accompanying region if it doesn't already exist
        
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        //[ModelDebugger viewRecordsOfEntity:photo.entity inContext:context];
        
        photo.id = flickr_id;
        //[ModelDebugger viewRecordsOfEntity:photo.entity inContext:context];

        // get the region info about the photo
        NSString *place_id = [flickrPhotoDictionary objectForKey:@"place_id"];
        NSData *jsonData = [NSData dataWithContentsOfURL:[FlickrFetcher URLforInformationAboutPlace:place_id]];
        NSError *error = nil;
        NSDictionary *placeInfo = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                  options:0
                                                                    error:&error];
        //NSDictionary *regionInfo = [placeInfo valueForKeyPath:@"place.region"];
        //NSString *regionName = [regionInfo objectForKey:@"_content"];
        NSString *regionName = [FlickrFetcher extractRegionNameFromPlaceInformation:placeInfo];
        
        photo.region = [Region regionWithName:regionName inManagedObjectContext:context];
        int currentNumberOfPhotographers = [photo.region.numberOfPhotographers intValue];
        photo.region.numberOfPhotographers = [NSNumber numberWithInt:(currentNumberOfPhotographers + 1)];

        //[ModelDebugger viewRecordsOfEntity:photo.region.entity inContext:context];
        
        //[ModelDebugger viewContentsOfModel:[photo.entity managedObjectModel] inContext:context];

    }
    
    return photo;
    
}

+ (void)loadPhotosFromFlickrArray:(NSArray *)photos intoManagedObjectContext:(NSManagedObjectContext *)context {
    for (NSDictionary *photo in photos) {
        [self photoWithFlickrInfo:photo inManagedObjectContext:context];
    }
}

@end
