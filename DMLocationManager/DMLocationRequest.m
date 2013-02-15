//
//  DMLocationRequest.m
//  DMLocationManagerExample
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 11/10/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//  Distribuited under MIT License (http://opensource.org/licenses/MIT)
//

#import "DMLocationRequest.h"
#import "DMLocationManager.h"

#define kDMLocManage_DefaultTimeout                     15.0f

#define kDMLocManage_MinAccuracy_BestNavigation         60.0f
#define kDMLocManage_MinAccuracy_TenMeters              120.0f
#define kDMLocManage_MinAccuracy_HundredMeters          500.0f
#define kDMLocManage_MinAccuracy_Kilometer              1000.0f
#define kDMLocManage_MinAccuracy_3Kilometers            3000.0f

#define kGoogleMapsReverseGeocodeURL                    @"http://maps.google.com/maps/api/geocode/json?sensor=false&address=%@"


@interface DMLocationRequest () <CLLocationManagerDelegate> {
    CLLocationAccuracy                              accuracy;
    BOOL                                            reverseCoordinates;
    BOOL                                            useCachedLocation;
    
    @private
        DMLocationRequestHandler                    completitionHandler;
        DMLocationRequestReverseGeoHandler          geocoderCompletitionHandler;
        DMLocationRequestReverseAddressCoordinates  coordFromAdrCompletitionHandler;

        NSString*                                   addressLine;
        DMLocationRequestType                       operationType;
        CLLocationManager*                          locationManager;
        NSTimeInterval                              timeout;
        CLLocation*                                 currentLocation;
        NSTimer*                                    timeoutTimer;
}

@property (copy)        DMLocationRequestHandler                        completitionHandler;
@property (copy)        DMLocationRequestReverseGeoHandler              geocoderCompletitionHandler;
@property (copy)        DMLocationRequestReverseAddressCoordinates      coordFromAdrCompletitionHandler;
@property (readwrite)   CLLocation*                                     currentLocation;
@property (readwrite)   NSString*                                       addressLine;

@end

@implementation DMLocationRequest

@synthesize accuracy,reverseCoordinates;
@synthesize completitionHandler,geocoderCompletitionHandler,coordFromAdrCompletitionHandler;
@synthesize timeout,useCachedLocation,currentLocation;
@synthesize addressLine;

- (id)initWithType:(DMLocationRequestType) type {
    self = [super init];
    if (self) {
        self.timeout = kDMLocManage_DefaultTimeout;
        currentLocation = nil;
        operationType = type;
    }
    return self;
}

+ (DMLocationRequest *) addressFromLocation:(CLLocation *) location
                               completition:(DMLocationRequestReverseGeoHandler) completition {
    
    DMLocationRequest* request = [[DMLocationRequest alloc] initWithType:DMLocationRequestTypeReverseLocation];
    request.geocoderCompletitionHandler = completition;
    request.currentLocation = location;
    return request;
}

+ (DMLocationRequest *) currentLocation:(BOOL) reverseCoordinates
                               accuracy:(CLLocationAccuracy) accuracy
                           completition:(DMLocationRequestHandler) completition {
    
    DMLocationRequest* request = [[DMLocationRequest alloc] initWithType:DMLocationRequestTypeLocationAndReverse];
    request.accuracy = accuracy;
    request.reverseCoordinates = reverseCoordinates;
    request.completitionHandler = completition;
    return request;
}

+ (DMLocationRequest *) coordinatesFromAddress:(NSString *) address
                                  completition:(DMLocationRequestReverseAddressCoordinates) completition {
    DMLocationRequest* request = [[DMLocationRequest alloc] initWithType:DMLocationRequestTypeCoordinatesFromAddress];
    request.addressLine = address;
    request.coordFromAdrCompletitionHandler = completition;
    return request;
}

- (void)operationDidStart {
    if (operationType == DMLocationRequestTypeLocationAndReverse) {
        BOOL locationCacheIsValid = (self.useCachedLocation ? ([DMLocationManager shared].cachedLocationAge < [DMLocationManager shared].maxCacheAge) : NO);
        if (locationCacheIsValid)
            currentLocation = [DMLocationManager shared].cachedLocation;
        
        BOOL locationIsAccurated = [self locationIsValidForAccuracy:self.accuracy];
        if (!locationCacheIsValid || !locationIsAccurated) {
            locationManager = [[CLLocationManager alloc] init];
            [locationManager setDelegate:self];
            [locationManager startUpdatingLocation];
            timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeout target:self selector:@selector(timeoutReached:) userInfo:nil repeats:NO];
        } else {
            [self reverseLocation];
        }
    } else if (operationType == DMLocationRequestTypeReverseLocation) {
        [self reverseLocation];
    } else if (operationType == DMLocationRequestTypeCoordinatesFromAddress) {
        [self obtainCoordinatesFromAddress];
    } else {
        [self finishOperationWithError:[NSError errorWithDomain:@"Unknown operation code" code:0 userInfo:nil]];
    }
}

- (void)operationWillFinish {
    [self cancelLocationSearch];
}

