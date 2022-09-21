//Stub file made with Khrysalis 2 (by Lightning Kite)
import Foundation
import Photos
import AVKit
import MapKit
import EventKitUI
import DKImagePickerController
import MobileCoreServices
import RxSwift

public struct SecurityException: Error {
    public let message: String
    public init(_ message: String) {
        self.message = message
    }
}
public enum NotAvailableErrorEnum : Error { case singleton }
public let NotAvailableError = NotAvailableErrorEnum.singleton
private enum RequestType { case image, video, document }

//--- ViewControllerAccess
public extension ViewControllerAccess {
    //--- ViewControllerAccess image helpers
    private static let imageDelegateExtension = ExtensionProperty<ViewControllerAccess, ImageDelegate>()
//    private static let documentDelegateExtension = ExtensionProperty<ViewControllerAccess, DocumentDelgate>()
    private var imageDelegate: ImageDelegate {
        if let existing = ViewControllerAccess.imageDelegateExtension.get(self) {
            return existing
        }
        let new = ImageDelegate()
        ViewControllerAccess.imageDelegateExtension.set(self, new)
        return new
    }

//    private var documentDelegate: DocumentDelgate {
//        if let existing = ViewControllerAccess.documentDelegateExtension.get(self) {
//            return existing
//        }
//        let new = DocumentDelgate()
//        ViewControllerAccess.documentDelegateExtension.set(self, new)
//        return new
//    }
    
