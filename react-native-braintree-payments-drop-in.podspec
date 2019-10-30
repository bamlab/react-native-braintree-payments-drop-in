require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-braintree-payments-drop-in"
  s.version      = package["version"]
  s.summary      = package['description']
  s.author       = package['author'] 
  s.homepage     = package['homepage']
  s.license      = package['license']
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/Thinkei/react-native-braintree-payments-drop-in.git", :tag => "v#{s.version}" }
  s.source_files  = "ios/*.{h,m}"
  s.dependency "React"
  s.dependency "BraintreeDropIn", '~> 6.5.0'
  s.dependency 'Braintree/DataCollector'
  s.dependency 'Braintree/PaymentFlow'
end
