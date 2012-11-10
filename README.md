# DMLocationManager: iOS CLLocationManager made easy

DMLocationManager made iOS's Location Manager easy to use. It supports blocks, reverse geocoding (from coordinates to address) and viceversa (from address string to it's GPS coordinates).
It's all block based and uses NSOperationQueue to optimize multiple requests.

Daniele Margutti, <http://www.danielemargutti.com>
<me@danielemargutti.com>

It requires iOS >= 5.

## How to use it

DMLocationManager is a singleton class, so just call one of the available methods from [DMLocationManager shared] instance.

How to obtain current user's location:
``` objective-c
    [[DMLocationManager shared] obtainCurrentLocationAndReverse:NO
                                                   withAccuracy:kCLLocationAccuracyHundredMeters
                                                       useCache:NO
                                                   completition:^(CLLocation *location, CLPlacemark *placemark, NSError *error) {
                                             }];
```

How to obtain address's CLPlacemark object from CLLocation:
    
``` objective-c
[[DMLocationManager shared] obtainAddressFromLocation:[[CLLocation alloc] initWithLatitude:41.90789 longitude:12.537514]
                                             completition:^(CLPlacemark *placemark, NSString *address,NSString *locality,NSError* error) {
                                             }];
```

How to obtain GPS coordinates from address NSString:

``` objective-c
[[DMLocationManager shared] obtainCoordinatesFromAddress:@"Via Vassallo 23, Roma"
                                                completition:^(CLLocation *location, NSError *error) {
                                                }];
```


## Donations

If you found this project useful, please donate.
There’s no expected amount and I don’t require you to.
[MAKE YOUR DONATION](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=GS3DBQ69ZBKWJ)

## License (MIT)

Copyright (c) 2012 Daniele Margutti

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
