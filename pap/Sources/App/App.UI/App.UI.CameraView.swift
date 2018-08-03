//
// Created by BLACKGENE on 15.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos
import PhotosUI
import DefaultsKit

protocol AppUICameraViewOptions {
    var isLivePhotoEnabled: Bool { get set }
    var cameraPosition: AVCaptureDevice.Position { get set }
    var cameraFlashMode: AVCaptureDevice.FlashMode { get set }
}

class AppUICameraView: UIView {

    lazy var cameraView: CameraView = {
        let cameraView = CameraView(frame: .zero)
        cameraView.backgroundColor = .black
        cameraView.clipsToBounds = true
        cameraView.contentMode = .scaleAspectFill
        cameraView.setUp()

        cameraView.addGestureRecognizer(tapGesture)

        return cameraView
    }()

    private lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapToCapture))

    private var optionViewHeightLayout: NSLayoutConstraint?
    private var controlViewHeightLayout: NSLayoutConstraint?
    private var cameraAspectRatioLayout: NSLayoutConstraint?

    fileprivate var primaryColor = UIColor(red:0.99, green:0.8, blue:0.2, alpha:1)

    init(frame: CGRect, options: AppUICameraViewOptions?=nil) {
        super.init(frame: frame)
        intialize(with: options)
    }

    override convenience init(frame:CGRect) {
        self.init(frame: frame, options: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        intialize()
    }

    private lazy var captureButton = CaptureButton(frame: .zero)
    private lazy var cameraPositionButton = UIButton(type: .system)
    private lazy var cameraFlashButton = UIButton(type: .system)
    private lazy var backgroundView = UIView(frame: .zero)
    private lazy var optionBackgroundView = UIView(frame: .zero)
    private lazy var livePhotoButton = UIButton(type: .system)

    private let OptionViewHeightAnchorConstant:CGFloat = 44 // top
    private let ControlViewHeightAnchorConstant:CGFloat = remapClamp(
            UIScreen.main.bounds.width/UIScreen.main.bounds.height,
            0.562218890554723, // w/h iphone 6/se (widest)
            // ... 6/7/8 Plus //
            0.461822660098522, // w/h iphone x (longest)
            54,
            72
    )
    private lazy var CaptureButtonMinHeightAnchorConstant:CGFloat = self.ControlViewHeightAnchorConstant/1.5 //compact size

    private func intialize(with defaults: AppUICameraViewOptions?=nil) {
        if let defaults = defaults{
            self.cameraView.isLivePhotoEnabled = defaults.isLivePhotoEnabled
            self.cameraView.cameraPosition = defaults.cameraPosition
            self.cameraView.currentFlashMode = defaults.cameraFlashMode
        }

        cameraView.deviceMotion.watch(\.orientation){
            let o = self.cameraView.deviceMotion.orientation

            var angle:Double = 0;
            if (o == .landscapeLeft ){ angle = .pi/2.0}
            else if (o == .landscapeRight ){ angle = -.pi/2.0}
            else if (o == .portraitUpsideDown ){ angle = .pi}

            DispatchQueue.main.async{
                let newTransform = o == .unknown ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: CGFloat(angle))
                if self.livePhotoButton.transform != newTransform{
                    UIView.animate(withDuration: 0.3, delay: 0, options: .beginFromCurrentState, animations: { () -> () in
                        self.livePhotoButton.transform = newTransform
                        self.cameraFlashButton.transform = newTransform
                        self.cameraPositionButton.transform = newTransform
                     }, completion: nil)
                }
                self.cameraView.updateVideoOrientation()
            }
        }

        tintColor = UIColor.white

        let buttonImageInsets = UIEdgeInsetsMake(4, 4, 4, 4)

        backgroundView.backgroundColor = .black
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        let optionView = UIView(frame: .zero)
        optionView.clipsToBounds = true
        optionView.backgroundColor = .black
        addSubview(optionView)
        optionView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(cameraView)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.topAnchor.constraint(equalTo: optionView.bottomAnchor).isActive = true
        cameraView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let widthMaximumLayout = cameraView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor)
        widthMaximumLayout.isActive = true

        let widthLayout = cameraView.widthAnchor.constraint(equalTo: widthAnchor)
        widthLayout.priority = .defaultLow
        widthLayout.isActive = true

        let heightLayout = cameraView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        heightLayout.priority = .defaultLow
        heightLayout.isActive = true

        cameraAspectRatioLayout = cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor, multiplier: 1.333333)
        cameraAspectRatioLayout?.isActive = true

        backgroundView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true

        optionBackgroundView.clipsToBounds = true
        optionBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        addSubview(optionBackgroundView)
        optionBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        optionBackgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionBackgroundView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        optionBackgroundView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
        optionBackgroundView.heightAnchor.constraint(equalToConstant: OptionViewHeightAnchorConstant).isActive = true

        optionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        optionView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
        optionViewHeightLayout = optionView.heightAnchor.constraint(equalToConstant: 0)
        optionViewHeightLayout?.isActive = true

        livePhotoButton.imageEdgeInsets = buttonImageInsets
        livePhotoButton.imageView?.contentMode = .scaleAspectFit
        livePhotoButton.contentHorizontalAlignment = .fill
        livePhotoButton.contentVerticalAlignment = .fill
        livePhotoButton.setImage(livePhotoBadgeIcon, for: .normal)
        livePhotoButton.addTarget(self, action: #selector(self.toggleLivePhotoEnabled), for: .touchUpInside)
        addSubview(livePhotoButton)

        livePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        livePhotoButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        livePhotoButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        livePhotoButton.heightAnchor.constraint(equalToConstant: OptionViewHeightAnchorConstant).isActive = true
        livePhotoButton.widthAnchor.constraint(equalTo: livePhotoButton.heightAnchor, multiplier: 1).isActive = true

        let controlView = UIView(frame: .zero)
        controlView.clipsToBounds = true
        controlView.backgroundColor = .black
        addSubview(controlView)

        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.topAnchor.constraint(equalTo: cameraView.bottomAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        controlViewHeightLayout = controlView.heightAnchor.constraint(equalToConstant: 0)
        controlViewHeightLayout?.priority = .defaultLow
        controlViewHeightLayout?.isActive = true

        captureButton.addTarget(self, action: #selector(self.tapToCapture), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(self.tapDownToCapture), for: .touchDown)
        addSubview(captureButton)

        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        captureButton.centerXAnchor.constraint(equalTo: controlView.centerXAnchor).isActive = true
        captureButton.heightAnchor.constraint(greaterThanOrEqualToConstant: CaptureButtonMinHeightAnchorConstant).isActive = true
        captureButton.heightAnchor.constraint(lessThanOrEqualToConstant: ControlViewHeightAnchorConstant).isActive = true
        captureButton.widthAnchor.constraint(equalTo: captureButton.heightAnchor, multiplier: 1).isActive = true

        let captureButtonTopLayout = captureButton.topAnchor.constraint(equalTo: controlView.topAnchor)
        captureButtonTopLayout.priority = .defaultLow - 1
        captureButtonTopLayout.isActive = true

        let captureButtonCenterYLayout = captureButton.centerYAnchor.constraint(equalTo: controlView.centerYAnchor)
        captureButtonCenterYLayout.priority = .defaultLow
        captureButtonCenterYLayout.isActive = true

        //position
        cameraPositionButton.imageEdgeInsets = buttonImageInsets
        cameraPositionButton.setImage(devicePositionIcon, for: .normal)
        cameraPositionButton.addTarget(self, action: #selector(self.switchDevicePosition), for: .touchUpInside)
        addSubview(cameraPositionButton)

        cameraPositionButton.translatesAutoresizingMaskIntoConstraints = false
        cameraPositionButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        cameraPositionButton.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -2).isActive = true
        cameraPositionButton.heightAnchor.constraint(equalToConstant: OptionViewHeightAnchorConstant).isActive = true
        cameraPositionButton.widthAnchor.constraint(equalTo: cameraPositionButton.heightAnchor, multiplier: 1).isActive = true

        let cameraPositionButtonCenterYLayout = cameraPositionButton.centerYAnchor.constraint(equalTo: optionView.centerYAnchor)
        cameraPositionButtonCenterYLayout.priority = .defaultLow
        cameraPositionButtonCenterYLayout.isActive = true

        //flash
        cameraFlashButton.imageEdgeInsets = buttonImageInsets
        cameraFlashButton.setImage(flashModeIcon, for: .normal)
        cameraFlashButton.addTarget(self, action: #selector(self.switchFlash), for: .touchUpInside)
        addSubview(cameraFlashButton)

        cameraFlashButton.translatesAutoresizingMaskIntoConstraints = false
        cameraFlashButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        cameraFlashButton.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor, constant: 2).isActive = true
        cameraFlashButton.heightAnchor.constraint(equalToConstant: OptionViewHeightAnchorConstant).isActive = true
        cameraFlashButton.widthAnchor.constraint(equalTo: cameraFlashButton.heightAnchor, multiplier: 1).isActive = true

        let cameraFlashButtonCenterYLayout = cameraFlashButton.centerYAnchor.constraint(equalTo: optionView.centerYAnchor)
        cameraFlashButtonCenterYLayout.priority = .defaultLow
        cameraFlashButtonCenterYLayout.isActive = true

        cameraView.configurationDidUpdate = {
            var defaults = defaults
            defaults?.isLivePhotoEnabled = self.cameraView.isLivePhotoEnabled
            defaults?.cameraPosition = self.cameraView.cameraPosition

            DispatchQueue.mainAsyncIfNot {
                self.livePhotoButton.setImage(self.livePhotoBadgeIcon, for: .normal)
                self.livePhotoButton.tintColor = self.cameraView.isLivePhotoEnabled ? self.primaryColor : nil

                self.cameraFlashButton.setImage(self.flashModeIcon, for: .normal)
                self.cameraFlashButton.tintColor = self.cameraView.currentFlashMode == .on ? self.primaryColor : nil
            }
        }

        self.isCompactMode = true
    }

    private var devicePositionIcon: UIImage {
        return { () -> UIImage in
            return (self.isCompactMode ? R.image.appUICameraViewPositionIntaglio() : R.image.appUICameraViewPositionEmboss()) ?? UIImage()
        }().withRenderingMode(.alwaysTemplate)
    }

    private var livePhotoBadgeIcon: UIImage {
        return { () -> UIImage in
            guard cameraView.isLivePhotoSupported else { return PHLivePhotoView.livePhotoBadgeImage(options: .liveOff) }
            return cameraView.isLivePhotoEnabled ? PHLivePhotoView.livePhotoBadgeImage(options: .overContent) : PHLivePhotoView.livePhotoBadgeImage(options: .liveOff)
        }().withRenderingMode(.alwaysTemplate)
    }

    private var flashModeIcon: UIImage{
        return { () -> UIImage in
            switch cameraView.currentFlashMode{
                case .on, .auto:
                    return R.image.appUICameraViewFlashOn() ?? UIImage()
                case .off:
                    return R.image.appUICameraViewFlashOff() ?? UIImage()
            }
        }().withRenderingMode(.alwaysTemplate)
    }

    @objc func tapToCapture(sender: Any) {
        if isCompactMode || sender is CaptureButton {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            cameraView.takePhoto()
        }
        else if let gesture = sender as? UITapGestureRecognizer {
            cameraView.updatePointOfInterest(at: gesture.location(in: cameraView))
        }
    }

    @objc func tapDownToCapture(sender: Any) {
        UISelectionFeedbackGenerator().selectionChanged()
        UIImpactFeedbackGenerator(style: .light).prepare()
    }

    @objc func switchDevicePosition(sender: Any) {
        cameraView.switchCaptureDevicePosition()

        UISelectionFeedbackGenerator().selectionChanged()
    }

    @objc func switchFlash(sender: Any) {
        cameraView.currentFlashMode = [
            AVCaptureDevice.FlashMode.auto:AVCaptureDevice.FlashMode.on,
            AVCaptureDevice.FlashMode.on:AVCaptureDevice.FlashMode.off,
            AVCaptureDevice.FlashMode.off:AVCaptureDevice.FlashMode.auto
        ][cameraView.currentFlashMode]!

        UISelectionFeedbackGenerator().selectionChanged()
    }

    @objc func toggleLivePhotoEnabled(sender: Any) {
        guard cameraView.isLivePhotoSupported else { return }
        cameraView.isLivePhotoEnabled = !cameraView.isLivePhotoEnabled

        UISelectionFeedbackGenerator().selectionChanged()
    }

    var hasZeroOptionViewMargin:Bool{
        layoutIfNeeded()
        return height-(cameraView.height + ControlViewHeightAnchorConstant) < OptionViewHeightAnchorConstant
    }

    var isCompactMode: Bool = true {
        didSet {
            if isCompactMode {
                optionViewHeightLayout?.constant = 0
                controlViewHeightLayout?.constant = 0
            }
            else {
                controlViewHeightLayout?.constant = ControlViewHeightAnchorConstant
                optionViewHeightLayout?.constant = self.hasZeroOptionViewMargin ? 0 : OptionViewHeightAnchorConstant
            }

            let compactControlViewLayoutRequired = isCompactMode || optionViewHeightLayout?.constant ?? 0 > 0

            captureButton.isEnabled = !isCompactMode
            captureButton.transform = compactControlViewLayoutRequired ? CGAffineTransform.identity : CGAffineTransform(scaleX: 0.9, y: 0.9)

            cameraPositionButton.setImage(devicePositionIcon, for: .normal)

            optionBackgroundView.isHidden = compactControlViewLayoutRequired
            backgroundView.isHidden = isCompactMode
            
            //TODO: ignore layer implicit animation
            layoutIfNeeded()
            
            cameraView.updatePointOfInterest(at: CGPoint(x: cameraView.width / 2, y: cameraView.height / 2), showsGuide: !isCompactMode)
        }
    }
}
