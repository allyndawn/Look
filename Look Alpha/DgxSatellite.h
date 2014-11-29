//
//  DgxSatellite.h
//  Look Alpha
//
//  Created by Allen Snook on 11/23/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "DgxTwoLineElementSet.h"

@interface DgxSatellite : NSObject

@property (nonatomic) DgxTwoLineElementSet *twoLineElementSet;

- (instancetype)initWithTwoLineElementSet:(DgxTwoLineElementSet *)twoLineElementSet;

- (CLLocationCoordinate2D)getSubsatellitePointNow;

@end
