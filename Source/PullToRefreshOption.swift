//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//
import UIKit

struct PullToRefreshConst {
    static let tag = 810
    static let alpha = true
    static let height: CGFloat = 80
    static let imageName: String = "pulltorefresharrow.png"
    static let animationDuration: Double = 0.4
    static let fixedTop = true // PullToRefreshView fixed Top
}

public class PullToRefreshOption {
    public var backgroundColor = UIColor.clear
    public var indicatorColor = UIColor.gray
    public var autoStopTime: Double = 0.7 // 0 is not auto stop
    public var fixedSectionHeader = false  // Update the content inset for fixed section headers
    public var topInset: CGFloat = 0
    
    public init() {
    }
}
