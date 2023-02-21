require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "RNBraintreeDropIn"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/Thinkei/react-native-braintree-payments-drop-in.git", :tag => "v#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.requires_arc = true

  s.dependency "React"
  s.dependency "BraintreeDropIn", '~> 7.4'
  s.dependency 'Braintree/DataCollector'
  s.dependency 'Braintree/PaymentFlow'
end
