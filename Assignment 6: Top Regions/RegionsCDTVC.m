//
//  RegionsCDTVC.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/25/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "RegionsCDTVC.h"
#import "Region.h"
#import "PhotoDatabaseAvailability.h"

@interface RegionsCDTVC ()

@end

@implementation RegionsCDTVC

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserverForName:PhotoDatabaseAvailabilityNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *notification) {
                                                    self.managedObjectContext = notification.userInfo[PhotoDatabaseAvailabilityContext];
                                                }];
}


- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    _managedObjectContext = managedObjectContext;
    
    // whenever the managed object context is set, automatically query the database for all the regions
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"numberOfPhotographers"
                                                              ascending:FALSE]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Region Cell"];

    Region *region = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = region.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ photographers", region.numberOfPhotographers];
    
    return cell;
    
}


@end
