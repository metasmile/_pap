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
}

class AppUICameraView: UIView {

    lazy var cameraView: CameraView = {
        let cameraView = CameraView(frame: .zero)
        cameraView.backgroundColor = .black
        cameraView.contentMode = .scaleAspectFill
        cameraView.setUp()

        cameraView.addGestureRecognizer(tapGesture)

        return cameraView
    }()

    private lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapToCapture))

    private var optionViewHeightLayout: NSLayoutConstraint?
    private var cameraAspectRatioLayout: NSLayoutConstraint?

    fileprivate var primaryColor = UIColor(red: 0.97, green: 0.8, blue: 0.27, alpha: 1) // 248    204    70

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
    private lazy var backgroundView = UIView(frame: .zero)

    private func intialize(with defaults: AppUICameraViewOptions?=nil) {
        tintColor = UIColor.white

        let buttonImageInsets = UIEdgeInsetsMake(4, 4, 4, 4)

        backgroundView.backgroundColor = .black
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        let optionView = UIView(frame: .zero)
        optionView.backgroundColor = .black
        addSubview(optionView)
        optionView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(cameraView)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.topAnchor.constraint(equalTo: optionView.bottomAnchor).isActive = true
        cameraView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        let widthLayout = cameraView.widthAnchor.constraint(equalTo: widthAnchor)
        widthLayout.priority = .defaultLow
        widthLayout.isActive = true

        let heightLayout = cameraView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        heightLayout.priority = .defaultLow
        heightLayout.isActive = true

        cameraAspectRatioLayout = cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor, multiplier: 1.3)
        cameraAspectRatioLayout?.isActive = true

        backgroundView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true

        optionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        optionView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
        optionViewHeightLayout = optionView.heightAnchor.constraint(equalToConstant: 0)
        optionViewHeightLayout?.isActive = true

        let livePhotoButton = UIButton(type: .system)
        livePhotoButton.imageEdgeInsets = buttonImageInsets
        livePhotoButton.imageView?.contentMode = .scaleAspectFit
        livePhotoButton.contentHorizontalAlignment = .fill
        livePhotoButton.contentVerticalAlignment = .fill
        livePhotoButton.setImage(livePhotoBadgeIcon, for: .normal)
        livePhotoButton.addTarget(self, action: #selector(self.toggleLivePhotoEnabled), for: .touchUpInside)
        optionView.addSubview(livePhotoButton)

        livePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        livePhotoButton.centerXAnchor.constraint(equalTo: optionView.centerXAnchor).isActive = true
        livePhotoButton.topAnchor.constraint(equalTo: optionView.topAnchor).isActive = true
        livePhotoButton.bottomAnchor.constraint(equalTo: optionView.bottomAnchor).isActive = true
        livePhotoButton.widthAnchor.constraint(equalTo: optionView.heightAnchor, multiplier: 1).isActive = true

        let controlView = UIView(frame: .zero)
        controlView.backgroundColor = .black
        addSubview(controlView)

        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.topAnchor.constraint(equalTo: cameraView.bottomAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        captureButton.addTarget(self, action: #selector(self.tapToCapture), for: .touchUpInside)
        addSubview(captureButton)

        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        captureButton.centerXAnchor.constraint(equalTo: controlView.centerXAnchor).isActive = true
        captureButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        captureButton.heightAnchor.constraint(lessThanOrEqualToConstant: 72).isActive = true
        captureButton.widthAnchor.constraint(equalTo: captureButton.heightAnchor, multiplier: 1).isActive = true

        let captureButtonTopLayout = captureButton.topAnchor.constraint(equalTo: controlView.topAnchor)
        captureButtonTopLayout.priority = .defaultLow - 1
        captureButtonTopLayout.isActive = true

        let captureButtonCenterYLayout = captureButton.centerYAnchor.constraint(equalTo: controlView.centerYAnchor)
        captureButtonCenterYLayout.priority = .defaultLow
        captureButtonCenterYLayout.isActive = true

        cameraPositionButton.imageEdgeInsets = buttonImageInsets
        cameraPositionButton.setImage(devicePositionIcon, for: .normal)
        cameraPositionButton.addTarget(self, action: #selector(self.switchDevicePosition), for: .touchUpInside)
        addSubview(cameraPositionButton)

        cameraPositionButton.translatesAutoresizingMaskIntoConstraints = false
        cameraPositionButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        cameraPositionButton.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -2).isActive = true
        cameraPositionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        cameraPositionButton.widthAnchor.constraint(equalTo: cameraPositionButton.heightAnchor, multiplier: 1).isActive = true

        let cameraPositionButtonCenterYLayout = cameraPositionButton.centerYAnchor.constraint(equalTo: optionView.centerYAnchor)
        cameraPositionButtonCenterYLayout.priority = .defaultLow
        cameraPositionButtonCenterYLayout.isActive = true

        cameraView.configurationDidUpdate = {
            var defaults = defaults
            defaults?.isLivePhotoEnabled = self.cameraView.isLivePhotoEnabled
            defaults?.cameraPosition = self.cameraView.cameraPosition

            DispatchQueue.main.async {
                livePhotoButton.setImage(self.livePhotoBadgeIcon, for: .normal)
                livePhotoButton.tintColor = self.cameraView.isLivePhotoEnabled ? self.primaryColor : nil
            }
        }

        if let defaults = defaults{
            self.cameraView.isLivePhotoEnabled = defaults.isLivePhotoEnabled
            self.cameraView.cameraPosition = defaults.cameraPosition
        }

        self.isCompactMode = true
    }

    private var devicePositionIcon: UIImage {
        return { () -> UIImage in
            return (self.isCompactMode ? R.image.cameraBAppPositionIntaglio() : R.image.cameraBAppPositionEmboss()) ?? UIImage()
        }().withRenderingMode(.alwaysTemplate)
    }

    private var livePhotoBadgeIcon: UIImage {
        return { () -> UIImage in
            guard cameraView.isLivePhotoSupported else { return PHLivePhotoView.livePhotoBadgeImage(options: .liveOff) }
            return cameraView.isLivePhotoEnabled ? PHLivePhotoView.livePhotoBadgeImage(options: .overContent) : PHLivePhotoView.livePhotoBadgeImage(options: .liveOff)
        }().withRenderingMode(.alwaysTemplate)
    }

    @objc func tapToCapture(sender: Any) {
        cameraView.takePhoto()
    }

    @objc func switchDevicePosition(sender: Any) {
        cameraView.switchCaptureDevicePosition()
    }

    @objc func toggleLivePhotoEnabled(sender: Any) {
        guard cameraView.isLivePhotoSupported else { return }
        cameraView.isLivePhotoEnabled = !cameraView.isLivePhotoEnabled
    }

    var isCompactMode: Bool = true {
        didSet {
            optionViewHeightLayout?.isActive = false
            if isCompactMode {
                optionViewHeightLayout?.constant = 0
            }
            else {
                optionViewHeightLayout?.constant = 44
            }
            optionViewHeightLayout?.isActive = true

            tapGesture.isEnabled = isCompactMode
            captureButton.isEnabled = !isCompactMode

            cameraPositionButton.setImage(self.devicePositionIcon, for: .normal)

            backgroundView.isHidden = isCompactMode

            //TODO: ignore layer implicit animation
            layoutIfNeeded()
        }
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
}