    private func getLibraryPermission() -> Completable {
        return Completable.create { (obs) in
            if PHPhotoLibrary.authorizationStatus() == .authorized {
                obs(.completed)
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    switch status {
                    case .notDetermined:
                        DispatchQueue.main.async {
                            obs(.error(SecurityException("User has rejected permission to access photo library.")))
                        }
                    case .restricted:
                        DispatchQueue.main.async {
                            obs(.error(SecurityException("User has rejected permission to access photo library.")))
                        }
                    case .denied:
                        DispatchQueue.main.async {
                            obs(.error(SecurityException("User has rejected permission to access photo library.")))
                        }
                    case .authorized:
                        DispatchQueue.main.async {
                            obs(.completed)
                        }
                    case .limited:
                        DispatchQueue.main.async {
                            obs(.completed)
                        }
                    @unknown default:
                        DispatchQueue.main.async {
                            obs(.completed)
                        }
                    }
                }
            }
            return DisposableLambda {}
        }
    }
    private func getCameraPermission() -> Completable {
        return Completable.create { em in
            DispatchQueue.main.async {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            em(.completed)
                        } else {
                            em(.error(SecurityException("User rejected permission to capture video")))
                        }
                    }
                }
            }
            return DisposableLambda {}
        }
    }
    private func pick(sourceType: UIImagePickerController.SourceType, mustAllowVideo: Bool, delegateSetup: (ImageDelegate) -> Void) -> Maybe<URL> {
        if UIImagePickerController.isSourceTypeAvailable(sourceType){
            if mustAllowVideo {
                if(UIImagePickerController.availableMediaTypes(for: sourceType)?.contains("public.video") != true) {
                    return Maybe.error(NotAvailableError)
                }
            }
            let imageDelegate = self.imageDelegate
            imageDelegate.forImages()
            delegateSetup(imageDelegate)
            return Maybe.create { em in
                imageDelegate.onImagePicked = { url in
                    if let url = url {
                        em(.success(url))
                    } else {
                        em(.completed)
                    }
                }
                imageDelegate.prepareGallery()
                self.parentViewController.present(imageDelegate.imagePicker, animated: true, completion: nil)
                return DisposableLambda {
                    imageDelegate.imagePicker.dismiss(animated: true)
                }
            }
        } else {
            return Maybe.error(NotAvailableError)
        }
    }
    private func dkPick(type: DKImagePickerControllerAssetType) -> Maybe<Array<URL>> {
        return Maybe.create { em in
            let pickerController = DKImagePickerController()
            pickerController.assetType = type
            pickerController.didCancel = {
                em(.completed)
            }
            pickerController.didSelectAssets = { (assets: [DKAsset]) in
                DKImageAssetExporter.sharedInstance.exportAssetsAsynchronously(assets: assets, completion: { info in
                    em(.success(assets.map { $0.localTemporaryPath! }))
                })
            }
            self.parentViewController.present(pickerController, animated: true){}
            return DisposableLambda {
                pickerController.dismiss(animated: true)
            }
        }
    }
    private func documentsPick(_ type: String) -> Maybe<Array<URL>> {
        return Maybe.create { em in
            let docDelegate = DocumentDelgate(type)
            docDelegate.onDocumentsPicked = { documents in
                if let documents = documents {
                    em(.success(documents))
                } else {
                    em(.completed)
                }
            }
            docDelegate.prepareMenu()
            self.parentViewController.present(docDelegate.documentPicker, animated: true, completion: nil)
            return DisposableLambda {
                docDelegate.documentPicker.dismiss(animated: true)
            }
        }
    }
    private func pickType() -> Maybe<RequestType> {
        return Maybe.create { em in
            let optionMenu = UIAlertController(
                title: nil,
                message: "What kind of file?",
                preferredStyle: UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
            )
                
            let image = UIAlertAction(title: "Images", style: .default, handler: { _ in
                em(.success(.image))
            })
            let video = UIAlertAction(title: "Videos", style: .default, handler: { _ in
                em(.success(.video))
            })
            let doc = UIAlertAction(title: "Documents", style: .default, handler: { _ in
                em(.success(.document))
            })
                
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                em(.completed)
            })
                
            optionMenu.addAction(image)
            optionMenu.addAction(video)
            optionMenu.addAction(doc)
            optionMenu.addAction(cancelAction)
            
            optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.parentViewController.view.frame.midX, y: self.parentViewController.view.frame.midY, width: 1, height: 1)
            self.parentViewController.present(optionMenu, animated: true, completion: nil)
            return DisposableLambda {
                optionMenu.dismiss(animated: true)
            }
        }
    }

    //--- ViewControllerAccess.requestImageGallery((URL)->Unit)
    func requestImageGallery() -> Maybe<URL> {
        return getLibraryPermission()
            .andThen(pick(sourceType: .savedPhotosAlbum, mustAllowVideo: false, delegateSetup: { $0.forImages(); $0.prepareGallery() }))
    }


    //--- ViewControllerAccess.requestVideoGallery((URL)->Unit)
    func requestVideoGallery() -> Maybe<URL> {
        return getLibraryPermission()
            .andThen(pick(sourceType: .savedPhotosAlbum, mustAllowVideo: true, delegateSetup: { $0.forVideo(); $0.prepareGallery() }))
    }
    
    //--- ViewControllerAccess.requestMediaGallery((URL)->Unit)
    func requestMediaGallery() -> Maybe<URL> {
        return getLibraryPermission()
            .andThen(pick(sourceType: .savedPhotosAlbum, mustAllowVideo: false, delegateSetup: { $0.forAll(); $0.prepareGallery() }))
    }
    
    
    //--- ViewControllerAccess.requestImageCamera((URL)->Unit)
    func requestImageCamera(front:Bool = false) -> Maybe<URL> {
        return getCameraPermission()
            .andThen(getLibraryPermission())
            .andThen(pick(sourceType: .camera, mustAllowVideo: false, delegateSetup: { $0.forImages(); $0.prepareCamera(front: front) }))
    }
        
    //--- ViewControllerAccess.requestVideoCamera(Boolean, (URL)->Unit)
    func requestVideoCamera(front: Bool = false) -> Maybe<URL> {
        return getCameraPermission()
            .andThen(getLibraryPermission())
            .andThen(pick(sourceType: .camera, mustAllowVideo: true, delegateSetup: { $0.forVideo(); $0.prepareCamera(front: front) }))
    }

    
    //--- ViewControllerAccess.requestImagesGallery((List<URL>)->Unit)
    func requestImagesGallery() -> Maybe<Array<URL>> {
        return getLibraryPermission().andThen(dkPick(type: .allPhotos))
    }
    
    //--- ViewControllerAccess.requestVideosGallery((List<URL>)->Unit)
    func requestVideosGallery() -> Maybe<Array<URL>> {
        return getLibraryPermission().andThen(dkPick(type: .allVideos))
    }

    //--- ViewControllerAccess.requestMediasGallery((List<URL>)->Unit)
    func requestMediasGallery() -> Maybe<Array<URL>>  {
        return getLibraryPermission().andThen(dkPick(type: .allAssets))
    }


    func getMimeType(uri:URL) -> String? {
        let pathExtension = uri.pathExtension
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return nil
    }
    
    func requestDocuments(_ type: String) -> Maybe<Array<URL>> {
        return documentsPick(type)
    }

    func requestDocument(_ type: String) -> Maybe<URL> {
        return documentsPick(type).compactMap { $0.first }
    }
    
    func requestFiles(type: String = "*/*") -> Maybe<Array<URL>> {
        if type.starts(with: "*/") {
            return pickType().flatMap { [weak self] in
                guard let self = self else { return Maybe.empty() }
                switch $0 {
                case .image:
                    return self.requestImagesGallery()
                case .video:
                    return self.requestVideosGallery()
                case .document:
                    return self.requestDocuments(type)
                }
            }
        } else if type.starts(with: "image/") {
            return self.requestImagesGallery()
        } else if type.starts(with: "video/") {
            return self.requestVideosGallery()
        } else {
            return self.requestDocuments(type)
        }
    }

    func requestFile(type: String = "*/*") -> Maybe<URL> {
        if type.starts(with: "*/") {
            return pickType().flatMap { [weak self] in
                guard let self = self else { return Maybe.empty() }
                switch $0 {
                case .image:
                    return self.requestImageGallery()
                case .video:
                    return self.requestVideoGallery()
                case .document:
                    return self.requestDocument(type)
                }
            }
        } else if type.starts(with: "image/") {
            return self.requestImageGallery()
        } else if type.starts(with: "video/") {
            return self.requestVideoGallery()
        } else {
            return self.requestDocument(type)
        }
        
    }

    func getFileName(uri:URL) -> String? {
        return UUID().uuidString + uri.lastPathComponent
    }
    
    func getFileName(name: String, type: MediaType) -> String? {
        return UUID().uuidString + name
    }
    
    func downloadFile(url:String){
        let url = URL(string: url)!

        let documentsUrl:URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationFileUrl = documentsUrl?.appendingPathComponent(getFileName(uri: url)!)

        let task = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
            if let localTemp = localURL, let destination = destinationFileUrl{
                do {
                    try FileManager.default.copyItem(at: localTemp, to: destination)
                    
                    DispatchQueue.main.sync {
                        let ac = UIActivityViewController(activityItems: [destination], applicationActivities: nil)
                        ac.popoverPresentationController?.sourceView = self.parentViewController.view
                        ac.popoverPresentationController?.sourceRect = CGRect(x: self.parentViewController.view.frame.midX, y: self.parentViewController.view.frame.midY, width: 1, height: 1)
                        self.parentViewController.present(ac, animated: true)
                    }
                } catch (let writeError) {
                    print("Error creating a file \(destination) : \(writeError)")
                }
            }
        }

        task.resume()
    }
    
    func downloadFileData(data: Data, name: String, type: MediaType){

        let documentsUrl:URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationFileUrl = documentsUrl?.appendingPathComponent(getFileName(name: name, type: type)!)
        if let destination = destinationFileUrl{
            do {
                try data.write(to: destination)
                let ac = UIActivityViewController(activityItems: [destination], applicationActivities: nil)
                ac.popoverPresentationController?.sourceView = self.parentViewController.view
                ac.popoverPresentationController?.sourceRect = CGRect(x: self.parentViewController.view.frame.midX, y: self.parentViewController.view.frame.midY, width: 1, height: 1)
                self.parentViewController.present(ac, animated: true)
            } catch (let writeError) {
                print("Error creating a file \(destination) : \(writeError)")
            }
        }
    }
}


