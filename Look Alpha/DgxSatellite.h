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
#import "DgxSpaceConstants.h"

@interface DgxSatellite : NSObject

@property (nonatomic) DgxTwoLineElementSet *twoLineElementSet;
@property (nonatomic) NSString *name;
@property (nonatomic) long satCatNumber;
@property (nonatomic) NSString *cosparID;

- (instancetype)initWithTwoLineElementSet:(DgxTwoLineElementSet *)twoLineElementSet;

- (DgxGeoCoordinates)getSatellitePositionNow;

@end
