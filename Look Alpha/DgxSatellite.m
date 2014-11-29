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
            self.twoLineElementSet = twoLineElementSet;
        } else {
            self.twoLineElementSet = [[DgxTwoLineElementSet alloc] init];
        }
    };
    
    return self;
}

- (CLLocationCoordinate2D)getSubsatellitePointNow
{    
    CLLocationDegrees ssLat = 0;
    CLLocationDegrees ssLong = 0;
    
    long currentDate = [DgxJulianMath getSecondsSinceReferenceDate];
    NSLog(@"currentDate (sec) = %ld", currentDate);
    
    double currentJulianDate = [DgxJulianMath getJulianDateFromSecondsSinceReferenceDate:currentDate];
    NSLog(@"currentJulianDate (JD) = %f", currentJulianDate);

    double epochJulianDate = [self.twoLineElementSet getEpochAsJulianDate];
    NSLog(@"epochJulianDate (JD) = %f", epochJulianDate);
        
    double semimajorAxis = self.twoLineElementSet.getSemimajorAxis; // kilometers
    NSLog(@"semimajorAxis (km) = %f", semimajorAxis);
    
    double currentMeanAnomaly = [self.twoLineElementSet getMeanAnomalyForJulianDate:currentJulianDate];
    NSLog(@"currentMeanAnomaly (degrees) = %f", currentMeanAnomaly);
    
    // Use the current Mean Anomaly to get the current Eccentric Anomaly
    double currentEccentricAnomaly = [self.twoLineElementSet getEccentricAnomalyForMeanAnomaly:currentMeanAnomaly];
    NSLog(@"currentEccentricAnomaly (degrees) = %f", currentEccentricAnomaly);
    
    // Use the current Eccentric Anomaly to get the currentTrueAnomaly
    double currentTrueAnomaly = [self.twoLineElementSet getTrueAnomalyForEccentricAnomaly:currentEccentricAnomaly];
    NSLog(@"currentTrueAnomaly (degrees) = %f", currentTrueAnomaly);
    
    // Solve for r0 : the distance from the satellite to the Earth's center
    double currentOrbitalRadius = semimajorAxis - semimajorAxis * self.twoLineElementSet.eccentricity * cos(currentEccentricAnomaly * M_PI / 180.);
    NSLog(@"currentOrbitalRadius (km) = %f", currentOrbitalRadius);

    // Solve for the x and y position in the orbital plane
    double orbitalX = currentOrbitalRadius * cos(currentTrueAnomaly * M_PI / 180.);
    double orbitalY = currentOrbitalRadius * sin(currentTrueAnomaly * M_PI / 180.);
    
    NSLog(@"orbitalX = %f", orbitalX);
    NSLog(@"orbitalY = %f", orbitalY);
    
    double orbitalCheck = sqrt(orbitalX * orbitalX + orbitalY * orbitalY);
    NSLog(@"orbitalCheck = %f", orbitalCheck);
    
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
    NSLog(@"RAAN = %f", self.twoLineElementSet.rightAscensionOfTheAscendingNode);
    double cosRAAN = cos(self.twoLineElementSet.rightAscensionOfTheAscendingNode * M_PI / 180.);
    double sinRAAN = sin(self.twoLineElementSet.rightAscensionOfTheAscendingNode * M_PI / 180.);    
    double geocentricX = cosRAAN * orbitalXbyInclination - sinRAAN * orbitalYbyInclination;
    double geocentricY = sinRAAN * orbitalXbyInclination + cosRAAN * orbitalYbyInclination;
    double geocentricZ = orbitalZbyInclination;
        
    NSLog(@"geocentricX = %f", geocentricX);
    NSLog(@"geocentricY = %f", geocentricY);
    NSLog(@"geocentricZ = %f", geocentricZ);
    
    double geocentricCheck = sqrt(geocentricX * geocentricX + geocentricY * geocentricY + geocentricZ * geocentricZ);
    NSLog(@"geocentricCheck = %f", geocentricCheck);
    
    // And then around the z axis by the earth's own rotaton    
    double rotationFromGeocentric = [DgxJulianMath getRotationFromGeocentricforJulianDate:currentJulianDate];
    NSLog(@"rotationFromGeocentric = %f (deg)", rotationFromGeocentric);
    double rotationFromGeocentricRad = -rotationFromGeocentric * M_PI / 180.f;
    
    double relativeX = cos(rotationFromGeocentricRad) * geocentricX - sin(rotationFromGeocentricRad) * geocentricY;
    double relativeY = sin(rotationFromGeocentricRad) * geocentricX + cos(rotationFromGeocentricRad) * geocentricY;
    double relativeZ = geocentricZ;
    
    NSLog(@"relativeX = %f", relativeX);
    NSLog(@"relativeY = %f", relativeY);
    NSLog(@"relativeZ = %f", relativeZ);

    double relativeCheck = sqrt(relativeX * relativeX + relativeY * relativeY + relativeZ * relativeZ);
    NSLog(@"relativeCheck = %f", relativeCheck);

    ssLat = 90. - acos(relativeZ / sqrt(relativeX * relativeX + relativeY * relativeY + relativeZ * relativeZ)) * 180. / M_PI;
    ssLong = atan2(relativeY, relativeX) * 180. / M_PI;
    
    NSLog(@"ssLat = %f", ssLat);
    NSLog(@"ssLong = %f", ssLong);
    
    return CLLocationCoordinate2DMake( ssLat, ssLong );
}

@end
