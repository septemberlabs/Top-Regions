//
//  Region+Create.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/25/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "Region+Create.h"

@implementation Region (Create)

+ (Region *)regionWithName:(NSString *)name withPhotographer:(Photographer *)photographer inManagedObjectContext:(NSManagedObjectContext *)context {
    
    Region *region = nil;
    
    // determine whether the region already exists by searching with its name
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
    request.predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || [matches count] > 1) {
        // either the fetch request returned nil or reported an error or there were multiple matches, which is itself a logic error
    }
    else if ([matches count]) {
        // exists
        region = [matches firstObject];
    }
    else {
        // doesn't exist, create it
        region = [NSEntityDescription insertNewObjectForEntityForName:@"Region" inManagedObjectContext:context];
        region.name = name;
    }

    // if the photographer doesn't yet exist in the region, add it and increment the counter
    if (![region.photographers containsObject:photographer]) {
        [region addPhotographersObject:photographer];
        int currentNumberOfPhotographers = [region.numberOfPhotographers intValue];
        region.numberOfPhotographers = [NSNumber numberWithInt:(currentNumberOfPhotographers + 1)];
    }
    
    return region;
    
}

@end
