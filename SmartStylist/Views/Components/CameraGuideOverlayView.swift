import UIKit

// Transparent overlay placed over the UIImagePickerController live preview.
// Draws corner bracket guides and an orientation-aware tip banner.
// isUserInteractionEnabled = false so native camera controls remain fully tappable.
final class CameraGuideOverlayView: UIView {

    private let bracketLayer = CAShapeLayer()
    private let banner = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let bannerIcon = UIImageView()
    private let bannerLabel = UILabel()

    private var showingContrastTip = false
    private var tipTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        setupBrackets()
        setupBanner()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshTip),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        refreshTip()
        startTipCycle()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        tipTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    // MARK: – Setup

    private func setupBrackets() {
        bracketLayer.fillColor   = UIColor.clear.cgColor
        bracketLayer.strokeColor = UIColor.white.withAlphaComponent(0.85).cgColor
        bracketLayer.lineWidth   = 3
        bracketLayer.lineCap     = .round
        layer.addSublayer(bracketLayer)
    }

    private func setupBanner() {
        addSubview(banner)

        bannerIcon.contentMode = .scaleAspectFit
        bannerIcon.tintColor   = .white
        banner.contentView.addSubview(bannerIcon)

        bannerLabel.textColor     = .white
        bannerLabel.font          = .systemFont(ofSize: 13, weight: .semibold)
        bannerLabel.numberOfLines = 1
        bannerLabel.adjustsFontSizeToFitWidth = true
        bannerLabel.minimumScaleFactor = 0.8
        banner.contentView.addSubview(bannerLabel)
    }

    // MARK: – Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutBannerFrame()
        layoutBracketPath()
    }

    private func layoutBannerFrame() {
        let safeTop: CGFloat = safeAreaInsets.top > 0 ? safeAreaInsets.top : 44
        let bannerH: CGFloat = 48
        banner.frame = CGRect(x: 0, y: safeTop, width: bounds.width, height: bannerH)

        let iconSize: CGFloat = 20
        let gap: CGFloat      = 7
        let labelW: CGFloat   = 260
        let totalW            = iconSize + gap + labelW
        let originX           = (bounds.width - totalW) / 2
        let midY              = bannerH / 2

        bannerIcon.frame  = CGRect(x: originX, y: midY - iconSize / 2, width: iconSize, height: iconSize)
        bannerLabel.frame = CGRect(x: originX + iconSize + gap, y: 0, width: labelW, height: bannerH)
    }

    private func layoutBracketPath() {
        // Guide rect: 82 % wide, portrait 5:6 ratio, placed in the vertical center
        // of the usable area (below banner, above native camera controls ~150 pt)
        let safeTop: CGFloat  = safeAreaInsets.top > 0 ? safeAreaInsets.top : 44
        let controlsH: CGFloat = 150
        let bannerBottom      = safeTop + 48 + 12
        let usableH           = bounds.height - bannerBottom - controlsH

        let w = bounds.width * 0.82
        let h = min(w * 1.25, usableH - 24)
        let x = (bounds.width - w) / 2
        let y = bannerBottom + (usableH - h) / 2
        let rect = CGRect(x: x, y: y, width: w, height: h)

        let armLen: CGFloat    = 28
        let cornerR: CGFloat   = 12
        let path = UIBezierPath()

        func addBracket(pivot: CGPoint, hSign: CGFloat, vSign: CGFloat) {
            path.move(to: CGPoint(x: pivot.x, y: pivot.y + vSign * armLen))
            path.addLine(to: CGPoint(x: pivot.x, y: pivot.y + vSign * cornerR))
            path.addQuadCurve(
                to: CGPoint(x: pivot.x + hSign * cornerR, y: pivot.y),
                controlPoint: pivot
            )
            path.addLine(to: CGPoint(x: pivot.x + hSign * armLen, y: pivot.y))
        }

        addBracket(pivot: CGPoint(x: rect.minX, y: rect.minY), hSign: +1, vSign: +1)
        addBracket(pivot: CGPoint(x: rect.maxX, y: rect.minY), hSign: -1, vSign: +1)
        addBracket(pivot: CGPoint(x: rect.minX, y: rect.maxY), hSign: +1, vSign: -1)
        addBracket(pivot: CGPoint(x: rect.maxX, y: rect.maxY), hSign: -1, vSign: -1)

        bracketLayer.path  = path.cgPath
        bracketLayer.frame = bounds
    }

    // MARK: – Tip cycling

    private func startTipCycle() {
        tipTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard UIDevice.current.orientation != .faceUp else { return }
            self.showingContrastTip.toggle()
            UIView.transition(with: self.banner, duration: 0.35, options: .transitionCrossDissolve) {
                self.applyTipContent()
            }
        }
    }

    // MARK: – Orientation tip

    @objc private func refreshTip() {
        showingContrastTip = false
        applyTipContent()
    }

    private func applyTipContent() {
        let isFlatLay = UIDevice.current.orientation == .faceUp
        if isFlatLay {
            bannerLabel.text     = Strings.cameraGuideTipFlat
            bannerIcon.image     = UIImage(systemName: "checkmark.circle.fill")
            bannerIcon.tintColor = UIColor.systemGreen
        } else if showingContrastTip {
            bannerLabel.text     = Strings.cameraGuideTipContrast
            bannerIcon.image     = UIImage(systemName: "circle.lefthalf.filled")
            bannerIcon.tintColor = UIColor.systemYellow
        } else {
            bannerLabel.text     = Strings.cameraGuideTipHang
            bannerIcon.image     = UIImage(systemName: "tshirt.fill")
            bannerIcon.tintColor = .white
        }
    }
}
