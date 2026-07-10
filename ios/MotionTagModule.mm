#import "MotionTagModule.h"

#import <React/RCTLog.h>
// MotionTagSDK ships no Objective-C headers since v7 — it is a pure Swift module. All SDK
// access goes through MotionTagDelegateImpl, whose generated header omits the (non-@objc)
// MotionTagDelegate conformance, so nothing here needs to see the SDK.
// Swift generated header: CocoaPods only exposes it via the framework-style
// include when the pod is built as a framework (use_frameworks!). In the
// default static-library mode it stays in DerivedSources and is only
// reachable via the quoted form.
#if __has_include(<RNMotionTag/RNMotionTag-Swift.h>)
#import <RNMotionTag/RNMotionTag-Swift.h>
#else
#import "RNMotionTag-Swift.h"
#endif
#import <RNMotionTagSpec/RNMotionTagSpec.h>

// Codegen protocol conformance lives here, not on the public @interface,
// so the pod's Swift module can be built without ingesting the C++ codegen
// header through the umbrella.
@interface MotionTagModule () <NativeMotionTagSpec>
@end

@implementation MotionTagModule {
    BOOL _hasListeners;
}

RCT_EXPORT_MODULE(MotionTag)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"MotionTagEvent"];
}

// MotionTagDelegateImpl is @MainActor-isolated (the SDK's delegate protocol requires it), so
// every call into it below hops to the main queue first.
- (void)startObserving
{
    _hasListeners = YES;
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [MotionTagDelegateImpl.shared setEventCallback:^(NSDictionary<NSString *, id> *event) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && strongSelf->_hasListeners) {
                [strongSelf sendEventWithName:@"MotionTagEvent" body:event];
            }
        }];
    });
}

- (void)stopObserving
{
    _hasListeners = NO;
}

#pragma mark - NativeMotionTagSpec

- (void)start:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MotionTagDelegateImpl.shared startTracking];
        resolve(nil);
    });
}

- (void)stop:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MotionTagDelegateImpl.shared stopTracking];
        resolve(nil);
    });
}

- (void)setUserToken:(NSString *)jwt
             resolve:(RCTPromiseResolveBlock)resolve
              reject:(RCTPromiseRejectBlock)reject
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MotionTagDelegateImpl.shared setUserToken:jwt];
        resolve(nil);
    });
}

- (void)getUserToken:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    // Not wired to the SDK yet. Resolve to nil so JS callers can detect "not implemented here".
    resolve([NSNull null]);
}

- (void)isTrackingActive:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    dispatch_async(dispatch_get_main_queue(), ^{
        resolve(@([MotionTagDelegateImpl.shared isTrackingActive]));
    });
}

- (void)isPowerSaveModeEnabled:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    // Android-only. Resolve false on iOS to match Flutter SDK parity.
    resolve(@NO);
}

- (void)isBatteryOptimizationsEnabled:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    // Android-only. Resolve false on iOS to match Flutter SDK parity.
    resolve(@NO);
}

- (void)getWifiOnlyDataTransfer:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    // Not wired to the SDK yet.
    resolve(@NO);
}

- (void)setWifiOnlyDataTransfer:(BOOL)wifiOnly
                        resolve:(RCTPromiseResolveBlock)resolve
                         reject:(RCTPromiseRejectBlock)reject
{
    reject(@"UNSUPPORTED", @"setWifiOnlyDataTransfer is not implemented on iOS.", nil);
}

- (void)clearData:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    reject(@"UNSUPPORTED", @"clearData is not implemented on iOS.", nil);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMotionTagSpecJSI>(params);
}

@end
