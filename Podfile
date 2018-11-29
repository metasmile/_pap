platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'

def common_pods
  use_frameworks!

  # pod 'RealmSwift'
  pod 'Firebase/Core'
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionTextModel'
  pod 'Firebase/MLVisionBarcodeModel'
  pod 'Firebase/MLVisionLabelModel'
  pod 'Fabric'
  pod 'Crashlytics'

  # Core Wrappers
  pod 'R.swift', '4.0.0' #INFO: R.swift will major update soon : 5.0.0
  pod 'PropertyKit'

  # Common Solutions
  pod 'SwiftyGif'

  pod 'Armchair', :git => "https://github.com/UrbanApps/Armchair"
  pod 'PhoneNumberKit', '~> 2.1'
end

def paps_pods
  common_pods

  # com.stells.batch.shop
  # pod 'Eureka'
  # # Garbage Social/Ads Kits - Must Use In ShopApp Only.
  pod 'Firebase/AdMob', inhibit_warnings: true
  # Store
  pod 'SwiftyStoreKit'
  pod 'Armchair', :git => "https://github.com/UrbanApps/Armchair"
  # com.stells.batch.pdfmaker
  pod 'TPPDF'
  # com.stells.batch.clean
  pod 'CocoaImageHashing', :git => "https://github.com/ameingast/cocoaimagehashing" #INFO: The author did not update into official pod repo for his latest version
  # com.stells.batch.hashtagen
  pod 'TagListView', '~> 1.0'
end

target 'batch' do
  paps_pods
  target 'papTests' do
    inherit! :complete
  end
end

target 'sap' do
  paps_pods
end

target 'mmc' do
  common_pods
end

target 'ocra' do
  pod 'Firebase/AdMob', inhibit_warnings: true
  common_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if ['PropertyKit','Armchair','SwiftyGif','TPPDF'].include? "#{target}"
        config.build_settings['SWIFT_VERSION'] = '4.2'
      else
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
    end
  end
end


#TODO: global - Auto-Comment for each swift module tracks "import {pod framework}" (Using: file.swift#line, file.swift#line)
