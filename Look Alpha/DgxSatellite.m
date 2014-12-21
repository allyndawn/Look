//
//  DgxSatellite.m
//  Look Alpha
//
//  Created by Allen Snook on 11/23/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import "DgxSatellite.h"
#import "DgxJulianMath.h"

@implementation DgxSatellite

- (instancetype)init
{
    return [self initWithTwoLineElementSet:nil];
}

- (instancetype)initWithTwoLineElementSet:(DgxTwoLineElementSet *)twoLineElementSet
{
    self = [super init];
    if (self) {
        if (twoLineElementSet) {
            _twoLineElementSet = twoLineElementSet;
            _name = twoLineElementSet.nameOfSatellite;
            _cosparID = twoLineElementSet.cosparID;
            _satCatNumber = twoLineElementSet.satcatNumber;
        } else {
            _twoLineElementSet = [[DgxTwoLineElementSet alloc] init];
            _name = @"";
        }
        
        _subsatellitePoint = CLLocationCoordinate2DMake(0., 0.);
        
        [self updateSubsatellitePoint];
    }
    
    return self;
}

- (void)updateSubsatellitePoint
{    
    CLLocationDegrees ssLat = 0;
    CLLocationDegrees ssLong = 0;
    
    long currentDate = [DgxJulianMath getSecondsSinceReferenceDate];    
    double currentJulianDate = [DgxJulianMath getJulianDateFromSecondsSinceReferenceDate:currentDate];
    double semimajorAxis = self.twoLineElementSet.getSemimajorAxis; // kilometers
    double currentMeanAnomaly = [self.twoLineElementSet getMeanAnomalyForJulianDate:currentJulianDate];

    // Use the current Mean Anomaly to get the current Eccentric Anomaly
    double currentEccentricAnomaly = [self.twoLineElementSet getEccentricAnomalyForMeanAnomaly:currentMeanAnomaly];

    // Use the current Eccentric Anomaly to get the currentTrueAnomaly
    double currentTrueAnomaly = [self.twoLineElementSet getTrueAnomalyForEccentricAnomaly:currentEccentricAnomaly];

    // Solve for r0 : the distance from the satellite to the Earth's center
    double currentOrbitalRadius = semimajorAxis - semimajorAxis * self.twoLineElementSet.eccentricity * cos(currentEccentricAnomaly * M_PI / 180.);

    // Solve for the x and y position in the orbital plane
    double orbitalX = currentOrbitalRadius * cos(currentTrueAnomaly * M_PI / 180.);
    double orbitalY = currentOrbitalRadius * sin(currentTrueAnomaly * M_PI / 180.);
            
    // TODO: Pertubations / higher order TLE terms
    
    // Rotation math ased on https://www.csun.edu/~hcmth017/master/node20.html
    
    // First, rotate around the z''' axis by the Argument of Perigee: ⍵
    double cosArgPerigee = cos(self.twoLineElementSet.argumentOfPerigee * M_PI / 180.);
    double sinArgPerigee = sin(self.twoLineElementSet.argumentOfPerigee * M_PI / 180.);    
    double orbitalXbyPerigee = cosArgPerigee * orbitalX - sinArgPerigee * orbitalY;
    double orbitalYbyPerigee = sinArgPerigee * orbitalX + cosArgPerigee * orbitalY;
    double orbitalZbyPerigee = 0.;
    
    // Next, rotate around the x'' axis by inclincation
    double cosInclination = cos(self.twoLineElementSet.inclination * M_PI / 180.);
    double sinInclination = sin(self.twoLineElementSet.inclination * M_PI / 180.);    
    double orbitalXbyInclination = orbitalXbyPerigee;
    double orbitalYbyInclination = cosInclination * orbitalYbyPerigee - sinInclination * orbitalZbyPerigee;
    double orbitalZbyInclination = sinInclination * orbitalYbyPerigee + cosInclination * orbitalZbyPerigee;

    // Lastly, rotate around the z' axis by RAAN: Ω
    double cosRAAN = cos(self.twoLineElementSet.rightAscensionOfTheAscendingNode * M_PI / 180.);
    double sinRAAN = sin(self.twoLineElementSet.rightAscensionOfTheAscendingNode * M_PI / 180.);    
    double geocentricX = cosRAAN * orbitalXbyInclination - sinRAAN * orbitalYbyInclination;
    double geocentricY = sinRAAN * orbitalXbyInclination + cosRAAN * orbitalYbyInclination;
    double geocentricZ = orbitalZbyInclination;
            
    // And then around the z axis by the earth's own rotaton    
    double rotationFromGeocentric = [DgxJulianMath getRotationFromGeocentricforJulianDate:currentJulianDate];
    double rotationFromGeocentricRad = -rotationFromGeocentric * M_PI / 180.f;
    
    double relativeX = cos(rotationFromGeocentricRad) * geocentricX - sin(rotationFromGeocentricRad) * geocentricY;
    double relativeY = sin(rotationFromGeocentricRad) * geocentricX + cos(rotationFromGeocentricRad) * geocentricY;
    double relativeZ = geocentricZ;
    
    ssLat = 90. - acos(relativeZ / sqrt(relativeX * relativeX + relativeY * relativeY + relativeZ * relativeZ)) * 180. / M_PI;
    ssLong = atan2(relativeY, relativeX) * 180. / M_PI;
        
    self.subsatellitePoint = CLLocationCoordinate2DMake( ssLat, ssLong );
}

@end
