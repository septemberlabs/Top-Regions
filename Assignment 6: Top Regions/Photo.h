//
//  Photo.h
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/3/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Region;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSDate * dateUploaded;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSDate * originallyStored;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) Region *region;

@end