private class DocumentDelgate : NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    var documentPicker:UIDocumentPickerViewController
    var onDocumentsPicked: ((Array<URL>?) -> Void)? = nil

    init(_ type: String){
        
        if(type == "*/*"){
            documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        } else if #available(iOS 14.0, *) {
            if let type = UTType(mimeType: type){
                documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [type])
            } else {
                documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            }
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        }
        
    }
    
    func prepareMenu(){
        documentPicker.delegate = self
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.onDocumentsPicked?(urls)
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.onDocumentsPicked?(nil)
        controller.dismiss(animated: true, completion: nil)
    }
}


//--- Image helpers

private class ImageDelegate : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imagePicker = UIImagePickerController()
    var onImagePicked: ((URL?)->Void)? = nil

    func forVideo(){
        imagePicker.mediaTypes = ["public.movie"]
    }
    func forImages(){
        imagePicker.mediaTypes = ["public.image"]
    }
    func forAll(){
        imagePicker.mediaTypes = ["public.image", "public.movie"]
    }

    func prepareGallery(){
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
    }

    func prepareCamera(front:Bool){
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        if imagePicker.mediaTypes.contains("public.image") {
            imagePicker.cameraCaptureMode = .photo
        } else {
            imagePicker.cameraCaptureMode = .video
        }
        if front{
            imagePicker.cameraDevice = .front
        }else{
            imagePicker.cameraDevice = .rear
        }
        imagePicker.allowsEditing = false
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        onImagePicked?(nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if #available(iOS 11.0, *) {
            if let image = info[.imageURL] as? URL ?? info[.mediaURL] as? URL {
//                 print("Image retrieved directly using .imageURL")
                DispatchQueue.main.async {
                    picker.dismiss(animated: true, completion: {
                        self.onImagePicked?(image)
                        self.onImagePicked = nil
                    })
                }
                return
            }
        }
        if let originalImage = info[.editedImage] as? UIImage, let url = originalImage.saveTemp() {
//             print("Image retrieved using save as backup")
            picker.dismiss(animated: true, completion: {
                self.onImagePicked?(url)
                self.onImagePicked = nil
            })
        } else if let originalImage = info[.originalImage] as? UIImage, let url = originalImage.saveTemp() {
//             print("Image retrieved using save as backup")
            picker.dismiss(animated: true, completion: {
                self.onImagePicked?(url)
                self.onImagePicked = nil
            })
        } else {
            picker.dismiss(animated: true, completion: {
                self.onImagePicked = nil
            })
        }
    }
}

