//
//  ViewController.m
//  Look Alpha
//
//  Created by Allen Snook on 11/22/14.
//  Copyright (c) 2014 Designgeneers. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "DgxSatellites.h"

@interface ViewController () <MKMapViewDelegate>

@property (nonatomic) UITextView *clockView;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) DgxSatellites *satellites;
@property (nonatomic) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addSubViews];
    [self addSatellites];
    [self addEarthStation];
    [self addTimer];
    
}

- (void)addSubViews {
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectZero];
    [self.mapView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:self.mapView];
    
    self.clockView = [[UITextView alloc] initWithFrame:CGRectZero];
    [self.clockView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.clockView.textAlignment = NSTextAlignmentCenter;
    [self.clockView setFont:[UIFont systemFontOfSize:17]];
    [self.clockView setBackgroundColor: [UIColor blackColor]];
    [self.clockView setTextColor: [UIColor whiteColor]];
    [self.view addSubview:self.clockView];

    NSDictionary *views = @{@"mapview": self.mapView,
                            @"clockview": self.clockView };    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mapview]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[clockview]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mapview][clockview(40)]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    self.mapView.delegate = self;
}

- (void)addSatellites
{
    self.satellites = [[DgxSatellites alloc] init];
    [self.mapView addAnnotations:self.satellites.subsatellitePoints];
}

- (void)addEarthStation
{
    MKPointAnnotation *subsatellitePoint = [[MKPointAnnotation alloc] init];
    subsatellitePoint.coordinate = CLLocationCoordinate2DMake( 47.6097f, -122.3331f );
    subsatellitePoint.title = @"Seattle";
    [self.mapView addAnnotation:subsatellitePoint];
}

- (void)addTimer
{
    self.timer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)onTimer:(NSTimer *)timer
{
    NSDate *currentDate = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss 'UTC'"];
    [dateFormatter setTimeZone: [NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSString *timeeString = [dateFormatter stringFromDate:currentDate];    
    self.clockView.text = timeeString;
    
    [self.satellites updateSubsatellitePoints];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
