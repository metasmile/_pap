platform :ios, '11.0'

target 'pap' do
  use_frameworks!

  # pod 'RealmSwift'
  pod 'Firebase/Core', '5.1.0'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'R.swift'
  pod 'DefaultsKit', :git => "https://github.com/metasmile/DefaultsKit" #TODO: consider to get into CodeKit with Subfile
  pod 'SwiftyGif'
  # pod 'SwipeCellKit'

  target 'papTests' do
    inherit! :complete
  end

  # com.stells.pap.pdfactory
  pod 'TPPDF'

  # for test - com.stells.pap.textractor
  pod 'Firebase/MLVision', '5.1.0'
  pod 'Firebase/MLVisionTextModel', '5.1.0'
  pod 'PhoneNumberKit', '~> 2.1'

  pod 'Armchair', '>= 0.3'
end
