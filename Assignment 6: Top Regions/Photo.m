//
//  Photo.m
//  Assignment 6: Top Regions
//
//  Created by Will Smith on 10/2/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "Photo.h"
#import "Region.h"


@implementation Photo

@dynamic id;
@dynamic thumbnail;
@dynamic owner;
@dynamic title;
@dynamic dateUploaded;
@dynamic originallyStored;
@dynamic region;

- (void) awakeFromInsert
{
    [super awakeFromInsert];
    [self setOriginallyStored:[NSDate date]];
}

@end
