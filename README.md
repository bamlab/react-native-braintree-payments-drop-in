# react-native-braintree-drop-in

> React Native integration of Braintree Drop-in

*** for iOS only at the moment***

## Getting started

```bash
yarn add react-native-braintree-drop-in
```

### Mostly automatic installation

```bash
react-native link react-native-braintree-drop-in
```

#### iOS specific

You must have a iOS deployment target >= 9.0.

If you don't have a Podfile or are unsure on how to proceed, see the [CocoaPods](http://guides.cocoapods.org/using/using-cocoapods.html) usage guide.

In your `Podfile`, add:

```
pod 'BraintreeDropIn', '~> 6.0'
```

Then:

```bash
cd ios
pod repo update # optional and can be very long
pod install
```

### Configuration

#### 3D Secure

If you plan on using 3D Secure, you have to do the following.

##### Configure a new URL scheme

Add a bundle url scheme `payments` in your app Info via XCode or manually in the `Info.plist`.
In your `Info.plist`, you should have something like:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.myapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>payments</string>
        </array>
    </dict>
</array>
```

##### Update your code

In your `AppDelegate.m`:

```objective-c
#import "BraintreeCore.h"

...
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ...
    [BTAppSwitch setReturnURLScheme:[self getPaymentsURLScheme]];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    if ([url.scheme localizedCaseInsensitiveCompare:[self getPaymentsURLScheme]] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url options:options];
    }
    
    return [RCTLinkingManager application:application openURL:url options:options];
}

-(NSString *)getPaymentsURLScheme {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return [NSString stringWithFormat:@"%@.%@", bundleIdentifier, @"payments"];
}
```

## Usage

For the API, see the [Flow typings](./index.js.flow).

### Basic

```javascript
import BraintreeDropIn from 'react-native-braintree-drop-in';

BraintreeDropIn.show({
  clientToken: 'token',
})
.then(result => console.log(result))
.catch(error => console.warn(error));
```

### 3D Secure

```javascript
import BraintreeDropIn from 'react-native-braintree-drop-in';

BraintreeDropIn.show({
  clientToken: 'token',
  threeDSecure: {
    amount: 1.0,
  },
})
.then(result => console.log(result))
.catch(error => console.warn(error));
```
