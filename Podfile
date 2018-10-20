platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'

def common_pods
  use_frameworks!

  # pod 'RealmSwift'
  pod 'Firebase/Core', '5.2.0' #TODO: when it disappears memory leak issue since 5.3+0.10 version set, use latest version
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionTextModel'
  pod 'Firebase/MLVisionBarcodeModel'
  # pod 'Firebase/MLVisionLabelModel'
  pod 'Fabric'
  pod 'Crashlytics'

  # Core Wrappers
  pod 'R.swift', '4.0.0' #INFO: R.swift will major update soon : 5.0.0
  pod 'PropertyKit'

  # Common Solutions
  pod 'Hero'
  pod 'SwiftyGif'

  # com.stells.mmc.shop
  # pod 'Eureka'
  # # Garbage Social/Ads Kits - Must Use In ShopApp Only.
  # pod 'Firebase/AdMob', inhibit_warnings: true

  # Store
  pod 'Armchair', :git => "https://github.com/UrbanApps/Armchair"

  # com.stells.mmc.finder,phonecall - FirebaseMLVision.VisionText.Parser.Types.swift
  pod 'PhoneNumberKit', '~> 2.1'
end

target 'mmc' do
  common_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if ['PropertyKit','Armchair'].include? "#{target}"
        config.build_settings['SWIFT_VERSION'] = '4.2'
      else
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
    end
  end
end


#TODO: global - Auto-Comment for each swift module tracks "import {pod framework}" (Using: file.swift#line, file.swift#line)
