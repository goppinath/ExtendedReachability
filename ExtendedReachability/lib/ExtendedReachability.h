//
//  ExtendedReachability.h
//  ExtendedReachability
//
//  Created by Goppinath Thurairajah on 03.05.15.
//  Copyright (c) 2015 Goppinath Thurairajah. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

typedef NS_ENUM(NSUInteger, NetworkStatus) {
    
    NotReachable        = 0,
    ReachableViaWiFi,
    ReachableViaWWAN
};

@interface ExtendedReachability : NSObject

@property (copy, nonatomic, readonly) void (^reachabilityDidChangeHandler)(ExtendedReachability *changedReachability);

/*!
 * Use to check the reachability of a given host name.
 */
+ (instancetype)reachabilityWithHostName:(NSString *)hostName;
+ (instancetype)reachabilityWithHostname:(NSString *)hostname;

/*!
 * Use to check the reachability of a given IP address.
 */
+ (instancetype)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress;

/*!
 * Checks whether the default route is available. Should be used by applications that do not connect to a particular host.
 */
+ (instancetype)reachabilityForInternetConnection;

/*!
 * Checks whether a local WiFi connection is available.
 */
+ (instancetype)reachabilityForLocalWiFi;

/*!
 * Start listening for reachability notifications on the current run loop.
 */
//- (BOOL)startNotifier;
- (BOOL)startNotifierWithReachabilityDidChangeHandler:(void (^)(ExtendedReachability *changedReachability))reachabilityDidChangeHandler;
- (void)stopNotifier;

- (NetworkStatus)currentReachabilityStatus;

/*!
 * WWAN may be available, but not active until a connection has been established. WiFi may require a connection for VPN on Demand.
 */
- (BOOL)connectionRequired;

- (BOOL)isReachable;
- (BOOL)isReachableViaWWAN;
- (BOOL)isReachableViaWiFi;

@end
