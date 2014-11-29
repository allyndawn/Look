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

@property (nonatomic) DgxSatellite* satellite;
@property (nonatomic, readwrite) NSMutableArray* subsatellitePoints;

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
    // TODO: Read these directly from a source like http://www.celestrak.com/NORAD/elements/visual.txt
    
    DgxTwoLineElementSet *issTLE = [[DgxTwoLineElementSet alloc]
                                    initWithName:@"ISS (ZARYA)"
                                    andLineOne:@"1 25544U 98067A   14333.22994814  .00018276  00000-0  30924-3 0  4779"
                                    andLineTwo:@"2 25544  51.6479   1.3035 0007327  78.8730  39.5933 15.51601234916936"];
    
    self.satellite = [[DgxSatellite alloc] initWithTwoLineElementSet:issTLE];
}

- (void)updateSubsatellitePoints
{
    if (! self.subsatellitePoints) {
        MKPointAnnotation *subsatellitePoint = [[MKPointAnnotation alloc] init];
        subsatellitePoint.coordinate = [self.satellite getSubsatellitePointNow];
        subsatellitePoint.title = self.satellite.twoLineElementSet.nameOfSatellite;
        
        self.subsatellitePoints = [[NSMutableArray alloc] initWithObjects:subsatellitePoint, nil];
    } else {
        // just update the coordinates based on the current time
        
        for ( MKPointAnnotation *pointAnnotation in self.subsatellitePoints ) {
            pointAnnotation.coordinate = [self.satellite getSubsatellitePointNow];
        }
    }
}

@end
