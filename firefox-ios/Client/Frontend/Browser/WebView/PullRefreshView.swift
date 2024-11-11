// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class PullRefreshView: UIView,
                       ThemeApplicable {
    private struct UX {
        static let progressViewPadding: CGFloat = 24.0
        static let progressViewSize: CGFloat = 40.0
        static let progressViewAnimatedBackgroundSize: CGFloat = 30.0
        static let progressViewAnimatedBackgroundBlinkTransform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        static let progressViewAnimatedBackgroundFinalAnimationTransform = CGAffineTransform(scaleX: 15.0, y: 15.0)
        static let easterEggSize = CGSize(width: 80.0, height: 100.0)
        static let easterEggDelayInSeconds: CGFloat = 4.0
    }

    private let onRefreshCallback: VoidReturnCallback
    private lazy var progressView: UIImageView = .build { view in
        view.image = UIImage(named: StandardImageIdentifiers.Large.arrowClockwise)?.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
    }
    private let progressContainerView: UIView = .build { view in
        view.layer.cornerRadius = UX.progressViewAnimatedBackgroundSize / 2.0
        view.backgroundColor = .clear
    }
    private weak var scrollView: UIScrollView?
    private var obeserveTicket: NSKeyValueObservation?
    private var currentTheme: Theme?
    private var refreshIconHasFocus = false
    private lazy var easterEggGif: UIImageView? = {
        let imageView = loadGifFromBundle(named: "easterEggGif")
        imageView?.isHidden = true
        imageView?.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    init(parentScrollView: UIScrollView?,
         isPotraitOrientation: Bool,
         onRefreshCallback: @escaping VoidReturnCallback) {
        self.scrollView = parentScrollView
        self.onRefreshCallback = onRefreshCallback
        super.init(frame: .zero)
        clipsToBounds = true
        setupEasterEgg(isPotrait: isPotraitOrientation)
        setupSubviews()
        startObservingContentScroll()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEasterEgg(isPotrait: Bool) {
        if let easterEggGif {
            addSubview(easterEggGif)
            let layoutBuilder = EasterEggViewLayoutBuilder(easterEggSize: UX.easterEggSize)
            layoutBuilder.layoutEasterEggView(easterEggGif, superview: self, isPotrait: isPotrait)
        }
    }

    private func setupSubviews() {
        addSubviews(progressContainerView, progressView)
        NSLayoutConstraint.activate([
            progressContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.progressViewPadding),
            progressContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressContainerView.heightAnchor.constraint(equalToConstant: UX.progressViewAnimatedBackgroundSize),
            progressContainerView.widthAnchor.constraint(equalToConstant: UX.progressViewAnimatedBackgroundSize),

            progressView.centerYAnchor.constraint(equalTo: progressContainerView.centerYAnchor),
            progressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressView.heightAnchor.constraint(equalToConstant: UX.progressViewSize),
            progressView.widthAnchor.constraint(equalToConstant: UX.progressViewSize)
        ])
    }

    /// Starts observing the `UIScrollView` content offset so the refresh can react to content change and show
    /// the correct state of the pull to refresh view.
    func startObservingContentScroll() {
        obeserveTicket = scrollView?.observe(\.contentOffset) { [weak self] _, _ in
            guard let scrollView = self?.scrollView, scrollView.isDragging
            else {
                guard let refreshHasFocus = self?.refreshIconHasFocus, refreshHasFocus else { return }
                self?.refreshIconHasFocus = false
                self?.easterEggGif?.removeFromSuperview()
                self?.easterEggGif = nil
                self?.obeserveTicket?.invalidate()
                self?.triggerReloadAnimation()
                return
            }
            if scrollView.contentOffset.y < -80.0 {
                self?.blinkBackgroundProgressViewIfNeeded()
                DispatchQueue.main.asyncAfter(deadline: .now() + UX.easterEggDelayInSeconds) {
                    self?.showEasterEgg()
                }
            } else {
                self?.restoreBackgroundProgressViewIfNeeded()
                let rotationAngle = -(scrollView.contentOffset.y / (self?.frame.height ?? 0.0)) * .pi * 2
                UIView.animate(withDuration: 0.1) {
                    self?.progressView.transform = CGAffineTransform(rotationAngle: rotationAngle)
                }
            }
        }
    }

    private func triggerReloadAnimation() {
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
            self.progressContainerView.transform = UX.progressViewAnimatedBackgroundFinalAnimationTransform
        }, completion: { _ in
            self.progressContainerView.backgroundColor = .clear
            self.progressContainerView.transform = .identity
            self.progressView.transform = .identity
            self.onRefreshCallback()
        })
    }

    private func blinkBackgroundProgressViewIfNeeded() {
        guard !refreshIconHasFocus else { return }
        refreshIconHasFocus = true
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 10,
                       animations: {
            self.progressContainerView.transform = UX.progressViewAnimatedBackgroundBlinkTransform
            self.progressContainerView.backgroundColor = self.currentTheme?.colors.layer4
        }, completion: { _ in
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        })
    }

    private func restoreBackgroundProgressViewIfNeeded() {
        guard refreshIconHasFocus else { return }
        refreshIconHasFocus = false
        UIView.animate(withDuration: 0.3) {
            self.progressContainerView.transform = .identity
            self.progressContainerView.backgroundColor = .clear
        }
    }
    
    private func showEasterEgg() {
        guard let easterEggGif else { return }
        easterEggGif.isHidden = false
        let angle = atan2(easterEggGif.transform.b, easterEggGif.transform.a)
        UIView.animate(withDuration: 0.3) {
            easterEggGif.transform = .identity.rotated(by: angle)
        }
    }

    func stopObservingContentScroll() {
        obeserveTicket?.invalidate()
    }
    
    func updateEasterEggForOrientationChange(isPotrait: Bool) {
        guard let easterEggGif else { return }
        easterEggGif.removeFromSuperview()
        insertSubview(easterEggGif, at: 0)
        let layoutBuilder = EasterEggViewLayoutBuilder(easterEggSize: UX.easterEggSize)
        layoutBuilder.layoutEasterEggView(easterEggGif, superview: self, isPotrait: isPotrait)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        backgroundColor = theme.colors.layer1
        progressView.tintColor = theme.colors.iconPrimary
    }

    private func loadGifFromBundle(named name: String) -> UIImageView? {
        guard let gifPath = Bundle.main.path(forResource: name, ofType: "gif"),
              let gifData = NSData(contentsOfFile: gifPath) as Data?,
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return nil
        }

        var frames: [UIImage] = []
        let frameCount = CGImageSourceGetCount(source)

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                frames.append(UIImage(cgImage: cgImage))
            }
        }

        let animatedImage = UIImage.animatedImage(with: frames, duration: Double(frameCount) * 0.1)
        let imageView = UIImageView(image: animatedImage)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }

    deinit {
        obeserveTicket?.invalidate()
    }
}

