platform :ios, '11.0'

target 'pap' do
  use_frameworks!

  # pod 'RealmSwift'
  pod 'Firebase/Core'
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
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionTextModel'
  pod 'PhoneNumberKit', '~> 2.1'

  pod 'Armchair', '>= 0.3'
  # https://github.com/UrbanApps/Armchair
  #Add the following in order to automatically set debug flags for armchair in debug builds
  # post_install do |installer|
  #   installer.pods_project.targets.each do |target|
  #     if target.name == 'Armchair'
  #       target.build_configurations.each do |config|
  #         if config.name == 'Debug'
  #           config.build_settings['OTHER_SWIFT_FLAGS'] = '-DDebug'
  #         else
  #           config.build_settings['OTHER_SWIFT_FLAGS'] = ''
  #         end
  #       end
  #     end
  #   end
  # end

end
