//
//  DgxEarthStation.m
//  Look Alpha
//
//  Created by Allen Snook on 1/1/15.
//  Copyright (c) 2015 Designgeneers. All rights reserved.
//

#import "DgxEarthStation.h"

@implementation DgxEarthStation

- (id)init
{
    if (self = [super init]) {
        _altitude = 0.;
        _coordinate.latitude = 0.;
        _coordinate.longitude = 0.;
    }
    return self;
}

- (DgxLookAngle)getLookAngleForSatelliteAt:(DgxGeoCoordinates)satelliteCoordinates
{
    DgxLookAngle lookAngle;
    
    double latitudeRad = self.coordinate.latitude * M_PI / 180.;
    double longitudeRad = self.coordinate.longitude * M_PI / 180.;
    
    double satelliteLatitudeRad = satelliteCoordinates.latitude * M_PI / 180.;
    double satelliteLongitudeRad = satelliteCoordinates.longitude * M_PI / 180.;
    
    // calculate gamma, the angle between the earth station, the center of the earth, and the subsatellite point
    
    double gamma = acos(sin(satelliteLatitudeRad)*sin(latitudeRad) + cos(satelliteLatitudeRad)*cos(latitudeRad)*cos(satelliteLongitudeRad - longitudeRad));
    
    double radiusRatio = (self.altitude + 6370.) / (satelliteCoordinates.altitude + 6370.);
    
    double elevationRad = acos(sin(gamma)/sqrt(1 + radiusRatio*radiusRatio - 2*radiusRatio*cos(gamma)));
    
    // calculate alpha, the azimuth angle (but we'll need to tweak it a bit before we can use it)
    
    double alpha = asin(sin(fabs(longitudeRad - satelliteLongitudeRad)) * cos(satelliteLatitudeRad) / gamma);
    
    // TODO: Test at Greenwich, east of Greenwich, south of the equator
    double azimuthRad = 0.;
    if (satelliteLatitudeRad > latitudeRad) // satellite is North of earth station
    {
        if (satelliteLongitudeRad > longitudeRad) // satellite is East of us
        {
            azimuthRad = alpha;
        } else { // satellite is West of us
            azimuthRad = 2 * M_PI - alpha;
        }
    } else { // satellite is South of earth station
        if (satelliteLongitudeRad > longitudeRad) // satellite is East of us
        {
            azimuthRad = M_PI - alpha;
        } else { // satellite is West of us
            azimuthRad = M_PI + alpha;
        }
    }
    
    lookAngle.elevation = elevationRad * 180. / M_PI;
    lookAngle.azimuth = azimuthRad * 180. / M_PI;
    
    return lookAngle;
}

@end
