//
//  CoreSimulator.m
//  ControlRoom
//
//  Created by Dave DeLong on 2/14/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

#import "CoreSimulator.h"
#import "Control_Room-Swift.h"

/*
 This file uses private API in the CoreSimulator framework, which is located at /Library/Developer/PrivateFrameworks.

 The build settings for the project are modified to look inside /Library/Developer/PrivateFrameworks when linking,
 and they also specify to *weakly* link in CoreSimulator (ie, it's an "optional" framework).

 This means that if the app is run on a system that does not have CoreSimulator, then the symbols we need from it
 will all be nil.

 This allows us to dynamically check for the framework's existence (using NSClassFromString),
 and alter our behavior in the case that the framework is not properly loaded.
 */

/// A protocol to describe a "SimDeviceSet"
///
/// This is a class defined in CoreSimulator.framework that notifies registrants of changes to the simulators
@protocol SimDeviceSet_Protocol <NSObject>
- (NSUInteger)registerNotificationHandler:(void (^_Nonnull)(NSDictionary *))handler;
- (void)unregisterNotificationHandler:(NSUInteger)token error:(NSError **)error;
@end

/// A protocol to describe a "SimServiceContext"
///
/// This is how we can retrieve the SimDeviceSet
@protocol SimServiceContext_Protocol <NSObject>
+ (instancetype)sharedServiceContextForDeveloperDir:(NSString *)developerDirectory error:(NSError **)error;
- (id<SimDeviceSet_Protocol>)defaultDeviceSetWithError:(NSError **)error;
@end

id<SimDeviceSet_Protocol> deviceSet() {
    static id<SimDeviceSet_Protocol> set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // run `xcode-select -p` to get the active developer directory
        NSData *select = [NSTask execute:@"/usr/bin/xcode-select" arguments:@[@"-p"]];
        if (select == nil) { return; }

        NSString *developerDir = [[NSString alloc] initWithData:select encoding:NSUTF8StringEncoding];

        // if CoreSimulator isn't loaded, this will return nil
        id<SimServiceContext_Protocol> context = [NSClassFromString(@"SimServiceContext") sharedServiceContextForDeveloperDir:developerDir error:nil];
        set = [context defaultDeviceSetWithError:nil];
    });
    return set;
}

@implementation CoreSimulator

+ (BOOL)canRegisterForSimulatorNotifications {
    return deviceSet() != nil;
}

+ (NSUInteger)registerForSimulatorNotifications:(void (^)(void))handler {
    if (self.canRegisterForSimulatorNotifications == NO) { return NSNotFound; }
    return [deviceSet() registerNotificationHandler:^(id info) {
        handler();
    }];
}

+ (void)unregisterFromSimulatorNotifications:(NSUInteger)token {
    [deviceSet() unregisterNotificationHandler:token error:nil];
}

@end


