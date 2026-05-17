platform :ios, '16.0'
source 'https://github.com/CocoaPods/Specs.git'

def common_pods
  use_frameworks!

  # Core Firebase
  pod 'Firebase/Core'
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionTextModel'
  pod 'Firebase/MLVisionBarcodeModel'
  pod 'Firebase/MLVisionLabelModel'

  # Core Wrappers
  pod 'R.swift'

  # Common Solutions
  pod 'SwiftyGif'
end

def paps_pods
  common_pods

  # Ads & Payments
  pod 'Firebase/AdMob', inhibit_warnings: true
  pod 'SwiftyStoreKit'
  
  # Feature pods
  pod 'TPPDF'
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

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Set minimum deployment target for all pods to match the project
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      # Use Swift 5 for all pods
      config.build_settings['SWIFT_VERSION'] = '5.0'
      # Suppress C strict-prototypes warning as error (Xcode 16+)
      config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'NO'
      config.build_settings['SWIFT_TREAT_WARNINGS_AS_ERRORS'] = 'NO'
    end
  end
end
