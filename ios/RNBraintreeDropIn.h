#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#import "BraintreeCore.h"
#import "BraintreeDropIn.h"
#import "BTCardNonce.h"
@import PassKit;
#import "BraintreeApplePay.h"

@interface RNBraintreeDropIn : NSObject <RCTBridgeModule, PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, strong) UIViewController* _Nonnull reactRoot;
@property (nonatomic, strong) BTApplePayClient *applePayClient;
@property (nonatomic, strong) RCTPromiseResolveBlock _Nonnull resolve;
@property (nonatomic, strong) NSString* applePayAmout;

+ (void)resolvePayment:(BTDropInResult* _Nullable)result resolver:(RCTPromiseResolveBlock _Nonnull)resolve;

@end
