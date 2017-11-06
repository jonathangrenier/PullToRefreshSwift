//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//  Qiulang rewrites it to support pull down & push up
//
import UIKit

open class PullToRefreshView: UIView {
    enum PullToRefreshState {
        case pulling
        case triggered
        case refreshing
        case stop
        case finish
    }
    
    fileprivate var options: PullToRefreshOption
    fileprivate var backgroundView: UIView
    fileprivate var arrow: UIImageView
    fileprivate var indicator: UIActivityIndicatorView
    fileprivate var scrollViewInsets: UIEdgeInsets = UIEdgeInsets.zero
    fileprivate var refreshCompletion: (() -> ())?
    fileprivate var pull: Bool = true
    fileprivate var observers = [NSKeyValueObservation]()

    fileprivate var positionY:CGFloat = 0 {
        didSet {
            if self.positionY == oldValue {
                return
            }
            var frame = self.frame
            frame.origin.y = positionY
            self.frame = frame
        }
    }
    
    var state: PullToRefreshState = PullToRefreshState.pulling {
        didSet {
            if self.state == oldValue {
                return
            }
            switch self.state {
            case .stop:
                stopAnimating()
            case .finish:
                var duration = PullToRefreshConst.animationDuration
                var time = DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self.stopAnimating()
                }
                duration = duration * 2
                time = DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self.removeFromSuperview()
                }
            case .refreshing:
                startAnimating()
            case .pulling: //starting point
                arrowRotationBack()
            case .triggered:
                arrowRotation()
            }
        }
    }
    
    // MARK: UIView
    public override convenience init(frame: CGRect) {
        self.init(options: PullToRefreshOption(), frame: frame, refreshCompletion: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(options: PullToRefreshOption, frame: CGRect, refreshCompletion: (() -> Void)?, down: Bool = true) {
        self.options = options
        self.refreshCompletion = refreshCompletion

        self.backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        self.backgroundView.backgroundColor = self.options.backgroundColor
        self.backgroundView.autoresizingMask = UIViewAutoresizing.flexibleWidth
        
        self.arrow = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        self.arrow.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        
        self.arrow.image = UIImage(named: PullToRefreshConst.imageName, in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        
        self.indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        self.indicator.bounds = self.arrow.bounds
        self.indicator.autoresizingMask = self.arrow.autoresizingMask
        self.indicator.hidesWhenStopped = true
        self.indicator.color = options.indicatorColor
        self.pull = down
        
        super.init(frame: frame)
        self.addSubview(indicator)
        self.addSubview(backgroundView)
        self.addSubview(arrow)
        self.autoresizingMask = .flexibleWidth
    }
   
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.arrow.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
        self.arrow.frame = arrow.frame.offsetBy(dx: 0, dy: 0)
        self.indicator.center = self.arrow.center
    }
    
    open override func willMove(toSuperview superView: UIView!) {
        //superview NOT superView, DO NEED to call the following method
        //superview dealloc will call into this when my own dealloc run later!!
        self.removeRegister()
        guard let scrollView = superView as? UIScrollView else {
            return
        }
        
        var observer = scrollView.observe(\.contentOffset, options: [.initial, .new]) { [weak self] (scrollView, _) in
            self?.handleScrollViewContentUpdate(scrollView: scrollView)
        }
        observers.append(observer)
        
        if !pull {
            observer = scrollView.observe(\.contentSize, options: [.initial, .new], changeHandler: { [weak self] (scrollView, _) in
                self?.handleScrollViewContentUpdate(scrollView: scrollView)
            })
            observers.append(observer)
        }
    }
    
    fileprivate func removeRegister() {
        for observer in observers {
            observer.invalidate()
        }
        
        observers = []
    }
    
    deinit {
        self.removeRegister()
    }
    
    // MARK: private
    
    fileprivate func handleScrollViewContentUpdate(scrollView: UIScrollView) {
        // Pulling State Check
        let offsetY = scrollView.contentOffset.y
        
        // Alpha set
        if PullToRefreshConst.alpha {
            var alpha = fabs(offsetY) / (self.frame.size.height + 40)
            if alpha > 0.8 {
                alpha = 0.8
            }
            self.arrow.alpha = alpha
        }
        
        if offsetY <= 0 {
            if !self.pull {
                return
            }
            
            if offsetY < -self.frame.size.height {
                // pulling or refreshing
                if scrollView.isDragging == false && self.state != .refreshing { //release the finger
                    self.state = .refreshing //startAnimating
                } else if self.state != .refreshing { //reach the threshold
                    self.state = .triggered
                }
            } else if self.state == .triggered {
                //starting point, start from pulling
                self.state = .pulling
            }
            return //return for pull down
        }
        
        //push up
        let upHeight = offsetY + scrollView.frame.size.height - scrollView.contentSize.height
        if upHeight > 0 {
            // pulling or refreshing
            if self.pull {
                return
            }
            if upHeight > self.frame.size.height {
                // pulling or refreshing
                if scrollView.isDragging == false && self.state != .refreshing { //release the finger
                    self.state = .refreshing //startAnimating
                } else if self.state != .refreshing { //reach the threshold
                    self.state = .triggered
                }
            } else if self.state == .triggered  {
                //starting point, start from pulling
                self.state = .pulling
            }
        }
    }
    // MARK: private
    
    fileprivate func startAnimating() {
        self.indicator.startAnimating()
        self.arrow.isHidden = true
        guard let scrollView = superview as? UIScrollView else {
            return
        }
        scrollViewInsets = scrollView.contentInset
        
        var insets = scrollView.contentInset
        if pull {
            insets.top += self.frame.size.height
        } else {
            insets.bottom += self.frame.size.height
        }
        scrollView.bounces = false
        UIView.animate(withDuration: PullToRefreshConst.animationDuration,
                                   delay: 0,
                                   options:[],
                                   animations: {
            scrollView.contentInset = insets
            },
                                   completion: { _ in
                if self.options.autoStopTime != 0 {
                    let time = DispatchTime.now() + Double(Int64(self.options.autoStopTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: time) {
                        self.state = .stop
                    }
                }
                self.refreshCompletion?()
        })
    }
    
    fileprivate func stopAnimating() {
        self.indicator.stopAnimating()
        self.arrow.isHidden = false
        guard let scrollView = superview as? UIScrollView else {
            return
        }
        scrollView.bounces = true
        let duration = PullToRefreshConst.animationDuration
        UIView.animate(withDuration: duration,
                                   animations: {
                                    scrollView.contentInset = self.scrollViewInsets
                                    self.arrow.transform = CGAffineTransform.identity
                                    }, completion: { _ in
            self.state = .pulling
        }
        ) 
    }
    
    fileprivate func arrowRotation() {
        UIView.animate(withDuration: 0.2, delay: 0, options:[], animations: {
            // -0.0000001 for the rotation direction control
            self.arrow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi-0.0000001))
        }, completion:nil)
    }
    
    fileprivate func arrowRotationBack() {
        UIView.animate(withDuration: 0.2, animations: {
            self.arrow.transform = CGAffineTransform.identity
        }) 
    }
}