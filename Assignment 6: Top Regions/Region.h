//
//  Region.h
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/4/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, Photographer;

@interface Region : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * numberOfPhotographers;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *photographers;
@end

@interface Region (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

- (void)addPhotographersObject:(Photographer *)value;
- (void)removePhotographersObject:(Photographer *)value;
- (void)addPhotographers:(NSSet *)values;
- (void)removePhotographers:(NSSet *)values;

@end
