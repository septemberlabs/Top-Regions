//
//  Region+Create.h
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/25/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "Region.h"
#import "Photographer.h"

@interface Region (Create)

+ (Region *)regionWithName:(NSString *)name withPhotographer:(Photographer *)photographer inManagedObjectContext:(NSManagedObjectContext *)context;

@end