// save
extension UIImage {

    func saveTemp() -> URL? {
        let id = UUID().uuidString
        let tempDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp-butterfly-photos-\(id)")
        guard let url2 = self.save(at: tempDirectoryUrl) else {
            return nil
        }
//         print(url2)
        return url2
    }

    func save(at directory: FileManager.SearchPathDirectory,
              pathAndImageName: String,
              createSubdirectoriesIfNeed: Bool = true,
              compressionQuality: CGFloat = 1.0)  -> URL? {
        do {
        let documentsDirectory = try FileManager.default.url(for: directory, in: .userDomainMask,
                                                             appropriateFor: nil,
                                                             create: false)
        return save(at: documentsDirectory.appendingPathComponent(pathAndImageName),
                    createSubdirectoriesIfNeed: createSubdirectoriesIfNeed,
                    compressionQuality: compressionQuality)
        } catch {
            print("-- Error: \(error)")
            return nil
        }
    }

    func save(at url: URL,
              createSubdirectoriesIfNeed: Bool = true,
              compressionQuality: CGFloat = 1.0)  -> URL? {
        do {
            if createSubdirectoriesIfNeed {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }
            guard let data = jpegData(compressionQuality: compressionQuality) else { return nil }
            try data.write(to: url)
            return url
        } catch {
            print("-- Error: \(error)")
            return nil
        }
    }
}

