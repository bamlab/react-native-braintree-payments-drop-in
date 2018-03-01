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

### With 3D Secure

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
