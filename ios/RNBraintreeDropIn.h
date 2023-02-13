#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#import "BraintreeCore.h"
#import "BraintreeDropIn.h"
#import "BTCardNonce.h"
#import "BTDataCollector.h"
#import "BraintreePaymentFlow.h"

@interface RNBraintreeDropIn : NSObject <RCTBridgeModule, BTViewControllerPresentingDelegate>

@property (nonatomic, strong) UIViewController* _Nonnull reactRoot;

@property (nonatomic, strong) BTDataCollector *dataCollector;

@property (nonatomic, strong) NSDictionary *options;

+ (void)resolvePayment:(BTDropInResult* _Nullable)result resolver:(RCTPromiseResolveBlock _Nonnull)resolve;

@end
