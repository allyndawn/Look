//
//  DgxTwoLineElementSet.m
//  Look Alpha
//
//  Created by Allen Snook on 11/28/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import "DgxTwoLineElementSet.h"

@implementation DgxTwoLineElementSet

- (instancetype)init
{
    return [self initWithName:nil andLineOne:nil andLineTwo:nil];
}

- (instancetype)initWithName:(NSString *)nameOfSatellite andLineOne:(NSString *)lineOne andLineTwo:(NSString *)lineTwo
{
    if (self = [super init] ) {

        // An example TLE
        //
        //           1         2         3         4         5         6         7
        // 01234567890123456789012345678901234567890123456789012345678901234567890123456789
        // 1 25544U 98067A   14332.12480567  .00017916  00000-0  30378-3 0  4720
        // 2 25544  51.6474   6.7919 0007352  75.3130 346.0866 15.51558891916767
        
        self.nameOfSatellite = nameOfSatellite;
        
        self.epochYear = [[lineOne substringWithRange:NSMakeRange(18, 2)] intValue];
        if (self.epochYear >= 57) {
            self.epochYear += 1900;
        } else {
            self.epochYear += 2000;
        }
        
        self.epochJulianDateFraction = [[lineOne substringWithRange:NSMakeRange(20, 12)] doubleValue];
        
        self.inclination = [[lineTwo substringWithRange:NSMakeRange(8, 8)] doubleValue];
        
        self.rightAscensionOfTheAscendingNode = [[lineTwo substringWithRange:NSMakeRange(17, 7)] doubleValue];

        NSString *eccentricityString = [NSString stringWithFormat:@"0.%@", [lineTwo substringWithRange:NSMakeRange(26, 7)]];
        self.eccentricity = [eccentricityString doubleValue];

        self.argumentOfPerigee = [[lineTwo substringWithRange:NSMakeRange(34, 8)] doubleValue];

        self.meanAnomaly = [[lineTwo substringWithRange:NSMakeRange(43, 8)] doubleValue];
        
        self.meanMotion = [[lineTwo substringWithRange:NSMakeRange(52, 11)] doubleValue];
        
        self.revolutionNumber = [[lineTwo substringWithRange:NSMakeRange(63, 5)] intValue];
    };
    
    return self;
}

- (double)getSemimajorAxis
{
    double keplersConstant = 398613.52; // km^3/s^2
    double meanMotionPerSec = self.meanMotion / 86400.;
    return pow(keplersConstant / (4. * M_PI * M_PI * meanMotionPerSec * meanMotionPerSec), 1./3.);
}

- (double)getOrbitalPeriod
{
    return (86400. / self.meanMotion);
}

- (double)getMeanMotionAsAngularVelocity
{
    double orbitalPeriod = [self getOrbitalPeriod];    
    return (360. / orbitalPeriod);
}

- (double)getEpochAsJulianDate
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    // get the 1/1/eopch year 12h GMT in seconds since 1/1/1 0h GMT
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:self.epochYear];
    [components setMonth:1];
    [components setDay:1];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];

    NSDate *epochFirstDayOfYear = [calendar dateFromComponents:components];
    
    long epochFirstDayOfYearSecondsSinceReferenceDate = floor(epochFirstDayOfYear.timeIntervalSinceReferenceDate);
    
    double epochFirstDayOfYearJulianDate = 2451910.5 + epochFirstDayOfYearSecondsSinceReferenceDate / 86400.;

    return epochFirstDayOfYearJulianDate + self.epochJulianDateFraction - 1.; // TLE contains julian day of year (therefore first day is day 1 not 0)
}

- (double)getMeanAnomalyForJulianDate:(double)julianDate
{
    double epochJulianDate = [self getEpochAsJulianDate];
    double daysSinceEpoch = julianDate - epochJulianDate;
    
    double revolutionsSinceEpoch = self.meanMotion * daysSinceEpoch;
    
    double meanAnomalyForJulianDate = self.meanAnomaly + revolutionsSinceEpoch * 360.;
    
    long fullRevolutions = floor(meanAnomalyForJulianDate / 360.);
    
    return meanAnomalyForJulianDate - 360. * fullRevolutions;
}

- (double)getEccentricAnomalyForMeanAnomaly:(double)meanAnomaly
{
    // For a circular orbit, the Eccentric Anomaly and the Mean Anomaly are equal
    if (self.eccentricity == 0.) {
        return meanAnomaly;
    }
     
    // Otherwise, do Newton–Raphson to solve Kepler's Equation : M = E - e * sin(E)
    // Start with the estimate = meanAnomaly converted to radians
    double estimate = 0.;
    double estimateError = 0.;
    double meanAnomalyInRadians = meanAnomaly * M_PI / 180.;
    double previousEstimate = meanAnomalyInRadians;
     
    // Now, iterate until the delta < 0.0001
    do {
        estimate = previousEstimate - (previousEstimate - self.eccentricity * sin(previousEstimate) - meanAnomalyInRadians) / ( 1 - self.eccentricity * cos(previousEstimate) );
        estimateError = fabs(estimate - previousEstimate);
        previousEstimate = estimate;
    } while (estimateError > 0.0001);
     
    return (estimate * 180. / M_PI);
}

/**
 * Based on http://en.wikipedia.org/wiki/True_anomaly
 */
- (double)getTrueAnomalyForEccentricAnomaly:(double)eccentricAnomaly
{
    double halfEccentricAnomalyRad = (eccentricAnomaly * M_PI / 180.) / 2.;
    
    return 2. * atan2(sqrt(1 + self.eccentricity) * sin(halfEccentricAnomalyRad), sqrt(1 - self.eccentricity) * cos(halfEccentricAnomalyRad)) * 180. / M_PI;
}

@end
