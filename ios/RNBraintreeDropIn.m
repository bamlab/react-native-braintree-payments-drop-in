#import "RNBraintreeDropIn.h"
#import <React/RCTUtils.h>
#import "BTThreeDSecureRequest.h"
#import "BTThreeDSecurePostalAddress.h"
#import "BTThreeDSecureAdditionalInformation.h"

@implementation RNBraintreeDropIn

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(show,
                 showWithOptions:(NSDictionary*)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* clientToken = options[@"clientToken"];
    if (!clientToken) {
        reject(@"NO_CLIENT_TOKEN", @"You must provide a client token", nil);
        return;
    }

    BTDropInRequest *request = [[BTDropInRequest alloc] init];

    NSDictionary* threeDSecureOptions = options[@"threeDSecure"];
    if (threeDSecureOptions) {
        NSNumber* threeDSecureAmount = threeDSecureOptions[@"amount"];
        if (!threeDSecureAmount) {
            reject(@"NO_3DS_AMOUNT", @"You must provide an amount for 3D Secure", nil);
            return;
        }

        BTThreeDSecureRequest *threeDSecureRequest = [[BTThreeDSecureRequest alloc] init];
        threeDSecureRequest.amount = [NSDecimalNumber decimalNumberWithString:threeDSecureAmount.stringValue];
        threeDSecureRequest.versionRequested = BTThreeDSecureVersion2;

        NSString *threeDSecureEmail = threeDSecureOptions[@"email"];
        if(threeDSecureEmail){
            threeDSecureRequest.email = threeDSecureEmail;
        }

        NSDictionary* threeDSecureBillingAddress = threeDSecureOptions[@"billingAddress"];
        if(threeDSecureBillingAddress){
            BTThreeDSecurePostalAddress *billingAddress = [BTThreeDSecurePostalAddress new];
            // BTThreeDSecurePostalAddress *billingAddress = [[BTThreeDSecurePostalAddress alloc] init];

            if(threeDSecureBillingAddress[@"givenName"]){
                billingAddress.givenName = threeDSecureBillingAddress[@"givenName"];
            }
            if(threeDSecureBillingAddress[@"surname"]){
                billingAddress.surname = threeDSecureBillingAddress[@"surname"];
            }
            if(threeDSecureBillingAddress[@"streetAddress"]){
                billingAddress.streetAddress = threeDSecureBillingAddress[@"streetAddress"];
            }
            if(threeDSecureBillingAddress[@"extendedAddress"]){
                billingAddress.extendedAddress = threeDSecureBillingAddress[@"extendedAddress"];
            }
            if(threeDSecureBillingAddress[@"locality"]){
                billingAddress.locality = threeDSecureBillingAddress[@"locality"];
            }
            if(threeDSecureBillingAddress[@"region"]){
                billingAddress.region = threeDSecureBillingAddress[@"region"];
            }
            if(threeDSecureBillingAddress[@"countryCodeAlpha2"]){
                billingAddress.countryCodeAlpha2 = threeDSecureBillingAddress[@"countryCodeAlpha2"];
            }
            if(threeDSecureBillingAddress[@"postalCode"]){
                billingAddress.postalCode = threeDSecureBillingAddress[@"postalCode"];
            }
            if(threeDSecureBillingAddress[@"phoneNumber"]){
                billingAddress.phoneNumber = threeDSecureBillingAddress[@"phoneNumber"];
            }
            threeDSecureRequest.billingAddress = billingAddress;
        }

        request.threeDSecureRequest = threeDSecureRequest;

    }

    BTDropInController *dropIn = [[BTDropInController alloc] initWithAuthorization:clientToken request:request handler:^(BTDropInController * _Nonnull controller, BTDropInResult * _Nullable result, NSError * _Nullable error) {
            [self.reactRoot dismissViewControllerAnimated:YES completion:nil];

            if (error != nil) {
                reject(error.localizedDescription, error.localizedDescription, error);
            } else if (result.canceled) {
                reject(@"USER_CANCELLATION", @"The user cancelled", nil);
            } else {
                if (threeDSecureOptions && [result.paymentMethod isKindOfClass:[BTCardNonce class]]) {
                    BTCardNonce *cardNonce = (BTCardNonce *)result.paymentMethod;
                    if (!cardNonce.threeDSecureInfo.liabilityShiftPossible && cardNonce.threeDSecureInfo.wasVerified) {
                        reject(@"3DSECURE_NOT_ABLE_TO_SHIFT_LIABILITY", @"3D Secure liability cannot be shifted", nil);
                    } else if (!cardNonce.threeDSecureInfo.liabilityShifted && cardNonce.threeDSecureInfo.wasVerified) {
                        reject(@"3DSECURE_LIABILITY_NOT_SHIFTED", @"3D Secure liability was not shifted", nil);
                    } else {
                        [[self class] resolvePayment :result resolver:resolve];
                    }
                } else {
                    [[self class] resolvePayment :result resolver:resolve];
                }
            }
        }];

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

@end
