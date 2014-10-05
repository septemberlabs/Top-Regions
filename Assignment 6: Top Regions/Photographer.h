//
//  Photographer.h
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/4/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Region;

@interface Photographer : NSManagedObject

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) Region *regions;

@end
