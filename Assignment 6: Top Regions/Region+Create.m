//
//  Region+Create.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/25/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "Region+Create.h"

@implementation Region (Create)

+ (Region *)regionWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context {
    
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
        //region.numberOfPhotographers = 0;
        //NSLog(@"here");
    }
    
    return region;
    
}

@end
