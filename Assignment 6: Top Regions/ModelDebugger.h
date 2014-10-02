//
//  ModelDebugger.h
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/30/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ModelDebugger : NSObject

@property (nonatomic, strong) NSManagedObjectContext *context;

+ (void)viewContentsOfModel:(NSManagedObjectModel *)model inContext:(NSManagedObjectContext *)context;
+ (void)viewRecordsOfEntity:(NSEntityDescription *)entity inContext:(NSManagedObjectContext *)context;

@end
