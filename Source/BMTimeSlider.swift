//
//  BMTimeSlider.swift
//  Pods
//
//  Created by BrikerMan on 2017/4/2.
//
//

import UIKit

open class BMTimeSlider: UISlider {
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let trackHeight: CGFloat = 6
        let position = CGPoint(x: 0, y: 14)
        let customBounds = CGRect(origin: position, size: CGSize(width: bounds.size.width, height: trackHeight))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }
    
    override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        return super.thumbRect(forBounds:
        bounds, trackRect: rect, value: value)
        .offsetBy(dx: 0, dy: 0)
    }
}
