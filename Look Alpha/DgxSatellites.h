//
//  DgxSatellites.h
//  Look Alpha
//
//  Created by Allen Snook on 11/23/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DgxSatellites : NSObject

@property (nonatomic, readonly) NSMutableArray* subsatellitePoints;

- (void)updateSubsatellitePoints;

@end
