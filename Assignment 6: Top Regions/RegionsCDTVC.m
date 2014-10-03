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
#import "PhotosCDTVC.h"

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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"Display Photo"]) {
        
        if ([segue.destinationViewController isKindOfClass:[PhotosCDTVC class]]) {
            
            PhotosCDTVC *tvc = (PhotosCDTVC *)segue.destinationViewController;
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            if (indexPath) {

                // get the region name from the selected cell
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                NSString *regionName = cell.textLabel.text;

                // fetch the corresponding Region managed object and send to the segued-to TVC
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
                request.predicate = [NSPredicate predicateWithFormat:@"name = %@", regionName];
                NSError *error;
                NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
                
                if (!matches || error || [matches count] != 1) {
                    // either the fetch request returned nil or reported an error or there were either 0 or 1+ matches, which is itself a logic error. need error handling here therefore.
                }
                else {
                    tvc.region = (Region *)[matches firstObject];
                }
                
            }
            
        }
        
    }
    
}

@end
