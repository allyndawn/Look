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
#import "DgxEarthStation.h"
#import "DgxSatelliteAnnotation.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic) NSMutableArray *satellites;
@property (nonatomic) DgxEarthStation *earthStation;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *dateTimeBarButtonItem;

@property (nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) NSArray *satelliteAnnotations;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) CLLocationManager *locationManager;

@property (atomic) NSMutableArray *pendingRequests;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    
    [self addEarthStation];
    [self addUsersLocation];
    [self addSatellites];
    [self addTimer];
}

- (void)addEarthStation
{
    self.earthStation = [[DgxEarthStation alloc] init];
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
        DgxSatelliteAnnotation *satelliteAnnotation = [[DgxSatelliteAnnotation alloc] init];
        DgxSatellite *satellite = [self.satellites objectAtIndex:i];
        satelliteAnnotation.title = [satellite name];
        satelliteAnnotation.subtitle = nil;
        satelliteAnnotation.coordinate = CLLocationCoordinate2DMake(0., 0.);
        [satelliteAnnotations addObject:satelliteAnnotation];
    }
    
    // But then, to get KVO for changes to the subsatellite points, we have to repackage it into NSArray
    // TODO: Is this for certain?
    self.satelliteAnnotations = [[NSArray alloc] initWithArray:satelliteAnnotations];
    for (long i=0; i<self.satelliteAnnotations.count; i++) {
        [self.mapView addAnnotation:self.satelliteAnnotations[i]];
    }
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
        DgxGeoCoordinates satelliteCoordinates = [satellite getSatellitePositionNow];
        CLLocationCoordinate2D subsatellitePoint = CLLocationCoordinate2DMake(satelliteCoordinates.latitude, satelliteCoordinates.longitude);
        [self.satelliteAnnotations[i] setCoordinate:subsatellitePoint];
        
        // Calculate the look angles for our current location
        DgxSatelliteVisibilityType oldVisibility = [self.satelliteAnnotations[i] visibility];
        DgxSatelliteVisibilityType newVisibility = oldVisibility;
        
        DgxLookAngle lookAngle = [self.earthStation getLookAngleForSatelliteAt:satelliteCoordinates];
        if (lookAngle.elevation >= 0.) {
            [self.satelliteAnnotations[i] setSubtitle:[NSString stringWithFormat:@"El: %.1f° Az: %.1f°", lookAngle.elevation, lookAngle.azimuth]];
            newVisibility = KDGX_SATELLITE_VISIBILITY_GOOD;
        } else {
            [self.satelliteAnnotations[i] setSubtitle:nil];
            newVisibility = KDGX_SATELLITE_NOT_VISIBLE;
        }
        
        // If the visibility has changed, we need to remove and re-add the annotation
        // otherwise iOS will not show the pin color change
        if (newVisibility != oldVisibility) {
            [self.mapView removeAnnotation:self.satelliteAnnotations[i]];
            [self.satelliteAnnotations[i] setVisibility:newVisibility];
            [self.mapView addAnnotation:self.satelliteAnnotations[i]];
        }
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
    self.dateTimeBarButtonItem.title = timeeString;
    [self updateMapAnnotations];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
    [self.earthStation setCoordinate:userLocation.location.coordinate];    
    [self.earthStation setAltitude:userLocation.location.altitude];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If the annotation is the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[DgxSatelliteAnnotation class]]) {
        
        DgxSatelliteAnnotation *satelliteAnnotation = annotation;
        
        // Try to dequeue an existing pin view first.
        MKAnnotationView *pinAnnotationView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        
        if (!pinAnnotationView) {
            // If an existing pin view was not available, create one.
            pinAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:@"CustomPinAnnotationView"];
            //pinView.animatesDrop = NO;
            pinAnnotationView.canShowCallout = YES;
            
            // If appropriate, customize the callout by adding accessory views (code not shown).
        } else {
            pinAnnotationView.annotation = annotation;
        }

        // Lastly, update the pin color
        if (satelliteAnnotation.visibility == KDGX_SATELLITE_NOT_VISIBLE) {
            //pinView.pinColor = MKPinAnnotationColorRed;
            pinAnnotationView.image = [UIImage imageNamed:@"Satellite not visible.png"];
        } else {
            //pinView.pinColor = MKPinAnnotationColorGreen;
            pinAnnotationView.image = [UIImage imageNamed:@"Satellite visible.png"];
        }

        return pinAnnotationView;
    }
    
    return nil;
}

@end
