//
//  DMAppDelegate.m
//  DMLocationManagerExample
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 11/10/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//

#import "DMAppDelegate.h"
#import "DMLocationManager.h"

#import "DMViewController.h"

@implementation DMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[DMViewController alloc] initWithNibName:@"DMViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    // A simple queue
    
    [[DMLocationManager shared] obtainCurrentLocationAndReverse:NO
                                                   withAccuracy:kCLLocationAccuracyHundredMeters
                                                       useCache:NO
                                                   completition:^(CLLocation *location, CLPlacemark *placemark, NSError *error) {
                                                       if (error != nil)
                                                           NSLog(@"Current location error: %@",error);
                                                       else
                                                           NSLog(@"Current location result: %@",(location != nil ? location : error));
                                                   }];
    
    [[DMLocationManager shared] obtainCurrentLocationAndReverse:YES
                                                   withAccuracy:kCLLocationAccuracyHundredMeters
                                                       useCache:YES
                                                   completition:^(CLLocation *location, CLPlacemark *placemark, NSError *error) {
                                                       if (error != nil)
                                                           NSLog(@"Current location/reverse error: %@",error);
                                                       else
                                                           NSLog(@"Current location/reverse result: %@,%@",location,placemark);
                                                   }];
    
    [[DMLocationManager shared] obtainAddressFromLocation:[[CLLocation alloc] initWithLatitude:41.90789 longitude:12.537514]
                                             completition:^(CLPlacemark *placemark, NSString *address,NSString *locality,NSError* error) {
                                                 if (error != nil)
                                                     NSLog(@"Address from location error: %@",error);
                                                 else 
                                                     NSLog(@"Address from location result: %@,%@ ",address,locality);
                                             }];
    
    [[DMLocationManager shared] obtainCoordinatesFromAddress:@"Via Vassallo 23, Roma"
                                                completition:^(CLLocation *location, NSError *error) {
                                                    NSLog(@"Coordinates from address: %@",(error != nil ? error : location));
                                                }];
     
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
