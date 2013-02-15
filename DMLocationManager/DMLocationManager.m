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

@interface DMLocationManager() <CLLocationManagerDelegate> {
    NSOperationQueue*   networkQueue;
    CLLocation*         cachedLocation;
    NSMutableArray*     sigLocChangesObservers;
    CLLocationManager*  sigLocChangesManager;
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
    DMLocationRequest *request = [DMLocationRequest currentLocation:reverseGeocoder
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

- (BOOL) queueSignificantLocationChangesMonitor:(DMLocationSignificantChangesHandler) updateBlock {
    if (![CLLocationManager significantLocationChangeMonitoringAvailable] || updateBlock == nil)
        return NO;
    
    if (sigLocChangesObservers == nil) {
        sigLocChangesObservers = [[NSMutableArray alloc] init];
        sigLocChangesManager = [[CLLocationManager alloc] init];
        [sigLocChangesManager setDelegate:self];
    }
    [sigLocChangesObservers addObject:[updateBlock copy]];
    [sigLocChangesManager startMonitoringSignificantLocationChanges];
    
    return YES;
}

- (void) stopMonitoringAllSignificantLocationChanges {
    [sigLocChangesObservers removeAllObjects];
    [sigLocChangesManager setDelegate:nil];
    [sigLocChangesManager stopMonitoringSignificantLocationChanges];
    sigLocChangesManager = nil;
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
    
    NSMutableIndexSet *unsubscribedObservers = [[NSMutableIndexSet alloc] init];
    __block BOOL needStopObservingMe = NO;
    [sigLocChangesObservers enumerateObjectsUsingBlock:^(DMLocationSignificantChangesHandler observer, NSUInteger idx, BOOL *stop) {
        observer(newLocation,nil,&needStopObservingMe);
        
        if (needStopObservingMe)
            [unsubscribedObservers addIndex:idx];
    }];
    [sigLocChangesObservers removeObjectsAtIndexes:unsubscribedObservers];
    if (sigLocChangesObservers.count == 0) [self stopMonitoringAllSignificantLocationChanges];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    
    NSMutableIndexSet *unsubscribedObservers = [[NSMutableIndexSet alloc] init];
    [sigLocChangesObservers enumerateObjectsUsingBlock:^(DMLocationSignificantChangesHandler observer, NSUInteger idx, BOOL *stop) {
        if (!stop)
            observer(nil,error,NO);
        else [unsubscribedObservers addIndex:idx];
    }];
    [sigLocChangesObservers removeObjectsAtIndexes:unsubscribedObservers];
    if (sigLocChangesObservers.count == 0) [self stopMonitoringAllSignificantLocationChanges];
}

@end
