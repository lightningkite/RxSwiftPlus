#
# Be sure to run `pod lib lint RxSwiftProperty.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RxSwiftProperty'
  s.version          = '0.1.0'
  s.summary          = 'Use Rx to bind data to your views'

  s.description      = <<-DESC
  This adds the concept of Property to RxSwift, which allows immediate retrieval of the value without subscription, as well as contractually restricting completion and errors.
  Use Rx to bind data to your views.
                       DESC

  s.homepage         = 'https://github.com/UnknownJoe796/RxSwiftProperty'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'UnknownJoe796' => 'joseph@lightningkite.com' }
  s.source           = { :git => 'https://github.com/UnknownJoe796/RxSwiftProperty.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'RxSwiftProperty/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RxSwiftProperty' => ['RxSwiftProperty/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.subspec 'Core' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/Core"
    sub.dependency 'RxSwift', '~> 6.2.0'
    sub.dependency 'RxCocoa', '~> 6.2.0'
  end
  s.subspec 'Http' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/Http"
    sub.dependency 'Starscream'
  end
  s.subspec 'Resources' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/Resources"
    sub.dependency "RxSwiftProperty/Core"
  end
  s.subspec 'Bindings' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/Bindings"
    sub.dependency "RxSwiftProperty/Core"
    sub.dependency "IBPCollectionViewCompositionalLayout"
  end
  s.subspec 'BindingsCosmo' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/BindingsCosmo"
    sub.dependency "RxSwiftProperty/Bindings"
    sub.dependency "Cosmos"
  end
  s.subspec 'BindingsXibToXmlRuntime' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/BindingsXibToXmlRuntime"
    sub.dependency "RxSwiftProperty/Bindings"
    sub.dependency "XmlToXibRuntime"
  end
  s.subspec 'BindingsXibToXmlRuntimeKhrysalis' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/BindingsXibToXmlRuntimeKhrysalis"
    sub.dependency "RxSwiftProperty/BindingsXibToXmlRuntime"
    sub.dependency "KhrysalisRuntime"
  end
  s.subspec 'BindingsSearchTextField' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/BindingsSearchTextField"
    sub.dependency "RxSwiftProperty/Bindings"
    sub.dependency "SearchTextField"
  end
  s.subspec 'ViewGenerator' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/ViewGenerator"
    sub.dependency "RxSwiftProperty/Resources"
  end
  s.subspec 'ViewGeneratorCalendar' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/ViewGeneratorCalendar"
    sub.dependency "RxSwiftProperty/ViewGenerator"
  end
  s.subspec 'ViewGeneratorImage' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/ViewGeneratorImage"
    sub.dependency "RxSwiftProperty/ViewGenerator"
    sub.dependency "RxSwiftProperty/Resources"
    sub.dependency "DKImagePickerController/Core"
    sub.dependency "DKImagePickerController/ImageDataManager"
    sub.dependency "DKImagePickerController/Resource"
    sub.dependency "DKImagePickerController/Camera"
  end
  s.subspec 'ViewGeneratorLocation' do |sub|
    sub.source_files =  "RxSwiftProperty/Classes/ViewGeneratorLocation"
    sub.dependency "RxSwiftProperty/ViewGenerator"
    sub.dependency "RxCoreLocation"
  end
end
