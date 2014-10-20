//
//  Photographer.h
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/10/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, Region;

@interface Photographer : NSManagedObject

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *regions;
@property (nonatomic, retain) NSSet *photos;
@end

@interface Photographer (CoreDataGeneratedAccessors)

- (void)addRegionsObject:(Region *)value;
- (void)removeRegionsObject:(Region *)value;
- (void)addRegions:(NSSet *)values;
- (void)removeRegions:(NSSet *)values;

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
