//
//  Photo.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/10/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "Photo.h"
#import "Photographer.h"
#import "Region.h"


@implementation Photo

@dynamic id;
@dynamic imageURL;
@dynamic originallyStored;
@dynamic owner;
@dynamic thumbnail;
@dynamic thumbnailURL;
@dynamic title;
@dynamic dateUploaded;
@dynamic region;
@dynamic photographer;

- (void) awakeFromInsert
{
    [super awakeFromInsert];
    [self setOriginallyStored:[NSDate date]];
}

@end