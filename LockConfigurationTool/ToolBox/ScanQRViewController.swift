//
//  ScanQRViewController.swift
//  LockConfigurationTool
//
//  Created by mugua on 2020/6/3.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa
import Action
import Then

class ScanQRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var scanView: ScanAnimationView!
    @IBOutlet weak var dismissButton: UIButton!
    
    private var scanResultBlock: ((String?) -> Void)?
    private lazy var _session = AVCaptureSession()
    private var _cameraLayer: AVCaptureVideoPreviewLayer?
    private lazy var output: AVCaptureMetadataOutput = {
        let o = AVCaptureMetadataOutput()
        o.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return o
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scanning()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        loadViewIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "扫码"
        view.backgroundColor = UIColor.black
        setupCaptureInputs()
    }
    
    func scanCompleted(result: @escaping (String?) -> Void) {
        self.scanResultBlock = result
    }
    
    func setupCaptureInputs() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 设置有效区域
        let scanCrop = getScanRectWithPreView(preView: scanView)
        output.rectOfInterest = scanCrop
        _session.sessionPreset = .high
        _session.addInput(input)
        _session.addOutput(output)
        
        // 设置编码格式
        output.metadataObjectTypes = [.qr, .ean13, .ean8, .code128]
        _cameraLayer = AVCaptureVideoPreviewLayer(session: _session)
        _cameraLayer?.videoGravity = .resizeAspectFill
        _cameraLayer?.frame = view.layer.bounds
        view.layer.insertSublayer(_cameraLayer!, at: 0)
    }
    
    func scanStop() {
        scanView.stopAnimation()
        DispatchQueue.global().async {
            self._session.stopRunning()
        }
    }
    
    func scanning() {
        scanView.startAnimation()
        DispatchQueue.global().async {
            self._session.startRunning()
        }
    }
    
    //根据矩形区域，获取识别区域
    func getScanRectWithPreView(preView:UIView) -> CGRect
    {
        let XRetangleLeft: CGFloat = 20.0
        var sizeRetangle = CGSize(width: preView.frame.size.width - XRetangleLeft*2, height: preView.frame.size.width - XRetangleLeft*2)
        
        if (preView.bounds.height / preView.bounds.width) != 1.0
        {
            let w = sizeRetangle.width;
            var h:CGFloat = w / 1.0
            
            let hInt:Int = Int(h)
            h = CGFloat(hInt)
            
            sizeRetangle = CGSize(width: w, height: h)
        }
        
        //扫码区域Y轴最小坐标
        let YMinRetangle = preView.frame.size.height / 2.0 - sizeRetangle.height/2.0 - 60
        //扫码区域坐标
        let cropRect =  CGRect(x: XRetangleLeft, y: YMinRetangle, width: sizeRetangle.width, height: sizeRetangle.height)
        
        //计算兴趣区域
        var rectOfInterest:CGRect
        
        let size = preView.bounds.size;
        let p1 = size.height/size.width;
        
        let p2:CGFloat = 1920.0/1080.0 //使用了1080p的图像输出
        if p1 < p2 {
            let fixHeight = size.width * 1920.0 / 1080.0;
            let fixPadding = (fixHeight - size.height)/2;
            rectOfInterest = CGRect(x: (cropRect.origin.y + fixPadding)/fixHeight,
                                    y: cropRect.origin.x/size.width,
                                    width: cropRect.size.height/fixHeight,
                                    height: cropRect.size.width/size.width)
            
            
        } else {
            let fixWidth = size.height * 1080.0 / 1920.0;
            let fixPadding = (fixWidth - size.width)/2;
            rectOfInterest = CGRect(x: cropRect.origin.y/size.height,
                                    y: (cropRect.origin.x + fixPadding)/fixWidth,
                                    width: cropRect.size.height/size.height,
                                    height: cropRect.size.width/fixWidth)
        }
        return rectOfInterest
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects.count > 0 {
            let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            self.scanStop()
            
            let scanResult = metadataObject.stringValue
            
            self.showAlert(title: nil, message: scanResult, buttonTitles: ["确定"], highlightedButtonIndex: 0) {[weak self] (index) in
                if index == 0 {
                    self?.scanResultBlock?(scanResult)
                }
            }
        }
    }
    
    func openAlbum(from: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            
            let controller = UIImagePickerController()
            controller.delegate = self
            controller.sourceType = .savedPhotosAlbum
            controller.modalTransitionStyle = .flipHorizontal
            from.present(controller, animated: true, completion: nil)
        } else {
            
            let alt = UIAlertController(title: nil, message: "设备不支持访问相册，请在设置->隐私->照片中进行设置！", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "确定", style: .cancel, handler: nil)
            alt.addAction(cancel)
            from.present(alt, animated: true, completion: nil)
        }
    }
    
}


