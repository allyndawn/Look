//
//  DgxSatellites.m
//  Look Alpha
//
//  Created by Allen Snook on 11/23/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import "DgxSatellites.h"
#import "DgxSatellite.h"
#import <MapKit/MapKit.h>

@interface DgxSatellites()

@property (nonatomic) NSArray* satellites;

@end

@implementation DgxSatellites

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadSatellites];
        [self updateSubsatellitePoints];
    }
    return self;
}

- (void)loadSatellites
{
    DgxTwoLineElementSet *issTLE = [[DgxTwoLineElementSet alloc]
                                    initWithName:@"ISS (ZARYA)"
                                    andLineOne:@"1 25544U 98067A   14333.22994814  .00018276  00000-0  30924-3 0  4779"
                                    andLineTwo:@"2 25544  51.6479   1.3035 0007327  78.8730  39.5933 15.51601234916936"];

    self.satellites = [[NSArray alloc] initWithObjects:[[DgxSatellite alloc] initWithTwoLineElementSet:issTLE], nil];
    
    // TODO: Read these directly from a source like http://www.celestrak.com/NORAD/elements/visual.txt
}

- (void)updateSubsatellitePoints
{
    for (long i=0; i<self.satellites.count; i++) {
        [self.satellites[i] updateSubsatellitePoint];
    }
}

@end
