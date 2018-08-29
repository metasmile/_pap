platform :ios, '11.0'

target 'pap' do
  use_frameworks!

  # pod 'RealmSwift'
  pod 'Firebase/Core', '5.2.0' #TODO: when it disappears memory leak issue since 5.3+0.10 version set, use latest version
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionTextModel'
  pod 'Fabric'
  pod 'Crashlytics'

  # Core Wrappers
  pod 'R.swift', '4.0.0' #INFO: R.swift will major update soon : 5.0.0
  pod 'PropertyKit'

  # Common Solutions
  pod 'Hero'
  pod 'SwiftyGif'

  # com.stells.pap.shop
  # pod 'Eureka'
  pod 'Firebase/AdMob', inhibit_warnings: true
  pod 'FBSDKCoreKit', inhibit_warnings: true
  pod 'FBSDKShareKit', inhibit_warnings: true

  pod 'SwiftyStoreKit'
  pod 'Armchair', :git => "https://github.com/UrbanApps/Armchair"
  # com.stells.pap.pdfactory
  pod 'TPPDF'
  # com.stells.pap.clean
  pod 'CocoaImageHashing', :git => "https://github.com/ameingast/cocoaimagehashing" #INFO: The author did not update into official pod repo for his latest version

  # com.stells.pap.finder,phonecall - FirebaseMLVision.VisionText.Parser.Contacts.swift
  pod 'PhoneNumberKit', '~> 2.1'

  target 'papTests' do
    inherit! :complete
  end
end

#TODO: global - Auto-Comment for each swift module tracks "import {pod framework}" (Using: file.swift#line, file.swift#line)
