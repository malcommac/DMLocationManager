//
//  DMLocationManager.m
//  DMLocationManagerExample
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 11/10/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//  Distribuited under MIT License (http://opensource.org/licenses/MIT)
//

#import "DMLocationManager.h"

#define kDMLocationManagerMaxCacheLife          (60*2)      // 2 MINUTES CACHE LIFETIME

@interface DMLocationManager() {
    NSOperationQueue*   networkQueue;
    CLLocation*         cachedLocation;
}

@end

@implementation DMLocationManager

@synthesize networkQueue;
@synthesize cachedLocation;
@synthesize maxCacheAge;

+ (DMLocationManager *) shared {
    static dispatch_once_t pred;
    static DMLocationManager *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[DMLocationManager alloc] init];
    });
    return shared;
}

- (id) init {
    self = [super init];
    if (self) {
        networkQueue = [[NSOperationQueue alloc] init];
        [networkQueue setMaxConcurrentOperationCount:1];
        
        cachedLocation = nil;
        self.maxCacheAge = kDMLocationManagerMaxCacheLife;
    }
    return self;
}

- (DMLocationRequest *) obtainCurrentLocationAndReverse:(BOOL) reverseGeocoder
                                           withAccuracy:(CLLocationAccuracy) accuracy
                                               useCache:(BOOL) useCachedLocationIfAvailable
                                           completition:(DMLocationRequestHandler) completition {
    DMLocationRequest *request = [DMLocationRequest currentLocation:YES
                                                           accuracy:accuracy
                                                       completition:completition];
    request.useCachedLocation = useCachedLocationIfAvailable;
    [networkQueue addOperation:request];
    return request;
}

- (DMLocationRequest *) obtainAddressFromLocation:(CLLocation *) location
                                     completition:(DMLocationRequestReverseGeoHandler) completition {
    DMLocationRequest *request = [DMLocationRequest addressFromLocation:location completition:completition];
    [networkQueue addOperation:request];
    return request;
}

- (DMLocationRequest *) obtainCoordinatesFromAddress:(NSString *) address
                                        completition:(DMLocationRequestReverseAddressCoordinates) completition {
    DMLocationRequest *request = [DMLocationRequest coordinatesFromAddress:address completition:completition];
    [networkQueue addOperation:request];
    return request;
}

- (void) setCachedLocation:(CLLocation *)newCachedLocation {
    if ([self is:newCachedLocation moreAccurateThan:cachedLocation] || cachedLocation == nil)
        cachedLocation = newCachedLocation;
}

- (NSTimeInterval) cachedLocationAge {
    if (cachedLocation == nil) return NSUIntegerMax;
    return [[NSDate date] timeIntervalSinceDate:cachedLocation.timestamp];
}

- (BOOL) is:(CLLocation *) locationA moreAccurateThan:(CLLocation *) locationB {
    if (locationB == nil && locationA != nil)
        return YES;
    return ([locationA.timestamp timeIntervalSinceNow] < [locationB.timestamp timeIntervalSinceNow] &&
            (locationA.horizontalAccuracy <= locationB.horizontalAccuracy && locationA.verticalAccuracy <= locationB.verticalAccuracy));
}

@end
