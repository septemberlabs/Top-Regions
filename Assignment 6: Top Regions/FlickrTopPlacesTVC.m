//
//  FlickrTopPlacesTVC.m
//  Assignment 5
//
//  Created by Will Smith on 7/8/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "FlickrTopPlacesTVC.h"
#import "FlickrFetcher.h"
#import "FlickrPhotosByPlaceTVC.h"

@interface FlickrTopPlacesTVC ()
@property (nonatomic, strong) NSMutableDictionary *places;
@property (nonatomic, strong) NSArray *sortedCountriesList;
@property (nonatomic, strong) NSMutableDictionary *sortedCitiesList;
@end

@implementation FlickrTopPlacesTVC

#pragma mark - Setup

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self fetchPlaces];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Lazy instantiation

- (NSMutableDictionary *)places {
    if (!_places) _places = [[NSMutableDictionary alloc] init];
    return _places;
}

- (NSMutableDictionary *)sortedCitiesList {
    if (!_sortedCitiesList) _sortedCitiesList = [[NSMutableDictionary alloc] init];
    return _sortedCitiesList;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return [self.places count];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    NSDictionary *country = [self.places objectForKey:self.sortedCountriesList[section]];
    return [country count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"Flickr Place";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSString *countryName = self.sortedCountriesList[indexPath.section];
    NSArray *citiesInCountry = [self.sortedCitiesList objectForKey:countryName];
    NSString *cityName = citiesInCountry[indexPath.row];
    // [self.places objectForKey:countryName] returns an array of dictionaries, each corresponding to a city. indexPath.row indexes to the particular city.
    NSString *regionName = [[self.places objectForKey:countryName][indexPath.row] objectForKey:@"region"];
    
    cell.textLabel.text = cityName;
    cell.detailTextLabel.text = regionName;
    
    return cell;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sortedCountriesList[section];
}

#pragma mark - Get data

- (IBAction)fetchPlaces {
    
    [self.refreshControl beginRefreshing];
    dispatch_queue_t flickrFetchQueue;
    flickrFetchQueue = dispatch_queue_create("flickr fetch queue", NULL);
    //dispatch_async(flickrFetchQueue, ^{
    NSData *jsonData = [NSData dataWithContentsOfURL:[FlickrFetcher URLforTopPlaces]];
    NSError *error = nil;
    NSDictionary *placesListResults = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:0
                                                                        error:&error];
    NSArray *places = [placesListResults valueForKeyPath:FLICKR_RESULTS_PLACES];
    //NSLog(@"places: %@", places);
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
    
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"Flickr Top Place"]) {
        if ([segue.destinationViewController isKindOfClass:[FlickrPhotosTVC class]]) {
            FlickrPhotosByPlaceTVC *tvc = (FlickrPhotosByPlaceTVC *)segue.destinationViewController;
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            if (indexPath) {
                NSString *countryName = self.sortedCountriesList[indexPath.section];
                // [self.places objectForKey:countryName] returns an array of dictionaries, each corresponding to a city. indexPath.row indexes to the particular city.
                tvc.placeID = [[self.places objectForKey:countryName][indexPath.row] objectForKey:@"place_id"];
            }
        }
    }
    
}

@end
