//
//  CoreSimulator.h
//  ControlRoom
//
//  Created by Dave DeLong on 2/14/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreSimulator: NSObject

@property (class, readonly) BOOL canRegisterForSimulatorNotifications;

+ (NSUInteger)registerForSimulatorNotifications:(void(^)(void))handler;
+ (void)unregisterFromSimulatorNotifications:(NSUInteger)token;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
