platform :ios, '11.0'

target 'pap' do
  use_frameworks!

  # pod 'RealmSwift'
  pod 'Firebase/Core', '5.2.0' #TODO: when it disappears memory leak issue since 5.3+0.10 version set, use latest version
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionTextModel'

  # com.stells.pap.*
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'R.swift', '4.0.0' #INFO: R.swift will major update soon : 5.0.0
  pod 'DefaultsKit', :git => "https://github.com/metasmile/DefaultsKit" #TODO: consider to get into CodeKit with Subfile
  pod 'SwiftyGif'
  pod 'Armchair', '>= 0.3' #FIXME: deprecation warning.
  pod 'Hero'
  # pod 'SwipeCellKit'

  # com.stells.pap.pdfactory
  pod 'TPPDF'

  # using: FirebaseMLVision.VisionText.Parser.Contacts.swift
  pod 'PhoneNumberKit', '~> 2.1'
  
  # com.stells.pap.clean
  pod 'CocoaImageHashing', :git => "https://github.com/ameingast/cocoaimagehashing" #INFO: The author did not update into official pod repo for his latest version

  target 'papTests' do
    inherit! :complete
  end
end

#TODO: global - Auto-Comment for each swift module tracks "import {pod framework}" (Using: file.swift#line, file.swift#line)
