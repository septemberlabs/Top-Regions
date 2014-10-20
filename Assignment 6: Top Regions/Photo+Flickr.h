//
//  Photo+Flickr.h
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/21/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "Photo.h"

@interface Photo (Flickr)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)flickrPhotoDictionary inManagedObjectContext:(NSManagedObjectContext *)context withSession:(NSURLSession *)session;

+ (void)loadPhotosFromFlickrArray:(NSArray *)photos // of Flickr NSDictionary
         intoManagedObjectContext:(NSManagedObjectContext *)context
                      withSession:session;

@end
