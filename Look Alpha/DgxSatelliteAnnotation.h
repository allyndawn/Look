//
//  DgxSatelliteAnnotation.h
//  Look Alpha
//
//  Created by Allen Snook on 1/2/15.
//  Copyright (c) 2015 Designgeneers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

typedef enum {
    KDGX_SATELLITE_NOT_VISIBLE = 0,
    KDGX_SATELLITE_VISIBILITY_MARGINAL = 1,
    KDGX_SATELLITE_VISIBILITY_GOOD = 2,
    KDGX_SATELLITE_VISIBILITY_EXCELLENT = 3
} DgxSatelliteVisibilityType;

@interface DgxSatelliteAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

@property (nonatomic) long satID;
@property (nonatomic) DgxSatelliteVisibilityType visibility;

@end
