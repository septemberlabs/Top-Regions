//
//  PhotosCDTVC.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/2/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "PhotosCDTVC.h"
#import "ImageViewController.h"

@interface PhotosCDTVC ()

@end

@implementation PhotosCDTVC

- (void)setRegion:(Region *)region {
    
    _region = region;
    _managedObjectContext = region.managedObjectContext;

    // whenever the region is set, which only happens when a user selects it in RegionsCDTVC, automatically query the database for all the photos
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"region = %@", self.region];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateUploaded" ascending:FALSE]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Photo Cell"];
    
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = photo.title;
    //cell.detailTextLabel.text = [NSString stringWithFormat:@"Taken %@", [NSDateFormatter localizedStringFromDate:photo.dateUploaded dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterLongStyle]];
    cell.detailTextLabel.text = photo.id;
    
    // if the thumbnail data exists display it immediately. if not, add a block off the main queue to go grab and store it.
    if (photo.thumbnail != nil) {
        cell.imageView.image = [UIImage imageWithData:photo.thumbnail];
    }
    else {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.thumbnailURL]];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        //NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                    if (!error) {
                        //NSLog(@"request.URL: %@", [request.URL absoluteString]);
                        //NSLog(@"photo.thumbnailURL: %@", photo.thumbnailURL);
                        photo.thumbnail = [NSData dataWithContentsOfURL:localfile];
                    }
                }];
        [task resume];
    }

    return cell;

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"Flickr Photo"]) {
        if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
            ImageViewController *ivc = (ImageViewController *)segue.destinationViewController;
            Photo *photo = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
            ivc.imageURL = [NSURL URLWithString:photo.imageURL];
            [ivc setTitle:photo.title];
        }
    }
    
}

@end
