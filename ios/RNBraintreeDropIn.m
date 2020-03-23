#import "RNBraintreeDropIn.h"

@implementation RNBraintreeDropIn

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(getDeviceData:(NSDictionary*)options
                       resolver: (RCTPromiseResolveBlock)resolve
                       rejecter: (RCTPromiseRejectBlock)reject)
{
    NSString* clientToken = options[@"clientToken"];
    if (!clientToken) {
        reject(@"NO_CLIENT_TOKEN", @"You must provide a client token", nil);
        return;
    }

    BTAPIClient *apiClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    self.dataCollector = [[BTDataCollector alloc] initWithAPIClient:apiClient];

    [self.dataCollector collectCardFraudData:^(NSString * _Nonnull deviceData) {
        resolve(deviceData);
    }];
}

RCT_REMAP_METHOD(show,
                 showWithOptions:(NSDictionary*)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* clientToken = options[@"clientToken"];
    if (!clientToken) {
        reject(@"NO_CLIENT_TOKEN", @"You must provide a client token", nil);
        return;
    }

    self.options = options;
    BTDropInRequest *request = [[BTDropInRequest alloc] init];
    request.vaultManager = YES;
    request.paypalDisabled = YES;

    NSDictionary* threeDSecureOptions = options[@"threeDSecure"];
    if (threeDSecureOptions) {
        NSNumber* threeDSecureAmount = threeDSecureOptions[@"amount"];
        if (!threeDSecureAmount) {
            reject(@"NO_3DS_AMOUNT", @"You must provide an amount for 3D Secure", nil);
            return;
        }

        request.threeDSecureVerification = YES;
        request.amount = [threeDSecureAmount stringValue];
    }

    BTDropInController *dropIn = [[BTDropInController alloc] initWithAuthorization:clientToken request:request handler:^(BTDropInController * _Nonnull controller, BTDropInResult * _Nullable result, NSError * _Nullable error) {
        [self.reactRoot dismissViewControllerAnimated:YES completion:nil];

        if (error != nil) {
            reject(error.localizedDescription, error.localizedDescription, error);
            return;
        }

        if (result.cancelled) {
            reject(@"USER_CANCELLATION", @"The user cancelled", nil);
            return;
        }

        if (threeDSecureOptions && [result.paymentMethod isKindOfClass:[BTCardNonce class]]) {
            BTCardNonce *cardNonce = (BTCardNonce *)result.paymentMethod;
            if (cardNonce.threeDSecureInfo.wasVerified) {
                [self handleVerifiedCard :result resolver:resolve rejecter:reject];
            } else {
                [self performThreeDSecureVerification :result resolver:resolve rejecter:reject];
            }
                
        }}];

    if (dropIn != nil) {
        [self.reactRoot presentViewController:dropIn animated:YES completion:nil];
    } else {
        reject(@"INVALID_CLIENT_TOKEN", @"The client token seems invalid", nil);
    }
}

+ (void)resolvePayment:(BTDropInResult* _Nullable)result resolver:(RCTPromiseResolveBlock _Nonnull)resolve {
    NSMutableDictionary* jsResult = [NSMutableDictionary new];
    [jsResult setObject:result.paymentMethod.nonce forKey:@"nonce"];
    [jsResult setObject:result.paymentMethod.type forKey:@"type"];
    [jsResult setObject:result.paymentDescription forKey:@"description"];
    [jsResult setObject:[NSNumber numberWithBool:result.paymentMethod.isDefault] forKey:@"isDefault"];
    resolve(jsResult);
}

- (UIViewController*)reactRoot {
    UIViewController *root  = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *maybeModal = root.presentedViewController;

    UIViewController *modalRoot = root;

    if (maybeModal != nil) {
        modalRoot = maybeModal;
    }

    return modalRoot;
}

- (void)handleVerifiedCard:(BTDropInResult* _Nonnull)result resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    BTCardNonce *cardNonce = (BTCardNonce *)result.paymentMethod;
    if (cardNonce.threeDSecureInfo.liabilityShiftPossible) { // Card is eligible for 3D secure
        if (cardNonce.threeDSecureInfo.liabilityShifted) { // 3D Secure authentication success
            [[self class] resolvePayment :result resolver:resolve];
        } else { // 3D Secure authentication failed
            reject(@"3DSECURE_LIABILITY_NOT_SHIFTED", @"3D Secure liability was not shifted", nil);
        }
    } else { // 3D Secure is not support, we allow users to continue without 3D Secure
        [[self class] resolvePayment :result resolver:resolve];
    }
}

- (void)performThreeDSecureVerification:(BTDropInResult* _Nonnull)result resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    BTAPIClient* apiClient = [[BTAPIClient alloc] initWithAuthorization:self.options[@"clientToken"]];
    BTPaymentFlowDriver *paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:apiClient];
    paymentFlowDriver.viewControllerPresentingDelegate = self;

    BTThreeDSecureRequest *request = [[BTThreeDSecureRequest alloc] init];
    NSDictionary* threeDSecureOptions = self.options[@"threeDSecure"];
    request.amount = threeDSecureOptions[@"amount"];
    request.nonce = result.paymentMethod.nonce;

    [paymentFlowDriver startPaymentFlow:request completion:^(BTPaymentFlowResult * _Nonnull paymentFlowResult, NSError * _Nonnull paymentFlowError) {
        if (paymentFlowError) {
            if (paymentFlowError.code == BTPaymentFlowDriverErrorTypeCanceled) {
                reject(@"USER_CANCELLATION", @"The user cancelled", nil);
            } else {
                reject(paymentFlowError.localizedDescription, paymentFlowError.localizedDescription, paymentFlowError);
            }
            return;
        }

        BTThreeDSecureResult *threeDSecureResult = (BTThreeDSecureResult *)paymentFlowResult;
        result.paymentMethod = threeDSecureResult.tokenizedCard;
        [self handleVerifiedCard :result resolver:resolve rejecter:reject];
    }];
}

- (void)paymentDriver:(id)driver requestsPresentationOfViewController:(UIViewController *)viewController {
    [self.reactRoot presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentDriver:(id)driver requestsDismissalOfViewController:(UIViewController *)viewController {
    [self.reactRoot dismissViewControllerAnimated:YES completion:nil];
}

@end
