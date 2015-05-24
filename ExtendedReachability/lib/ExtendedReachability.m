//
//  ExtendedReachability.m
//  ExtendedReachability
//
//  Created by Goppinath Thurairajah on 03.05.15.
//  Copyright (c) 2015 Goppinath Thurairajah. All rights reserved.
//

#import "ExtendedReachability.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>

#pragma mark - Supporting functions

#define kShouldPrintReachabilityFlags 1

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char* comment) {
    
#if kShouldPrintReachabilityFlags
    
    NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
          (flags & kSCNetworkReachabilityFlagsIsWWAN)				? 'W' : '-',
          (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
          
          (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
          (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
          (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
          (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
          comment
          );
#endif
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    
#pragma unused (target, flags)
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    NSCAssert([(__bridge NSObject*) info isKindOfClass: [ExtendedReachability class]], @"info was wrong class in ReachabilityCallback");
    
    ExtendedReachability *extendedReachability = (__bridge ExtendedReachability *)info;
    
        if (extendedReachability.reachabilityDidChangeHandler) {
    
            extendedReachability.reachabilityDidChangeHandler(extendedReachability);
        }
}

#pragma mark - Reachability implementation

@interface ExtendedReachability ()

@property (nonatomic) BOOL alwaysReturnLocalWiFiStatus; //default is NO
@property (nonatomic) SCNetworkReachabilityRef networkreachabilityRef;

@property (copy, nonatomic, readwrite) void (^reachabilityDidChangeHandler)(ExtendedReachability *changedReachability);

@end

@implementation ExtendedReachability

+ (instancetype)reachabilityWithNetworkReachabilityRef:(SCNetworkReachabilityRef)networkReachabilityRef {
    
    ExtendedReachability *extendedReachability;
    
    if (networkReachabilityRef) {
        
        extendedReachability = [ExtendedReachability new];
        
        [extendedReachability setNetworkreachabilityRef:networkReachabilityRef];
        [extendedReachability setAlwaysReturnLocalWiFiStatus:NO];
    }
    
    return extendedReachability;
}


+ (instancetype)reachabilityWithHostName:(NSString *)hostName {

    return [self reachabilityWithNetworkReachabilityRef:SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String])];
}

+ (instancetype)reachabilityWithHostname:(NSString *)hostname {
    
    return [self reachabilityWithNetworkReachabilityRef:SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String])];
}

+ (instancetype)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress {
    
    return [self reachabilityWithNetworkReachabilityRef:SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress)];
}

+ (instancetype)reachabilityForInternetConnection {
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    return [self reachabilityWithAddress:&zeroAddress];
}

+ (instancetype)reachabilityForLocalWiFi {
    
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0.
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    
    ExtendedReachability *extendedReachability = [self reachabilityWithAddress:&localWifiAddress];
    
    [extendedReachability setAlwaysReturnLocalWiFiStatus:YES];
    
    return extendedReachability;
}

#pragma mark - Start and stop notifier

- (BOOL)startNotifier {

    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    if (SCNetworkReachabilitySetCallback(_networkreachabilityRef, ReachabilityCallback, &context)) {
        
        if (SCNetworkReachabilitySetDispatchQueue(_networkreachabilityRef, dispatch_queue_create("com.goppinath.ExtendedReachability", nil))) {
            
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)startNotifierWithReachabilityDidChangeHandler:(void (^)(ExtendedReachability *changedReachability))reachabilityDidChangeHandler {
    
    _reachabilityDidChangeHandler = reachabilityDidChangeHandler;
    
    return [self startNotifier];
}

- (void)stopNotifier {
    
    if (_networkreachabilityRef) {
        
        SCNetworkReachabilitySetCallback(_networkreachabilityRef, nil, nil);
        
        SCNetworkReachabilitySetDispatchQueue(_networkreachabilityRef, nil);
    }
}

- (void)dealloc {
    
    [self stopNotifier];
    
    if (_networkreachabilityRef) {
        
        CFRelease(_networkreachabilityRef);
    }
}

- (BOOL)isReachable {
    
    SCNetworkReachabilityFlags networkReachabilityFlags;
    
    if (SCNetworkReachabilityGetFlags(_networkreachabilityRef, &networkReachabilityFlags)) {
        
        if (networkReachabilityFlags & kSCNetworkReachabilityFlagsReachable) {
            
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isReachableViaWWAN {
    
    SCNetworkReachabilityFlags networkReachabilityFlags;
    
    if (SCNetworkReachabilityGetFlags(_networkreachabilityRef, &networkReachabilityFlags)) {
        
        if (networkReachabilityFlags & kSCNetworkReachabilityFlagsReachable) {
            
            if ((networkReachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
                
                /*
                 ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
                 */
                return ReachableViaWWAN;
            }
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isReachableViaWiFi {
    
    SCNetworkReachabilityFlags networkReachabilityFlags;
    
    if (SCNetworkReachabilityGetFlags(_networkreachabilityRef, &networkReachabilityFlags)) {
        
        if (networkReachabilityFlags & kSCNetworkReachabilityFlagsReachable) {
            
            if ((networkReachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
                
                return NO;
            }
            else {
                
                if ((networkReachabilityFlags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
                    
                    /*
                     If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
                     */
                    return YES;
                }
                
                if ((((networkReachabilityFlags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (networkReachabilityFlags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
                    
                    /*
                     ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
                     */
                    
                    if ((networkReachabilityFlags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                        
                        /*
                         ... and no [user] intervention is needed...
                         */
                        return YES;
                    }
                }
            }
        }
    }
    
    return NO;
}

#pragma mark - Network Flag Handling

- (NetworkStatus)localWiFiStatusForFlags:(SCNetworkReachabilityFlags)flags {
    
    PrintReachabilityFlags(flags, "localWiFiStatusForFlags");
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect)) {
        
        return ReachableViaWiFi;
    }
    
    return NotReachable;
}


- (NetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
    
    PrintReachabilityFlags(flags, "networkStatusForFlags");
    
    if ([self isReachableViaWWAN]) {
        
        return ReachableViaWWAN;
    }
    else if ([self isReachableViaWiFi]) {
        
        return ReachableViaWiFi;
    }
    else {
        
        return NotReachable;
    }
}


- (BOOL)connectionRequired {
    
    NSAssert(_networkreachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
    
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(_networkreachabilityRef, &flags)) {
        
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    
    return NO;
}


- (NetworkStatus)currentReachabilityStatus {
    
    NSAssert(_networkreachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");
    
    NetworkStatus returnValue = NotReachable;
    
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(_networkreachabilityRef, &flags)) {
        
        if (_alwaysReturnLocalWiFiStatus) {
            
            returnValue = [self localWiFiStatusForFlags:flags];
        }
        else {
            
            returnValue = [self networkStatusForFlags:flags];
        }
    }
    
    return returnValue;
}

@end
