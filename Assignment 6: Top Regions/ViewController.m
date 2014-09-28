//
//  ViewController.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 9/12/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "ViewController.h"
#import "FlickrFetcher.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self grabData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Get data

- (void)grabData {
    
    // get list of 250 recently georeferenced photos
    // loop through the photos, using the place_id to get the region info for each. also add each photo to the database.
    // there's a dictionary of regions. each entry is an array of photographers (text).
    // if the region exists in the dictionary, check if the photographer exists in the array. if so, don't add to the array. if not, add to the array.
    // if the region doesn't exist in the dictionary, add it, which a single-item array containing that photographer
    // now we have a dictionary with all the regions and quantity and names of photographers
    
    NSData *jsonData = [NSData dataWithContentsOfURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
    NSError *error = nil;
    NSDictionary *fetcherResults = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:0
                                                                     error:&error];
    NSArray *photos = [fetcherResults valueForKeyPath:FLICKR_RESULTS_PHOTOS];
    //NSLog(@"results: %@", fetcherResults);
    //NSLog(@"photos: %@", photos);
    
    NSMutableDictionary *regions = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary *photoInfo in photos) {
        
        // get necessary items about the photo
        NSString *place_id = [photoInfo objectForKey:@"place_id"];
        NSString *photographer_id = [photoInfo objectForKey:@"owner"];

        // get the region info about the photo
        NSData *jsonData = [NSData dataWithContentsOfURL:[FlickrFetcher URLforInformationAboutPlace:place_id]];
        NSError *error = nil;
        NSDictionary *placeInfo = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                       options:0
                                                                         error:&error];
        NSDictionary *regionInfo = [placeInfo valueForKeyPath:@"place.region"];
        NSString *region_place_id = [regionInfo objectForKey:@"place_id"];

        NSLog(@"results: %@", placeInfo);
        NSLog(@"place_id: %@", place_id);
        NSLog(@"region: %@", regionInfo);
        
        if ([regions objectForKey:region_place_id] != nil) {
            // a photographer in the region has already been counted. see if the current photog is him. if not, add the current photog.
            NSMutableArray *photographers = [regions objectForKey:region_place_id];
            if (![photographers containsObject:photographer_id]) {
                [photographers addObject:photographer_id];
            }
        }
        else {
            // a photographer in the region has not been counted. initialize the photographer array with this photog.
            NSMutableArray *photographers = [[NSMutableArray alloc] init];
            [photographers addObject:photographer_id];
            [regions setValue:photographers forKey:region_place_id];
        }
        NSLog(@"here");

    }
    
}

- (IBAction)fetchPlaces {
    
    /*
    dispatch_queue_t flickrFetchQueue;
    flickrFetchQueue = dispatch_queue_create("flickr fetch queue", NULL);
    //dispatch_async(flickrFetchQueue, ^{
    NSData *jsonData = [NSData dataWithContentsOfURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
    NSError *error = nil;
    NSDictionary *fetcherResults = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:0
                                                                     error:&error];
    NSLog(@"results: %@", fetcherResults);
    
    //NSArray *places = [fetcherResults valueForKeyPath:FLICKR_RESULTS_PLACES];
    //NSLog(@"places: %@", places);
     
     */
    
    /*
    for (NSDictionary *placeInfo in places) {
        
        NSString *place_id = [placeInfo objectForKey:@"place_id"];
        NSString *placeNamesAsString = [placeInfo objectForKey:@"_content"];
        
        /// placeNames[0] is city, placeNames[1] is region/state/province ("region" from now on), placeNames[2] is country
        NSMutableArray *placeNames = [NSMutableArray arrayWithArray:[placeNamesAsString componentsSeparatedByString:@", "]];
        
        // When there is no region/state/province specified (eg Vatican City), we add an empty field for that field.
        if ([placeNames count] < 3) [placeNames insertObject:@"" atIndex:1];
        
        NSMutableArray *country = [self.places objectForKey:placeNames[2]];
        // if an entry doesn't yet exist for this country, add it.
        if (!country) {
            [self.places setObject:[[NSMutableArray alloc] init] forKey:placeNames[2]];
            country = [self.places objectForKey:placeNames[2]];
        }
        
        // add a new key/value in the country's dictionary. key is the city, value is the region/state/province.
        //[country setValue:[NSString stringwithFormat:@"%@ - %d", placeNames[1], ] forKey:placeNames[0]];
        //[country setValue:placeNames[1] forKey:placeNames[0]];
        NSDictionary *newPlace = [[NSDictionary alloc] initWithObjectsAndKeys:placeNames[0], @"city", placeNames[1], @"region", place_id, @"place_id", nil];
        [country addObject:newPlace];
        
    }
    
    // maintain an alphabetically ordered array of the country and city names for indexing against indexPath.
    self.sortedCountriesList = [[self.places allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.places enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSMutableArray *cityNames = [[NSMutableArray alloc] init];
        for (int i = 0; i < [obj count]; i++) [cityNames addObject:[obj[i] valueForKey:@"city"]];
        NSArray *sortedCities = [cityNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        [self.sortedCitiesList setValue:sortedCities forKey:key];
    }];
    
    [self.refreshControl endRefreshing];
    //});
     */
    
}

@end
