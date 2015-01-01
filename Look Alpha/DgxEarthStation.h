//
//  DgxEarthStation.h
//  Look Alpha
//
//  Created by Allen Snook on 1/1/15.
//  Copyright (c) 2015 Designgeneers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "DgxSpaceConstants.h"

@interface DgxEarthStation : NSObject

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) double altitude;

/*
 * Returns the look angle from the earth station given the satellite latitude and longitude in
 * degrees and altitude in meters
 */

- (DgxLookAngle)getLookAngleForSatelliteAt:(DgxGeoCoordinates)satelliteCoordinates;

@end
