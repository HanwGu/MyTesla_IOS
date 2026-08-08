//
//  Extensions.swift
//  TeslaMateApp
//

import SwiftUI

extension Date {
    func timeAgoDisplay() -> String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "刚刚更新" }
        else if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        else if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        else { return "\(Int(interval / 86400))天前" }
    }
}

extension Array where Element == Drive {
    func filter(in range: Range<Date>) -> [Drive] {
        filter { range.contains($0.startTime) }
    }
}
