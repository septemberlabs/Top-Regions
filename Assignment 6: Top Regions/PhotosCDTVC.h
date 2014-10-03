//
//  PhotosCDTVC.h
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/2/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "CoreDataTableViewController.h"
#import "Region.h"
#import "Photo.h"

@interface PhotosCDTVC : CoreDataTableViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Region *region;

@end
