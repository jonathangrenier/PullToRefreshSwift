//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//
import UIKit

public protocol PullToRefreshDelegate: AnyObject {
    func didCompletePullToRefresh()
}

public class PullToRefreshView: UIView {
    enum PullToRefreshState {
        case Normal
        case Pulling
        case Refreshing
    }
    
    // MARK: Variables
    let contentOffsetKeyPath = "contentOffset"
    var kvoContext = ""
    
    private var options: PullToRefreshOption!
    private var backgroundView: UIView!
    private var arrow: UIImageView!
    private var indicator: UIActivityIndicatorView!
    private var scrollViewBounces: Bool = false
    private var scrollViewInsets = UIEdgeInsets.zero
    private var previousOffset: CGFloat = 0
    
    public weak var delegate: PullToRefreshDelegate? = nil
    public var additionalInsetTop: CGFloat = 0
    
    var state: PullToRefreshState = PullToRefreshState.Normal {
        didSet {
            if self.state == oldValue {
                return
            }
            switch self.state {
            case .Normal:
                stopAnimating()
            case .Refreshing:
                startAnimating()
            default:
                break
            }
        }
    }
    
    // MARK: UIView
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init(options: PullToRefreshOption, frame: CGRect) {
        self.init(frame: frame)
        self.options = options

        self.backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        self.backgroundView.backgroundColor = self.options.backgroundColor
        self.backgroundView.autoresizingMask = .flexibleWidth
        self.addSubview(backgroundView)
        
        self.arrow = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        self.arrow.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        
        self.arrow.image = UIImage(named: PullToRefreshConst.imageName, in: Bundle(for: type(of: self)), compatibleWith: nil)
        self.addSubview(arrow)
        
        self.indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        self.indicator.bounds = self.arrow.bounds
        self.indicator.autoresizingMask = self.arrow.autoresizingMask
        self.indicator.hidesWhenStopped = true
        self.indicator.color = options.indicatorColor
        self.addSubview(indicator)
        
        self.autoresizingMask = .flexibleWidth
    }
   
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.arrow.center = CGPoint(x: self.frame.size.width / 2, y: (self.frame.size.height / 2) + options.topInset)
        self.indicator.center = self.arrow.center
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        
        superview?.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &kvoContext)
        
        if let scrollView = newSuperview as? UIScrollView {
            scrollView.addObserver(self, forKeyPath: contentOffsetKeyPath, options: .initial, context: &kvoContext)
        }
    }
    
    deinit {
        if let scrollView = superview as? UIScrollView {
            scrollView.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &kvoContext)
        }
    }
    
    // MARK: KVO

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (context == &kvoContext && keyPath == contentOffsetKeyPath) {
            if let scrollView = object as? UIScrollView {
                
                // Debug
                //println(scrollView.contentOffset.y)
                
                let offsetWithoutInsets = self.previousOffset + self.scrollViewInsets.top
                
                // Update the content inset for fixed section headers
                if self.options.fixedSectionHeader && self.state == .Refreshing {
                    if (scrollView.contentOffset.y > 0) {
                        scrollView.contentInset = .zero;
                    }
                    return
                }
                
                // Alpha set
                if PullToRefreshConst.alpha {
                    var alpha = fabs(offsetWithoutInsets) / (self.frame.size.height + 30)
                    if alpha > 0.8 {
                        alpha = 0.8
                    }
                    self.arrow.alpha = alpha
                }
                
                // Backgroundview frame set
                if PullToRefreshConst.fixedTop {
                    if PullToRefreshConst.height < fabs(offsetWithoutInsets) {
                        self.backgroundView.frame.size.height = fabs(offsetWithoutInsets)
                    } else {
                        self.backgroundView.frame.size.height =  PullToRefreshConst.height
                    }
                } else {
                    self.backgroundView.frame.size.height = PullToRefreshConst.height + fabs(offsetWithoutInsets)
                    self.backgroundView.frame.origin.y = -fabs(offsetWithoutInsets)
                }
                
                // Pulling State Check
                if (offsetWithoutInsets < -self.frame.size.height) {
                    
                    // pulling or refreshing
                    if (scrollView.isDragging == false && self.state != .Refreshing) {
                        self.state = .Refreshing
                    } else if (self.state != .Refreshing) {
                        self.arrowRotation()
                        self.state = .Pulling
                    }
                } else if (self.state != .Refreshing && offsetWithoutInsets < 0) {
                    // normal
                    self.arrowRotationBack()
                }
                self.previousOffset = scrollView.contentOffset.y
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: private
    
    private func startAnimating() {
        self.indicator.startAnimating()
        self.arrow.isHidden = true
        
        if let scrollView = superview as? UIScrollView {
            scrollViewBounces = scrollView.bounces
            scrollViewInsets = scrollView.contentInset
            
            var insets = scrollView.contentInset
            insets.top += self.frame.size.height
            scrollView.contentOffset.y = self.previousOffset
            scrollView.bounces = false
            UIView.animate(withDuration: PullToRefreshConst.animationDuration, delay: 0, options:[], animations: {
                scrollView.contentInset = insets
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: -insets.top)
                }, completion: {finished in
                    if self.options.autoStopTime != 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.options.autoStopTime) {
                            self.state = .Normal
                        }
                    }
                    self.delegate?.didCompletePullToRefresh()
            })
        }
    }
    
    private func stopAnimating() {
        self.indicator.stopAnimating()
        self.arrow.transform = CGAffineTransform.identity
        self.arrow.isHidden = false
        
        if let scrollView = superview as? UIScrollView {
            scrollView.bounces = self.scrollViewBounces
            UIView.animate(withDuration: PullToRefreshConst.animationDuration, animations: { () -> Void in
                scrollView.contentInset = self.scrollViewInsets
                }) { (Bool) -> Void in
                    
            }
        }
    }

    private func arrowRotation() {
        UIView.animate(withDuration: 0.2, delay: 0, options:[], animations: {
            // -0.0000001 for the rotation direction control
            self.arrow.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI-0.0000001))
        }, completion:nil)
    }
    
    private func arrowRotationBack() {
        UIView.animate(withDuration: 0.2, delay: 0, options:[], animations: {
            self.arrow.transform = CGAffineTransform.identity
            }, completion:nil)
    }
}