- (void) cancelLocationSearch {
    [timeoutTimer invalidate];
    timeoutTimer = nil;
    [locationManager stopUpdatingLocation];
    [locationManager setDelegate:nil];
    locationManager = nil;
}

- (void) timeoutReached:(id) sender {
    [self cancelLocationSearch];
    
    NSError *timeoutError = [NSError errorWithDomain:NSLocalizedStringFromTable(@"Error_Timeout", @"DMLocationManager", nil) code:0 userInfo:nil];
    if (completitionHandler != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completitionHandler(currentLocation,nil,timeoutError);
        });
    }
    [self finishOperationWithError:timeoutError];
}

- (void) obtainCoordinatesFromAddress {
    NSString *urlToCall = [NSString stringWithFormat: kGoogleMapsReverseGeocodeURL,[addressLine stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlToCall]];
    [request setTimeoutInterval: self.timeout];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *dataError) {
                               if (dataError != nil || data.length == 0) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       coordFromAdrCompletitionHandler(nil,dataError);
                                   });
                               } else {
                                   NSError* jsonError = nil;
                                   NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       if (jsonError != nil)
                                           coordFromAdrCompletitionHandler(nil,jsonError);
                                       else
                                           coordFromAdrCompletitionHandler([self locationFromGoogleResultDictionary:resultDict],nil);
                                   });
                               }
                               [self finishOperationWithError:dataError];
                           }];
}

- (CLLocation *) locationFromGoogleResultDictionary:(NSDictionary *) JSONResultDict {
    NSDictionary    *resultsDict = [JSONResultDict valueForKey:  @"results"];   // get the results dictionary
    NSDictionary   *geometryDict = [   resultsDict valueForKey: @"geometry"];   // geometry dictionary within the  results dictionary
    NSDictionary   *locationDict = [  geometryDict valueForKey: @"location"];   // location dictionary within the geometry dictionary
    
    NSArray *latArray = [locationDict valueForKey: @"lat"]; NSString *latString = [latArray lastObject];     // (one element) array entries provided by the json parser
    NSArray *lngArray = [locationDict valueForKey: @"lng"]; NSString *lngString = [lngArray lastObject];     // (one element) array entries provided by the json parser
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude: [latString doubleValue] longitude:[lngString doubleValue]];
    return location;
}

- (void) reverseLocation {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:currentLocation
                   completionHandler:^(NSArray *cl_placemarks, NSError *cl_error) {
                       CLPlacemark* placemark = [cl_placemarks lastObject];
                       if (completitionHandler != nil) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               completitionHandler(currentLocation,placemark,cl_error);
                           });
                       }
                       
                       if (geocoderCompletitionHandler != nil) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               geocoderCompletitionHandler(placemark,
														   [placemark.addressDictionary objectForKey:@"City"],
														   [placemark.addressDictionary objectForKey:@"City"],
														   nil,
														   cl_error);
                           });
                       }
                       [self finishOperationWithError:nil];
                   }];
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
    currentLocation = newLocation;
    [DMLocationManager shared].cachedLocation = newLocation;
    
    BOOL isValidForAccuracy = [self locationIsValidForAccuracy:self.accuracy];
    if (isValidForAccuracy) {
        if (!self.reverseCoordinates) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completitionHandler(currentLocation,nil,nil);
            });
            [self finishOperationWithError:nil];
        } else {
            [self cancelLocationSearch];
            [self reverseLocation];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    if (completitionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completitionHandler(nil,nil,error);
        });
    }
    [self finishOperationWithError:error];
}

- (BOOL) locationIsValidForAccuracy:(CLLocationAccuracy) desideredAccuracy {
    if (currentLocation == nil)
        return NO;
    BOOL isValid = YES;
    // Use the highest-level of accuracy and combine it with additional sensor data.
    // This level of accuracy is intended for use in navigation applications that
    // require precise position information at all times and are intended to be used only while the
    if (desideredAccuracy == kCLLocationAccuracyBestForNavigation || desideredAccuracy == kCLLocationAccuracyBest)
        isValid= (currentLocation.horizontalAccuracy    < kDMLocManage_MinAccuracy_BestNavigation);
    
    // Accurate to within ten meters of the desired target.
    else if (desideredAccuracy == kCLLocationAccuracyNearestTenMeters)
        isValid= (currentLocation.horizontalAccuracy    <= kDMLocManage_MinAccuracy_TenMeters);
    
    // Accurate to within one hundred meters.
    else if (desideredAccuracy == kCLLocationAccuracyHundredMeters)
        isValid= (currentLocation.horizontalAccuracy    <= kDMLocManage_MinAccuracy_HundredMeters);
    
    // Accurate to the nearest kilometer.
    else if (desideredAccuracy == kCLLocationAccuracyKilometer)
        isValid= (currentLocation.horizontalAccuracy    <= kDMLocManage_MinAccuracy_Kilometer);
    
    // Accurate to the nearest three kilometers.
    else if (desideredAccuracy == kCLLocationAccuracyThreeKilometers)
        isValid= (currentLocation.horizontalAccuracy    <= kDMLocManage_MinAccuracy_3Kilometers);
    
    return isValid; // otherwise we will assume it's okay (it should never happend btw)
}

@end
