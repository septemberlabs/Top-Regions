//
//  ModelDebugger.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/30/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "ModelDebugger.h"

@implementation ModelDebugger

+ (void)viewContentsOfModel:(NSManagedObjectModel *)model inContext:(NSManagedObjectContext *)context {
    NSLog(@"---------------------------------");
    // loop through all the entities, viewing the records of that entity
    for (NSEntityDescription *entity in model) {
        [self viewRecordsOfEntity:entity inContext:context];
    }
}

+ (void)viewRecordsOfEntity:(NSEntityDescription *)entity inContext:(NSManagedObjectContext *)context {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity.name];
    //[fetchRequest setResultType:NSDictionaryResultType];
    //[fetchRequest setIncludesPendingChanges:NO];
    //[fetchRequest setIncludesPropertyValues:NO];
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    else {

        // loop through every object returned of that entity
        for (NSManagedObject *result in fetchedObjects) {
            NSString *debugOutput = [NSString stringWithFormat:@"%@: |", [[entity name] uppercaseString]];
            // loop through every property of that entity
            for (NSPropertyDescription *entityProperty in [entity properties]) {
                if ([entityProperty isMemberOfClass:[NSAttributeDescription class]]) {
                    debugOutput = [debugOutput stringByAppendingFormat:@" %@: %@ |", [entityProperty name], [result valueForKey:[entityProperty name]]];
                }
                else if ([entityProperty isMemberOfClass:[NSRelationshipDescription class]]) {
                    if ([result valueForKey:[entityProperty name]] == NULL) {
                        debugOutput = [debugOutput stringByAppendingFormat:@" %@: %@ |", [entityProperty name], [result valueForKey:[entityProperty name]]];
                    }
                    else {
                        debugOutput = [debugOutput stringByAppendingFormat:@" %@: is set |", [entityProperty name]];
                    }
                }
                else {
                    // result is NSFetchedPropertyDescription.
                }
                
                // HERE. DISPLAY DIFFERENTLY by testing if object is NSAttributeDescription or NSRelationshipDescription or NSFetchedPropertyDescription.
                
                
            }
            NSLog(@"%@", debugOutput);
        }
    }
    
}

@end
