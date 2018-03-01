#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#import "BraintreeCore.h"
#import "BraintreeDropIn.h"

@interface RNBraintreeDropIn : NSObject <RCTBridgeModule>

@property (nonatomic, strong) UIViewController *reactRoot;

@end
