package tech.bam.RNBraintreeDropIn;

import android.app.Activity;
import android.content.Intent;

import androidx.appcompat.app.AppCompatActivity;

import com.braintreepayments.api.dropin.utils.PaymentMethodType;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.braintreepayments.api.dropin.DropInActivity;
import com.braintreepayments.api.dropin.DropInRequest;
import com.braintreepayments.api.dropin.DropInResult;
import com.braintreepayments.api.models.PaymentMethodNonce;
import com.braintreepayments.api.models.CardNonce;
import com.braintreepayments.api.models.ThreeDSecureInfo;
import com.braintreepayments.api.models.ThreeDSecureRequest;

public class RNBraintreeDropInModule extends ReactContextBaseJavaModule {

  private Promise mPromise;
  private static final int DROP_IN_REQUEST = 0x444;

  private boolean isVerifyingThreeDSecure = false;
  private static final String GET_LAST_USED_CARD_ERROR = "GET_LAST_USED_CARD_ERROR";

  public RNBraintreeDropInModule(ReactApplicationContext reactContext) {
    super(reactContext);
    reactContext.addActivityEventListener(mActivityListener);
  }

  @ReactMethod
  public void show(final ReadableMap options, final Promise promise) {
    isVerifyingThreeDSecure = false;

    if (!options.hasKey("clientToken")) {
      promise.reject("NO_CLIENT_TOKEN", "You must provide a client token");
      return;
    }

    Activity currentActivity = getCurrentActivity();
    if (currentActivity == null) {
      promise.reject("NO_ACTIVITY", "There is no current activity");
      return;
    }

    DropInRequest dropInRequest = new DropInRequest()
      .clientToken(options.getString("clientToken"))
      .disablePayPal()
      .collectDeviceData(true)
      .vaultManager(true);

    if (options.hasKey("threeDSecure")) {
      final ReadableMap threeDSecureOptions = options.getMap("threeDSecure");
      if (!threeDSecureOptions.hasKey("amount")) {
        promise.reject("NO_3DS_AMOUNT", "You must provide an amount for 3D Secure");
        return;
      }

      isVerifyingThreeDSecure = true;

      ThreeDSecureRequest threeDSecureRequest = new ThreeDSecureRequest()
              .amount(String.valueOf(threeDSecureOptions.getDouble("amount")))
              .versionRequested(ThreeDSecureRequest.VERSION_2);


      dropInRequest
              .requestThreeDSecureVerification(true)
              .threeDSecureRequest(threeDSecureRequest);


    }

    mPromise = promise;
    currentActivity.startActivityForResult(dropInRequest.getIntent(currentActivity), DROP_IN_REQUEST);
  }

  @ReactMethod
  public void getLastUsedPaymentMethod(final ReadableMap options, final Promise promise) {

      if (!options.hasKey("clientToken")) {
          promise.reject("NO_CLIENT_TOKEN", "You must provide a client token");
          return;
      }
      Activity activity = getCurrentActivity();
      DropInResult.fetchDropInResult((AppCompatActivity) activity, options.getString("clientToken"), new DropInResult.DropInResultListener() {
          @Override
          public void onError(Exception exception) {
              // an error occurred
              promise.reject(GET_LAST_USED_CARD_ERROR, exception.getMessage());
          }

          @Override
          public void onResult(DropInResult result) {
              mPromise = promise;
              if (result.getPaymentMethodType() != null && result.getPaymentMethodNonce() != null) {
                  if (result.getPaymentMethodType() == PaymentMethodType.GOOGLE_PAYMENT) {
                      // The last payment method the user used was GooglePayment. The GooglePayment
                      // flow will need to be performed by the user again at the time of checkout
                      // using GooglePayment#requestPayment(...). No PaymentMethodNonce will be
                      // present in result.getPaymentMethodNonce(), this is only an indication that
                      // the user last used GooglePayment.
                      // 2nd note: I'm not handling google pay since we don't need it on our feat yet.
                      promise.reject("NOT_SUPPORT_GOOGLE_PAY", "We currently not implement Google pay yet");
                  } else {
                      // show the payment method in your UI and charge the user at the
                      // time of checkout using the nonce: paymentMethod.getNonce()
                      PaymentMethodNonce paymentMethod = result.getPaymentMethodNonce();
                      String deviceData = result.getDeviceData();
                      WritableMap cardInfo = getCardInfo(paymentMethod, deviceData);
                      promise.resolve(cardInfo);
                  }
              } else {
                  // there was no existing payment method
                  promise.reject(GET_LAST_USED_CARD_ERROR, "No existing lasted card");
              }
              mPromise = null;
          }
      });
  }

  private final ActivityEventListener mActivityListener = new BaseActivityEventListener() {
    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
      super.onActivityResult(requestCode, resultCode, data);

      if (requestCode != DROP_IN_REQUEST || mPromise == null) {
        return;
      }

      if (resultCode == Activity.RESULT_OK) {
        DropInResult result = data.getParcelableExtra(DropInResult.EXTRA_DROP_IN_RESULT);
        PaymentMethodNonce paymentMethodNonce = result.getPaymentMethodNonce();
        String deviceData = result.getDeviceData();

        if (isVerifyingThreeDSecure && paymentMethodNonce instanceof CardNonce) {
          CardNonce cardNonce = (CardNonce) paymentMethodNonce;
          ThreeDSecureInfo threeDSecureInfo = cardNonce.getThreeDSecureInfo();
          if (threeDSecureInfo.isLiabilityShiftPossible()) { // Card is eligible for 3D secure
            if (threeDSecureInfo.isLiabilityShifted()) { // 3D Secure authentication success
               resolvePayment(paymentMethodNonce, deviceData);
            } else {
               mPromise.reject("3DSECURE_LIABILITY_NOT_SHIFTED", "3D Secure liability was not shifted");
            }
          } else {
            // 3D Secure is not support, we allow users to continue without 3D Secure
            resolvePayment(paymentMethodNonce, deviceData);
          }
        } else {
          resolvePayment(paymentMethodNonce, deviceData);
        }
      } else if (resultCode == Activity.RESULT_CANCELED) {
        mPromise.reject("USER_CANCELLATION", "The user cancelled");
      } else {
        Exception exception = (Exception) data.getSerializableExtra(DropInActivity.EXTRA_ERROR);
        mPromise.reject(exception.getMessage(), exception.getMessage());
      }

      mPromise = null;
    }
  };

  private final void resolvePayment(PaymentMethodNonce paymentMethodNonce, String deviceData) {
    mPromise.resolve(getCardInfo(paymentMethodNonce, deviceData));
  }

  private WritableMap getCardInfo(PaymentMethodNonce paymentMethodNonce, String deviceData) {
    WritableMap jsResult = Arguments.createMap();
    jsResult.putString("nonce", paymentMethodNonce.getNonce());
    jsResult.putString("type", paymentMethodNonce.getTypeLabel());
    jsResult.putString("description", paymentMethodNonce.getDescription());
    jsResult.putBoolean("isDefault", paymentMethodNonce.isDefault());
    jsResult.putString("deviceData", deviceData);

    return jsResult;
  }

  @Override
  public String getName() {
    return "RNBraintreeDropIn";
  }
}
