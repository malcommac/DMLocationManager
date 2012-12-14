//
//  DMLocationManager.h
//  DMLocationManagerExample
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 11/10/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//  Distribuited under MIT License (http://opensource.org/licenses/MIT)
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "DMOperation.h"
#import "DMLocationRequest.h"

@interface DMLocationManager : NSObject {

}

@property (readonly)            NSOperationQueue*       networkQueue;           // Main operation queue
                                                                                // (set a setMaxConcurrentOperationCount to limit concurrent operations. default is managed by the system)
@property (nonatomic,retain)    CLLocation*             cachedLocation;         // Globally cached location (the most accurate one)
@property (nonatomic,readonly)  NSTimeInterval          cachedLocationAge;      // Age of cached location from now (in seconds)
@property (nonatomic,assign)    NSTimeInterval          maxCacheAge;            // A cached value can be used only if it still valid in it's life interval

// Singleton
+ (DMLocationManager *) shared;

// Obtain user's current location (and optionally related placemark) with a desidered accuracy.
// (If useCachedLocationIfAvailable = YES you can get a cached value faster (if available and valid))
- (DMLocationRequest *) obtainCurrentLocationAndReverse:(BOOL) reverseGeocoder
                                           withAccuracy:(CLLocationAccuracy) accuracy
                                               useCache:(BOOL) useCachedLocationIfAvailable
                                           completition:(DMLocationRequestHandler) completition;

// Obtain address from given location
- (DMLocationRequest *) obtainAddressFromLocation:(CLLocation *) location
                                     completition:(DMLocationRequestReverseGeoHandler) completition;

// Obtain coordinates from a given address string
- (DMLocationRequest *) obtainCoordinatesFromAddress:(NSString *) address
                                        completition:(DMLocationRequestReverseAddressCoordinates) completition;

// Receive only significant location changes (low power monitor)
// Your updateBlock block will be added into the internal observer queue, so you can register one or more observers.
- (BOOL) queueSignificantLocationChangesMonitor:(DMLocationSignificantChangesHandler) updateBlock;

// Stop monitoring significant location changes (remove all block's observers)
- (void) stopMonitoringAllSignificantLocationChanges;

@end
