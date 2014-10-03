//
//  Photo.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/3/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "Photo.h"
#import "Region.h"


@implementation Photo

@dynamic dateUploaded;
@dynamic id;
@dynamic originallyStored;
@dynamic owner;
@dynamic thumbnail;
@dynamic title;
@dynamic thumbnailURL;
@dynamic imageURL;
@dynamic region;

- (void) awakeFromInsert
{
    [super awakeFromInsert];
    [self setOriginallyStored:[NSDate date]];
}

@end
