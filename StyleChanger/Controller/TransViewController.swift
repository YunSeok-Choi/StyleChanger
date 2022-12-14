//
//  TransViewController.swift
//  StyleChanger
//
//  Created by 최윤석 on 2022/11/26.
//

import UIKit
import CoreML
import Vision
import Photos

class TransViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc let imagePicker = UIImagePickerController()
    var userCIImage: CIImage!
    var userUIImage: UIImage!
    var ratio: CGFloat = 0
    
    private var imageView: UIImageView = {
        var image = UIImageView(image: UIImage(named: "blackpaper"))
        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private let segmentButton: UISegmentedControl = {
        var segment = UISegmentedControl(items: ["Original", "Stone", "Draw", "Pencil", "Spring", "Dot", "Green"])
        segment.selectedSegmentIndex = 0
        segment.translatesAutoresizingMaskIntoConstraints = false
        return segment
    }()
    
    private let saveButton: UIButton = {
        var button = UIButton()
        button.setTitle("저장하기", for: .normal)
        button.titleLabel?.font = UIFont(name: "Nanum GangInHanWiRo", size: 64)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        segmentButton.addTarget(self, action: #selector(segmentControl(_:)), for: .valueChanged)
        saveButton.addTarget(self, action: #selector(saveTransImage), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "camera"), style: .plain, target: self, action: #selector(albumTaped))
        
        view.addSubview(imageView)
        view.addSubview(segmentButton)
        view.addSubview(saveButton)
        
        setConstraints()
    }
    
    @objc func albumTaped() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        guard let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        userUIImage = userPickedImage
        ratio = userUIImage.size.width / userUIImage.size.height
        self.imageView.image = userUIImage
        
        userCIImage = CIImage(image: userPickedImage)!
        userCIImage.orientationTransform(for: .up)
        
        imagePicker.dismiss(animated: true)
    }
    
    @objc func segmentControl(_ segmentedControl: UISegmentedControl) {
        
        guard userCIImage != nil else { return }
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            imageView.image = userUIImage
        case 1:
            detect(image: userCIImage, name: "Stone")
        case 2:
            detect(image: userCIImage, name: "Dezoomify1teration310")
        case 3:
            detect(image: userCIImage, name: "Pencil")
        case 4:
            detect(image: userCIImage, name: "Spring")
        case 5:
            detect(image: userCIImage, name: "Dot")
        case 6:
            detect(image: userCIImage, name: "Green")
        default:
            break
        }
    }
    
    private func detect(image: CIImage, name: String) {
        
        var model: VNCoreMLModel?
        
        switch name {
        case "Stone":
            model = try? VNCoreMLModel(for: Stone(configuration: MLModelConfiguration()).model)
        case "Dezoomify1teration310":
            model = try? VNCoreMLModel(for: Dezoomify1teration310(configuration: MLModelConfiguration()).model)
        case "Pencil":
            model = try? VNCoreMLModel(for: Pencil(configuration: MLModelConfiguration()).model)
        case "Spring":
            model = try? VNCoreMLModel(for: Spring(configuration: MLModelConfiguration()).model)
        case "Dot":
            model = try? VNCoreMLModel(for: Dot(configuration: MLModelConfiguration()).model)
        case "Green":
            model = try? VNCoreMLModel(for: Green(configuration: MLModelConfiguration()).model)
        default:
            break
        }
        
        let request = VNCoreMLRequest(model: model!) { request, _ in
            DispatchQueue.global(qos: .userInteractive).async {
                guard let results = request.results?.first as? VNPixelBufferObservation else {
                    fatalError("model failed to process image")
                }
                let pixelBuffer = results.pixelBuffer
                
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let image = UIImage(ciImage: ciImage)
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }
        
        let orientation: CGImagePropertyOrientation = {
            
            switch ratio {
            case 0.75:
                return .right
            default:
                return .up
            }
        }()
        
        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    @objc private func saveTransImage() {
        
        let view = imageView
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        if image != nil {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image!)
            })
        }
        
        let alert = UIAlertController(title: "저장완료", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        present(alert, animated: true)
    }
    
    private func setConstraints() {
        
        let imageViewConstraints = [
            //            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 124),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 136),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -136),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.2)
        ]
        
        let segmentButtonConstraints = [
            segmentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 42),
            segmentButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -42),
            segmentButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 75)
        ]
        
        let saveButtonConstraints = [
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            //            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 435)
            saveButton.topAnchor.constraint(equalTo: segmentButton.bottomAnchor, constant: 30)
        ]
        
        NSLayoutConstraint.activate(imageViewConstraints)
        NSLayoutConstraint.activate(segmentButtonConstraints)
        NSLayoutConstraint.activate(saveButtonConstraints)
    }
}
