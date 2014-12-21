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

@interface ViewController () <MKMapViewDelegate>

@property (nonatomic) UITextView *clockView;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) NSMutableArray *satellites;
@property (nonatomic) NSArray *satelliteAnnotations;
@property (nonatomic) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addSubViews];
    [self addSatellites];
    [self addMapAnnotations];
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
    self.satellites = [[NSMutableArray alloc] init];
        
    NSString *allGPS = @"GPS BIIA-10 (PRN 32)\n\
    1 20959U 90103A   14343.37167076  .00000030  00000-0  00000+0 0  5976\n\
    2 20959  54.2739 201.9377 0114064 357.8843   2.1523  2.00571636176041\n\
    GPS BIIA-14 (PRN 26)    \n\
    1 22014U 92039A   14344.04422582 -.00000033  00000-0  00000+0 0  3906\n\
    2 22014  55.7512 262.8457 0212065  74.1220 186.6762  2.00562427157784\n\
    GPS BIIA-23 (PRN 04)    \n\
    1 22877U 93068A   14343.80399672  .00000028  00000-0  00000+0 0  9866\n\
    2 22877  53.8133 136.4410 0107679  59.2864 310.1230  2.00554829154773\n\
    GPS BIIA-26 (PRN 10)    \n\
    1 23953U 96041A   14343.91613444  .00000031  00000-0  00000+0 0  6359\n\
    2 23953  53.9489 197.7470 0142379  51.3496 228.9116  2.00566816134844\n\
    GPS BIIR-2  (PRN 13)    \n\
    1 24876U 97035A   14344.22839648 -.00000034  00000-0  00000+0 0   874\n\
    2 24876  55.9027 263.3897 0056726 127.4612 294.3040  2.00305348127382\n\
    GPS BIIR-3  (PRN 11)    \n\
    1 25933U 99055A   14343.79268957  .00000004  00000-0  10000-3 0  5138\n\
    2 25933  51.1031 118.1070 0154617  78.3281 283.3679  2.00557505111196\n\
    GPS BIIR-4  (PRN 20)    \n\
    1 26360U 00025A   14344.20542610  .00000032  00000-0  00000+0 0  6328\n\
    2 26360  53.0839 193.2389 0060934  76.1885 132.6332  2.00563400106893\n\
    GPS BIIR-5  (PRN 28)    \n\
    1 26407U 00040A   14344.20535941 -.00000080  00000-0  00000+0 0  5699\n\
    2 26407  56.6119  21.0019 0199126 263.1306  61.2218  2.00562832105566\n\
    GPS BIIR-6  (PRN 14)    \n\
    1 26605U 00071A   14344.17683618 -.00000032  00000-0  00000+0 0  5804\n\
    2 26605  55.4734 261.4774 0079983 247.9686 344.9067  2.00553255103169\n\
    GPS BIIR-7  (PRN 18)    \n\
    1 26690U 01004A   14344.11896885  .00000030  00000-0  00000+0 0  4694\n\
    2 26690  53.0191 196.2714 0156999 245.6066  39.1462  2.00554244101566\n\
    GPS BIIR-8  (PRN 16)    \n\
    1 27663U 03005A   14344.16012353 -.00000080  00000-0  00000+0 0  8996\n\
    2 27663  56.6936  20.6853 0077732  11.1413  38.7204  2.00559553 86925\n\
    GPS BIIR-9  (PRN 21)    \n\
    1 27704U 03010A   14344.04030475  .00000030  00000-0  00000+0 0  7814\n\
    2 27704  53.4685 136.4533 0220728 247.1876  38.1997  2.00566360 85721\n\
    GPS BIIR-10 (PRN 22)    \n\
    1 28129U 03058A   14344.18058346  .00000030  00000-0  00000+0 0  3478\n\
    2 28129  52.8930 196.3549 0075000 242.3396  53.8464  2.00558533 80424\n\
    GPS BIIR-11 (PRN 19)    \n\
    1 28190U 04009A   14344.21598272 -.00000031  00000-0  00000+0 0  3588\n\
    2 28190  55.4497  82.5179 0106263  28.2108 337.2646  2.00563257 78609\n\
    GPS BIIR-12 (PRN 23)    \n\
    1 28361U 04023A   14344.17797494 -.00000030  00000-0  00000+0 0  1651\n\
    2 28361  54.4267 257.5315 0097645 205.4243 281.7758  2.00561161 76686\n\
    GPS BIIR-13 (PRN 02)    \n\
    1 28474U 04045A   14344.00176735  .00000030  00000-0  00000+0 0   682\n\
    2 28474  53.8691 135.5454 0142135 225.4498 138.7108  2.00556397 74046\n\
    GPS BIIRM-1 (PRN 17)    \n\
    1 28874U 05038A   14343.83105597 -.00000036  00000-0  00000+0 0  3014\n\
    2 28874  55.6165  79.6590 0100681 241.9398 105.8873  2.00562127 67445\n\
    GPS BIIRM-2 (PRN 31)    \n\
    1 29486U 06042A   14343.77544135 -.00000073  00000-0  00000+0 0  7271\n\
    2 29486  55.9694 318.9648 0084162 324.4383 264.0065  2.00562075 60158\n\
    GPS BIIRM-3 (PRN 12)    \n\
    1 29601U 06052A   14344.06906742 -.00000080  00000-0  00000+0 0  5333\n\
    2 29601  56.6611  19.6216 0049403  25.8892  96.6771  2.00553480 59078\n\
    GPS BIIRM-4 (PRN 15)    \n\
    1 32260U 07047A   14344.11927934 -.00000029  00000-0  00000+0 0  4461\n\
    2 32260  53.5602 254.6891 0069184  16.8744 266.8026  2.00546014 52468\n\
    GPS BIIRM-5 (PRN 29)    \n\
    1 32384U 07062A   14343.55585687 -.00000036  00000-0  00000+0 0  4779\n\
    2 32384  55.6619  80.1981 0013780 303.1683  73.3705  2.00573991 51180\n\
    GPS BIIRM-6 (PRN 07)    \n\
    1 32711U 08012A   14344.12248607 -.00000071  00000-0  10000-3 0  2245\n\
    2 32711  55.6874 318.5490 0081185 204.0712 155.5411  2.00571598 49406\n\
    GPS BIIRM-8 (PRN 05)    \n\
    1 35752U 09043A   14344.04945117  .00000032  00000-0  00000+0 0  9911\n\
    2 35752  54.2473 196.8193 0039465  20.3435 309.8482  2.00555854 38975\n\
    GPS BIIF-1  (PRN 25)    \n\
    1 36585U 10022A   14344.14185547 -.00000082  00000-0  00000+0 0  8048\n\
    2 36585  56.0087  17.0588 0037336  35.6491 107.3222  2.00555019 33228\n\
    GPS BIIF-2  (PRN 01)    \n\
    1 37753U 11036A   14343.86097153  .00000032  00000-0  00000+0 0  2694\n\
    2 37753  55.0962 137.4926 0036374  22.0444   0.9118  2.00563694 24904\n\
    GPS BIIF-3  (PRN 24)    \n\
    1 38833U 12053A   14343.31832932 -.00000077  00000-0  00000+0 0  8412\n\
    2 38833  54.7298 316.4061 0026772   7.6727 352.3577  2.00561218 15953\n\
    GPS BIIF-4  (PRN 27)    \n\
    1 39166U 13023A   14344.16809222 -.00000038  00000-0  10000-3 0  5981\n\
    2 39166  55.3212  76.9666 0015577   6.7238 353.3105  2.00562518 11490\n\
    GPS BIIF-5  (PRN 30)    \n\
    1 39533U 14008A   14342.66962844 -.00000082  00000-0  00000+0 0  3360\n\
    2 39533  54.8679 321.5711 0010191 195.1468 164.8144  2.00568846  5833\n\
    GPS BIIF-6  (PRN 06)    \n\
    1 39741U 14026A   14344.44707139  .00000038  00000-0  00000+0 0  2216\n\
    2 39741  55.0901 136.9795 0004550 152.8864 207.1093  2.00566753  4150\n\
    GPS BIIF-7  (PRN 09)    \n\
    1 40105U 14045A   14344.03973736 -.00000028  00000-0  00000+0 0  1237\n\
    2 40105  54.9392 256.9537 0002616 221.0838 138.9479  2.00559989  2594\n\
    GPS BIIF-8  (PRN 03)    \n\
    1 40294U 14068A   14342.48733667  .00000041  00000-0  00000+0 0   227\n\
    2 40294  54.9747 197.1569 0010568 200.3448 212.9756  2.00550597   786";

    NSArray *allGPSLines = [allGPS componentsSeparatedByString:@"\n"];

    long tleCount = allGPSLines.count / 3;
    
    for (long i=0; i<tleCount; i++ ) {
        NSString *name = allGPSLines[i * 3];
        NSString *lineOne = allGPSLines[1 + i * 3];
        NSString *lineTwo = allGPSLines[2 + i * 3];
        
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        lineOne = [lineOne stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        lineTwo = [lineTwo stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSLog(@"vvvvvvvvvvvv");
        NSLog(@"i = %ld", i);
        NSLog(@"name = %@", name);
        NSLog(@"lineOne = %@", lineOne);
        NSLog(@"lineTwo = %@", lineTwo);
        
        if (0 < name.length) {
            DgxTwoLineElementSet *twoLineElementSet = [[DgxTwoLineElementSet alloc] initWithName:name
                                                                                    andLineOne:lineOne
                                                                                    andLineTwo:lineTwo];
            
            DgxSatellite *satellite = [[DgxSatellite alloc] initWithTwoLineElementSet:twoLineElementSet];
            [self.satellites addObject:satellite];
        }
        
        NSLog(@"^^^^^^^^^^^^");
    }
}

- (void)addMapAnnotations
{
    // First, our present location
    MKPointAnnotation *userAnnotation = [[MKPointAnnotation alloc] init];
    userAnnotation.coordinate = CLLocationCoordinate2DMake( 47.6097, -122.3331 );
    userAnnotation.title = @"Your Location";
    [self.mapView addAnnotation:userAnnotation];

    // Next, the satellites
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

@end
