//
//  DgxJulianMath.h
//  Look Alpha
//
//  Created by Allen Snook on 11/29/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DgxJulianMath : NSObject

+ (long)getSecondsSinceReferenceDate;
+ (NSString*)getUTCTimestampFromSecondsSinceReferenceDate:(long)secondsSinceReferenceDate;
+ (double)getJulianDateFromSecondsSinceReferenceDate:(long)secondsSinceReferenceDate;
+ (double)getZeroHourUTJulianDateforJulianDate:(double)julianDate;
+ (double)getMinutesSinceZeroHourUTforJulianDate:(double)julianDate;
+ (double)getAngleofGreenwichMeridianAtZeroHourUTforJulianDate:(double)julianDate;
+ (double)getRotationFromGeocentricforJulianDate:(double)julianDate;


@end
