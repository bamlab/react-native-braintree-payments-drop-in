package tech.bam.RNBraintreeDropIn;

import android.app.Activity;
import android.content.Intent;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.braintreepayments.api.dropin.DropInActivity;
import com.braintreepayments.api.dropin.DropInRequest;
import com.braintreepayments.api.dropin.DropInResult;

public class RNBraintreeDropInModule extends ReactContextBaseJavaModule {

  private Promise mPromise;
  private static final int DROP_IN_REQUEST = 0x444;

  public RNBraintreeDropInModule(ReactApplicationContext reactContext) {
    super(reactContext);
    reactContext.addActivityEventListener(mActivityListener);
  }

  @ReactMethod
  public void show(final ReadableMap options, final Promise promise) {
    if (!options.hasKey("clientToken")) {
      promise.reject("NO_CLIENT_TOKEN", "You must provide a client token");
      return;
    }

    Activity currentActivity = getCurrentActivity();
    if (currentActivity == null) {
      promise.reject("NO_ACTIVITY", "There is no current activity");
      return;
    }

    DropInRequest dropInRequest = new DropInRequest().clientToken(options.getString("clientToken"));

    if (options.hasKey("threeDSecure")) {
      final ReadableMap threeDSecureOptions = options.getMap("threeDSecure");
      if (!threeDSecureOptions.hasKey("amount")) {
        promise.reject("NO_3DS_AMOUNT", "You must provide an amount for 3D Secure");
        return;
      }

      dropInRequest
      .amount(String.valueOf(threeDSecureOptions.getDouble("amount")))
      .requestThreeDSecureVerification(true);
    }

    mPromise = promise;
    currentActivity.startActivityForResult(dropInRequest.getIntent(currentActivity), DROP_IN_REQUEST);
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
        String paymentMethodNonce = result.getPaymentMethodNonce().getNonce();
        mPromise.resolve(paymentMethodNonce);
      } else if (resultCode == Activity.RESULT_CANCELED) {
        mPromise.reject("USER_CANCELLATION", "The user cancelled");
      } else {
        Exception exception = (Exception) data.getSerializableExtra(DropInActivity.EXTRA_ERROR);
        mPromise.reject(exception.getMessage(), exception.getMessage());
      }

      mPromise = null;
    }
  };

  @Override
  public String getName() {
    return "RNBraintreeDropIn";
  }
}
