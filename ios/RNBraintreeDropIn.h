#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#import "BraintreeCore.h"
#import "BraintreeDropIn.h"
#import "BTCardNonce.h"

@interface RNBraintreeDropIn : NSObject <RCTBridgeModule>

@property (nonatomic, strong) UIViewController* _Nonnull reactRoot;

+ (void)resolvePayment:(BTDropInResult* _Nullable)result resolver:(RCTPromiseResolveBlock _Nonnull)resolve;

@end
