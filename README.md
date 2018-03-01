# react-native-braintree-drop-in

## Getting started

`$ npm install react-native-braintree-drop-in --save`

### Mostly automatic installation

`$ react-native link react-native-braintree-drop-in`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-braintree-drop-in` and add `RNBraintreeDropIn.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNBraintreeDropIn.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import tech.bam.RNBraintreeDropIn.RNBraintreeDropInPackage;` to the imports at the top of the file
  - Add `new RNBraintreeDropInPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-braintree-drop-in'
  	project(':react-native-braintree-drop-in').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-braintree-drop-in/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-braintree-drop-in')
  	```


## Usage
```javascript
import RNBraintreeDropIn from 'react-native-braintree-drop-in';

// TODO: What to do with the module?
RNBraintreeDropIn;
```
