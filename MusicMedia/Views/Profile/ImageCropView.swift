import SwiftUI
import PhotosUI
import UIKit
import TOCropViewController

struct ImageCropView: UIViewControllerRepresentable {
    let initialImage: UIImage
    let onCrop: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> TOCropViewController {
        let cropViewController = TOCropViewController(croppingStyle: .circular, image: initialImage)
        cropViewController.aspectRatioPreset = .presetSquare
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.rotateButtonsHidden = false
        cropViewController.doneButtonTitle = "Choose"
        cropViewController.cancelButtonTitle = "Cancel"
        cropViewController.delegate = context.coordinator
        return cropViewController
    }
    
    func updateUIViewController(_ uiViewController: TOCropViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, TOCropViewControllerDelegate {
        let parent: ImageCropView
        
        init(parent: ImageCropView) {
            self.parent = parent
        }
        
        func cropViewController(_ cropViewController: TOCropViewController, didCropToCircularImage image: UIImage, with cropRect: CGRect, angle: Int) {
            parent.onCrop(image)
            parent.dismiss()
        }
        
        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            parent.dismiss()
        }
    }
}

// MARK: - CropViewController
class CropViewController: UIViewController {
    private let croppingStyle: CroppingStyle
    private let image: UIImage
    
    var onCropComplete: ((CGRect, UIImage?) -> Void)?
    var aspectRatioPreset: AspectRatioPreset = .presetSquare
    var aspectRatioLockEnabled = true
    var resetAspectRatioEnabled = false
    var rotateButtonsHidden = true
    
    let cropView: CropView
    
    init(croppingStyle: CroppingStyle, image: UIImage) {
        self.croppingStyle = croppingStyle
        self.image = image
        self.cropView = CropView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCropView()
    }
    
    private func setupCropView() {
        view.backgroundColor = .black
        
        cropView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cropView)
        
        NSLayoutConstraint.activate([
            cropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup the crop view with the image
        cropView.image = image
    }
}

// MARK: - Supporting Types
enum CroppingStyle {
    case circular
    case square
}

enum AspectRatioPreset {
    case presetSquare
    case presetOriginal
}

class CropView: UIView {
    var image: UIImage? {
        didSet {
            // Update the image view when the image is set
            imageView.image = image
        }
    }
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    var cropBoxResizeEnabled: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
} 