extension ScanQRViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        picker.dismiss(animated: true) {
            let features = detector?.features(in: CIImage(cgImage: image.cgImage!))
            
            if features?.count != 0 {
                guard let feature = features?.first as? CIQRCodeFeature else { return }
                let scannedResult = feature.messageString
                self.scanResultBlock?(scannedResult)
                
            } else {
                print("图片中没有二维码")
            }
        }
    }
}

class ScanAnimationView: UIView {
    
    fileprivate let bgImage = UIImageView(frame: .zero)
    fileprivate let scanLine = UIView(frame: .zero)
    fileprivate var scanHeight: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scanHeight = frame.height
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scanHeight = frame.height
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgImage.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        scanLine.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(0)
            maker.left.equalToSuperview().offset(4)
            maker.right.equalToSuperview().offset(-4)
            maker.height.equalTo(1)
        }
        
        scanHeight = self.bounds.height - 2
    }
    
    override func draw(_ rect: CGRect) {
        
        let viewWidth:CGFloat = self.bounds.width
        let viewHight:CGFloat = self.bounds.height
        let x1:CGFloat = 0.0
        let x2:CGFloat = viewWidth
        
        let y1:CGFloat = 0.0
        let y2:CGFloat = viewHight
        
        let cellLength:CGFloat = min(viewHight, viewWidth) / 20
        let lineWidth:CGFloat = 0.5
        
        let context = UIGraphicsGetCurrentContext()
        context!.setLineWidth(lineWidth)
        context!.setStrokeColor(ColorClassification.primary.value.withAlphaComponent(0.6).cgColor)
        
        // draw horizontal lines
        var i:CGFloat = 0.0
        repeat {
            context?.move(to: CGPoint(x: x1, y: cellLength + i))
            context?.addLine(to: CGPoint(x: x2, y: cellLength + i))
            i = i + cellLength
            
        } while i < rect.height - cellLength
        
        // draw vertical lines
        var j:CGFloat = 0.0
        repeat {
            context?.move(to: CGPoint(x: cellLength + j, y: y1))
            context?.addLine(to: CGPoint(x: cellLength + j, y: y2))
            j = j + cellLength
            
        } while j < rect.width - cellLength
        
        context!.strokePath()
    }
}

extension ScanAnimationView {
    
    fileprivate func commonInit() {
        bgImage.image = UIImage(named: "qr_border_bg")?.filled(withColor: ColorClassification.primary.value)
        self.addSubview(bgImage)
        scanLine.backgroundColor = UIColor.white
        self.addSubview(scanLine)
        self.scanLine.isHidden = true
        self.backgroundColor = .clear
    }
    
    func startAnimation() {
        
        let duration: CFTimeInterval = 0.0
        
        layoutIfNeeded()
        UIView.animate(withDuration: 1, delay: duration, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.scanLine.transform.ty = self.scanHeight
        }, completion: nil)
        self.scanLine.isHidden = false
    }
    
    func stopAnimation() {
        bgImage.layer.removeAllAnimations()
        scanLine.isHidden = true
        layoutIfNeeded()
    }
}

extension Reactive where Base: ScanQRViewController {
    
    static func present() -> Observable<String?> {
        
        return Observable<String?>.create { (observer) -> Disposable in
            
            let scanVC = ScanQRViewController().then { vc in
                let dismissAction = CocoaAction {
                    observer.onNext(nil)
                    observer.onCompleted()
                    vc.dismiss(animated: true, completion: nil)
                    return .empty()
                }
                vc.dismissButton.rx.action = dismissAction
            }
            
            scanVC.scanCompleted { (scanString) in
                observer.onNext(scanString)
                observer.onCompleted()
            }
            
            if let currentVC = RootViewController.topViewController() {
                currentVC.present(scanVC, animated: true, completion: nil)
            } else {
                observer.onCompleted()
            }
            return Disposables.create {
                scanVC.dismiss(animated: true, completion: nil)
            }
        }
    }
}
