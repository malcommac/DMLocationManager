//
//  DMLocationRequest.h
//  DMLocationManagerExample
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 11/10/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//  Distribuited under MIT License (http://opensource.org/licenses/MIT)
//

#import "DMOperation.h"
#import <CoreLocation/CoreLocation.h>

// DMLocationRequest OPERATION TYPE
enum {
    DMLocationRequestTypeLocationAndReverse     = 0,    // Get current location and [optionally] reverse location
    DMLocationRequestTypeReverseLocation        = 1,    // Reverse given location
    DMLocationRequestTypeCoordinatesFromAddress = 2     // Obtain coordinates from given location
}; typedef NSUInteger DMLocationRequestType;


// COMPLETITION HANDLERS
typedef void(^DMLocationRequestHandler)(CLLocation *location, CLPlacemark *placemark, NSError *error);
typedef void(^DMLocationRequestReverseGeoHandler)(CLPlacemark *placemark, NSString *address,NSString *locality,NSArray* otherPlacemarks,NSError *error);
typedef void(^DMLocationRequestReverseAddressCoordinates)(CLLocation* location,NSError *error);
typedef void(^DMLocationSignificantChangesHandler)(CLLocation* location,NSError *error, BOOL *stop);

@interface DMLocationRequest : DMOperation {
    
}

@property (assign)      CLLocationAccuracy          accuracy;               // Desidered accuracy
@property (assign)      NSTimeInterval              timeout;                // Max search timeout. If desidered accuracy is not achieved in this
                                                                            // interval operation return error (but you can found cached location in operation.currentLocation property)
@property (assign)      BOOL                        useCachedLocation;      // YES if you want to use cached location if available (cached will be used only if accuracy is validated and
                                                                            // cached location timestamp age < DMLocationManager's maxCacheAge property

@property (assign)      BOOL                        reverseCoordinates;     // YES if you want to reverse coordinates and get location's placemark
                                                                            // (works only with operationType = DMLocationRequestTypeLocationAndReverse)
@property (readonly)    CLLocation*                 currentLocation;        // Last given location (supposedly the most accurate?)


// Create new request to obtain current location with a desidered accuracy.
// (NOTE: You should not use this directly but only via DMLocationManager public methods)
+ (DMLocationRequest *) currentLocation:(BOOL) reverseCoordinates
                               accuracy:(CLLocationAccuracy) accuracy
                           completition:(DMLocationRequestHandler) completition;

// Create new request to obtain address string from a given location object
// (NOTE: You should not use this directly but only via DMLocationManager public methods)
+ (DMLocationRequest *) addressFromLocation:(CLLocation *) location
                               completition:(DMLocationRequestReverseGeoHandler) completition;

// Create new request to obtain coordinates from a given address
// (NOTE: You should not use this directly but only via DMLocationManager public methods)
+ (DMLocationRequest *) coordinatesFromAddress:(NSString *) address
                                  completition:(DMLocationRequestReverseAddressCoordinates) completition;

// YES if last obtained location (currentLocation) is valid for a given accuracy value
- (BOOL) locationIsValidForAccuracy:(CLLocationAccuracy) desideredAccuracy;

@end
