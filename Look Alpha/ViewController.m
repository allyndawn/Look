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
#import "DgxSatellite.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic) UITextView *clockView;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) NSMutableArray *satellites;
@property (nonatomic) NSArray *satelliteAnnotations;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) CLLocationManager *locationManager;

@property (atomic) NSMutableArray *pendingRequests;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addSubViews];
    [self addUsersLocation];
    [self addSatellites];
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

- (void)addSatellitesFromURL:(NSString *)url withSourceTag:(NSString *)sourceTag
{
    // TODO Check CoreData for a recently cached response for this URL first
    
    // Add this request to the queue
    if (!self.pendingRequests) {
        self.pendingRequests = [[NSMutableArray alloc] init];
    }
    
    [self.pendingRequests addObject:url];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:url]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                // handle response
                [self.pendingRequests removeObjectIdenticalTo:url];
                
                NSString *strData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                
                // TODO check for unexpected response                                
                [self addSatellitesFromString:strData];

                // If the requests queue is now empty, trigger a map update
                if (0 == self.pendingRequests.count) {
                    [self addMapAnnotations];                    
                }
            }] resume];
}

- (void)addSatellitesFromString:(NSString *)strData
{
    NSArray *responseArray = [strData componentsSeparatedByString:@"\n"];
    
    long tleCount = responseArray.count / 3;
    
    for (long i=0; i < tleCount; i++ ) {
        NSString *name = responseArray[i * 3];
        NSString *lineOne = responseArray[1 + i * 3];
        NSString *lineTwo = responseArray[2 + i * 3];
        
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        lineOne = [lineOne stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        lineTwo = [lineTwo stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (0 < name.length) {
            DgxTwoLineElementSet *twoLineElementSet = [[DgxTwoLineElementSet alloc] initWithName:name
                                                                                      andLineOne:lineOne
                                                                                      andLineTwo:lineTwo];
            
            // TODO: Check and see if we already have this satellite in our array
            // If we don't, add the satellite
            // If we do, add the category slug only to the existing satellite's slug array
            
            DgxSatellite *satellite = [[DgxSatellite alloc] initWithTwoLineElementSet:twoLineElementSet];
            [self.satellites addObject:satellite];
        }
    }
}

- (void)addSatellites
{
    self.satellites = [[NSMutableArray alloc] init];
    
    // TODO Check CoreData for a recently cached set of TLEs
    
    // TODO Move all this logic into a datamanager, apart from the view controller
    
    //[self addSatellitesFromURL:@"http://www.celestrak.com/NORAD/elements/stations.txt" withSourceTag:@"Space Stations"];
    //[self addSatellitesFromURL:@"http://www.celestrak.com/NORAD/elements/visual.txt" withSourceTag:@"Brightest"];
    [self addSatellitesFromURL:@"http://www.celestrak.com/NORAD/elements/amateur.txt" withSourceTag:@"Amateur Radio"];
    [self addSatellitesFromURL:@"http://www.celestrak.com/NORAD/elements/gps-ops.txt" withSourceTag:@"GPS Operational"];        
}

- (void)addUsersLocation
{
    self.mapView.showsUserLocation = YES;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if(IS_OS_8_OR_LATER) {
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

- (void)addMapAnnotations
{
    // Don't bother if there are pending requests
    if (0 != self.pendingRequests.count) {
        return;
    }

    // Next, add the satellites
    // TODO: Filter
    
    // Create it first as an NSMutableArray
    NSMutableArray *satelliteAnnotations = [[NSMutableArray alloc] init];
    for (long i=0; i<self.satellites.count; i++) {        
        MKPointAnnotation *satelliteAnnotation = [[MKPointAnnotation alloc] init];
        DgxSatellite *satellite = [self.satellites objectAtIndex:i];
        satelliteAnnotation.title = [satellite name];
        satelliteAnnotation.subtitle = [NSString stringWithFormat:@"%@ / %ld", [satellite cosparID], [satellite satCatNumber]];
        satelliteAnnotation.coordinate = CLLocationCoordinate2DMake(0., 0.);
        [satelliteAnnotations addObject:satelliteAnnotation];
    }
    
    // But then, to get KVO for changes to the subsatellite points, we have to repackage it into NSArray
    // TODO: Is this for certain?
    self.satelliteAnnotations = [[NSArray alloc] initWithArray:satelliteAnnotations];
    [self.mapView addAnnotations:self.satelliteAnnotations];
}

- (void)updateMapAnnotations
{
    // Don't bother if there are pending requests
    if (0 != self.pendingRequests.count) {
        return;
    }

    // Otherwise, update away!
    for (long i=0; i<self.satelliteAnnotations.count; i++) {
        DgxSatellite *satellite = self.satellites[i];
        [satellite updateSubsatellitePoint];
        [self.satelliteAnnotations[i] setCoordinate:satellite.subsatellitePoint];
    }
}

- (void)removeMapAnnotations
{
    // [self.mapView removeAnnotations:nil];
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
    [self updateMapAnnotations];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
}

@end
