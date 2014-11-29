//
//  DgxJulianMath.m
//  Look Alpha
//
//  Created by Allen Snook on 11/29/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import "DgxJulianMath.h"

@implementation DgxJulianMath

/** 
 * Returns the current time as the number of integer seconds since the first instant of 1 January 2001, GMT
 * @author allendav
 *
 * @return Current time in seconds since 1/1/1
 */
+ (long)getSecondsSinceReferenceDate
{
    NSDate *currentDate = [[NSDate alloc] init]; 
    return floor(currentDate.timeIntervalSinceReferenceDate);
}

/** 
 * Returns the Julian date for the given number of seconds since the first instant of 1 January 2001, GMT
 * Note: Treats UTC as == UT (when in fact they can differ by 0 to 0.9 seconds)
 * @author allendav
 *
 * @param secondsSinceReferenceDate The number of seconds since the first instant of 1 January 2001, GMT
 * @return String timestamp
 */
+ (NSString*)getUTCTimestampFromSecondsSinceReferenceDate:(long)secondsSinceReferenceDate
{
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:secondsSinceReferenceDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss 'UTC'"];
    [dateFormatter setTimeZone: [NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSString *timeString = [dateFormatter stringFromDate:date];
    return timeString;
}

/** 
 * Returns the Julian date for the given number of seconds since the first instant of 1 January 2001, GMT
 * Note: Treats UTC as == UT (when in fact they can differ by 0 to 0.9 seconds)
 * @author allendav
 *
 * @param secondsSinceReferenceDate The number of seconds since the first instant of 1 January 2001, GMT
 * @return Julian date for the given time
 */
+ (double)getJulianDateFromSecondsSinceReferenceDate:(long)secondsSinceReferenceDate
{
    double secondsPerDay = 86400.;
    return 2451910.5 + secondsSinceReferenceDate / secondsPerDay;
}

/** 
 * Returns a Julian date which corresponds to 0h UT for the given Julian Date
 * Note: Treats UTC as == UT (when in fact they can differ by 0 to 0.9 seconds)
 * @author allendav
 *
 * @param julianDate The julian date
 * @return Julian date for 0h UT 
 */
+ (double)getZeroHourUTJulianDateforJulianDate:(double)julianDate
{
    return (floor(julianDate - 0.5) + 0.5);
}

/** 
 * Returns the number of minutes (including fractional minutes) since 0h UT (aka midnight) for the given Julian Date
 * Note: Treats UTC as == UT (when in fact they can differ by 0 to 0.9 seconds)
 * @author allendav
 *
 * @param julianDate The julian date
 * @return Minutes since UT midnight 
 */
+ (double)getMinutesSinceZeroHourUTforJulianDate:(double)julianDate
{
    double minutesPerDay = 1440.;
    double zeroHourUTJD = [self getZeroHourUTJulianDateforJulianDate:julianDate];
    return (minutesPerDay * (julianDate - zeroHourUTJD));
}

/** 
 * Returns alpha g,o - the angle of the Greenwich meridian at 0h UT on the given Julian Date - in degrees
 * Based on http://aa.usno.navy.mil/faq/docs/GAST.php
 * @author allendav
 *
 * @param julianDate The julian date
 * @return Right ascension of the Greenwich meridian in degrees
 */
+ (double)getAngleofGreenwichMeridianAtZeroHourUTforJulianDate:(double)julianDate
{
    double zeroHourUTJulianDate = [self getZeroHourUTJulianDateforJulianDate:julianDate];
    double julianDaysSince2000January1NoonUT = zeroHourUTJulianDate - 2451545.;
    double julianCenturiesSince2000 = floor(julianDaysSince2000January1NoonUT / 36525.);
    double greenwichMeanSiderealTimeAtZeroHourUTInHours = 6.697374558 + 0.06570982441908 * julianDaysSince2000January1NoonUT + 0.000026 * julianCenturiesSince2000 * julianCenturiesSince2000;    
    // reduce it to 0 to 24 h
    double days = floor( greenwichMeanSiderealTimeAtZeroHourUTInHours / 24. );
    greenwichMeanSiderealTimeAtZeroHourUTInHours = greenwichMeanSiderealTimeAtZeroHourUTInHours - days * 24;
    // turn it into an angle
    return (greenwichMeanSiderealTimeAtZeroHourUTInHours * 360. / 24.);
}

/**
 * Returns Omega e * T e - the angle the coordinate system attached to the earth (xr, yr, zr) has
 * rotated with respect to the geocentric equatorial coordinate system (xi, yi, zi)
 * for the given julianDate
 * Based on eq 2.51 from "Satellite Communications" by Timothy Pratt, 1986
 *
 * @param julianDate The julian date
 * @return Rotation in degrees
 */
+ (double)getRotationFromGeocentricforJulianDate:(double)julianDate
{
    double rightAscensionGreenwichAtZeroHour = [self getAngleofGreenwichMeridianAtZeroHourUTforJulianDate:julianDate];
    double minutesSinceUTMidnight = [self getMinutesSinceZeroHourUTforJulianDate:julianDate];
    return (rightAscensionGreenwichAtZeroHour + 0.25068447 * minutesSinceUTMidnight);
}

@end