struct EasterEggViewLayoutBuilder {
    let easterEggSize: CGSize
    let sidePadding: CGFloat = 32.0
    
    func layoutEasterEggView(_ view: UIView, superview: UIView, isPotrait: Bool) {
        if isPotrait {
            layoutEasterEggView(view, superview: superview, position: randomPotraitLayoutPosition())
        } else {
            layoutEasterEggView(view, superview: superview, position: randomLandscapeLayoutPosition())
        }
    }
    
    private func layoutEasterEggView(_ view: UIView, superview: UIView, position: NSRectAlignment) {
        let constraints: [NSLayoutConstraint] = switch position {
        case .topLeading:
            [
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -easterEggSize.height / 1.5),
                view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor,
                                              constant: sidePadding)
            ]
        case .leading:
            [
                view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor),
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -easterEggSize.height / 2.0)
            ]
        case .bottomLeading:
            [
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor,
                                              constant: sidePadding)
            ]
        case .bottomTrailing:
            [
                view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor,
                                               constant: -sidePadding),
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ]
        case .trailing:
            [
                view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -easterEggSize.height / 2.0)
            ]
        case .topTrailing:
            [
                view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor,
                                               constant: -sidePadding),
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -easterEggSize.height / 1.5)
            ]
        default:
            []
        }
        view.transform = easterEggTransformation(for: position)
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: easterEggSize.height),
            view.widthAnchor.constraint(equalToConstant: easterEggSize.width)
        ] + constraints)
    }

    func easterEggTransformation(for alignment: NSRectAlignment) -> CGAffineTransform {
        return switch alignment {
        case .topLeading:
            CGAffineTransform(translationX: 0, y: -easterEggSize.height).rotated(by: .pi)
        case .leading:
            CGAffineTransform(translationX: -easterEggSize.height, y: 0).rotated(by: .pi / 2)
        case .bottomLeading:
            CGAffineTransform(translationX: 0, y: easterEggSize.height)
        case .bottomTrailing:
            CGAffineTransform(translationX: 0, y: easterEggSize.height)
        case .trailing:
            CGAffineTransform(translationX: easterEggSize.height, y: 0).rotated(by: -.pi / 2)
        case .topTrailing:
            CGAffineTransform(translationX: 0, y: -easterEggSize.height).rotated(by: .pi)
        default:
            .identity
        }
    }

    private func randomPotraitLayoutPosition() -> NSRectAlignment {
        let allowedPositions: [NSRectAlignment] = [
            .bottomLeading,
            .bottomTrailing,
            .topLeading,
            .topTrailing,
            .leading,
            .trailing
        ]
        return allowedPositions.randomElement() ?? .bottomLeading
    }
    
    private func randomLandscapeLayoutPosition() -> NSRectAlignment {
        let allowedPositions: [NSRectAlignment] = [
            .bottomLeading,
            .bottomTrailing
        ]
        return allowedPositions.randomElement() ?? .bottomLeading
    }
}
