platform :ios, '11.0'

target 'pap' do
  use_frameworks!

  # pod 'RealmSwift'
  pod 'Firebase/Core', '5.2.0' #when it disappears memory leak issue since 5.3+0.10 version set, use latest version
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionTextModel'

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
  pod 'PhoneNumberKit', '~> 2.1'
  
  # com.stells.pap.clean
  pod 'CocoaImageHashing'

  pod 'Armchair', '>= 0.3'
end
