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
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@end


@implementation RegionsCDTVC

- (void)awakeFromNib
{
    self.title = @"Popular Regions";
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PhotoDatabaseAvailabilityNotification
                object:nil
                 queue:nil
            usingBlock:^(NSNotification *notification) {
                self.managedObjectContext = notification.userInfo[PhotoDatabaseAvailabilityContext];
            }];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"refreshComplete" object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"refresh complete");
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
    }];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // when on screen, add an observer to receive notifications from the managed object context that it saved, and react by calling performFetch, which forces adherence to the fetchLimit so that only that amount of rows are displayed in the table.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextChanged:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.managedObjectContext];
    
}

// remove the observer if we're not on screen.
- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:self.managedObjectContext];
    [super viewWillDisappear:animated];
}

// performFetch forces adherence to the fetchLimit so that only that amount of rows are displayed in the table.
- (void)contextChanged:(NSNotification *)notification
{
    [self performFetch];
}

// because we want the action taken upon a user refresh to be a method of the AppDelegate, we need to use a notification. to respect MVC, we don't want the table view controller to know about the AppDelegate.
- (IBAction)userRefresh {
    NSLog(@"called userRefresh");
    [self.refreshControl beginRefreshing];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userRefresh" object:nil];
}


- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    // whenever the managed object context is set, automatically query the database for all the regions
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
    request.predicate = nil;
    request.fetchLimit = 10;
    NSSortDescriptor *numberOfPhotographers = [NSSortDescriptor sortDescriptorWithKey:@"numberOfPhotographers" ascending:FALSE];
    NSSortDescriptor *placeName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE];
    request.sortDescriptors = @[numberOfPhotographers, placeName];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Region Cell"];
    Region *region = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = region.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ photographers", region.numberOfPhotographers];
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Display Photo"]) {
        
        if ([segue.destinationViewController isKindOfClass:[PhotosCDTVC class]]) {
            
            PhotosCDTVC *tvc = (PhotosCDTVC *)segue.destinationViewController;
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            if (indexPath) {

                // get the region name from the selected cell
                Region *region = [self.fetchedResultsController objectAtIndexPath:indexPath];

                // fetch the corresponding Region managed object and send to the segued-to TVC
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
                request.predicate = [NSPredicate predicateWithFormat:@"name = %@", region.name];
                NSError *error;
                NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
                
                if (!matches || error || [matches count] != 1) {
                    // either the fetch request returned nil or reported an error or there were either 0 or 1+ matches, which is itself a logic error. need error handling here therefore.
                    NSLog(@"ERROR");
                }
                else {
                    tvc.region = (Region *)[matches firstObject];
                }
            }
        }
    }
}

@end
