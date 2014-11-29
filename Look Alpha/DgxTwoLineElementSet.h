//
//  DgxTwoLineElementSet.h
//  Look Alpha
//
//  Created by Allen Snook on 11/28/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DgxTwoLineElementSet : NSObject

// Line 0
@property (nonatomic, strong) NSString* nameOfSatellite;

// Line 1
@property (nonatomic) int epochYear;
@property (nonatomic) double epochJulianDateFraction;

// Line 2
@property (nonatomic) double inclination;                               // i, degrees
@property (nonatomic) double rightAscensionOfTheAscendingNode;          // Ω, degrees
@property (nonatomic) double eccentricity;                              // e, degrees
@property (nonatomic) double argumentOfPerigee;                         // degrees
@property (nonatomic) double meanAnomaly;                               // degrees
@property (nonatomic) double meanMotion;                                // The number of orbits the satellite completes in a day
@property (nonatomic) int revolutionNumber;

- (instancetype)initWithName:(NSString *)nameOfSatellite andLineOne:(NSString *)lineOne andLineTwo:(NSString *)lineTwo;

- (double)getSemimajorAxis;                                             // kilometers
- (double)getOrbitalPeriod;                                             // Time to complete one orbit, seconds
- (double)getMeanMotionAsAngularVelocity;                               // degrees / second
- (double)getEpochAsJulianDate;
- (double)getMeanAnomalyForJulianDate:(double)julianDate;               // degrees
- (double)getEccentricAnomalyForMeanAnomaly:(double)meanAnomaly;        // degrees
- (double)getTrueAnomalyForEccentricAnomaly:(double)eccentricAnomaly;
@end
