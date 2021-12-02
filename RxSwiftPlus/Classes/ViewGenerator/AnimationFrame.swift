//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import CoreGraphics
import RxSwift


public func delay(_ milliseconds: Int, _ action: @escaping () -> Void) -> Void {
    if milliseconds == 0 {
        action()
    } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(Int(milliseconds)), execute: action)
    }
}

//--- animationFrame
public let animationFrame: PublishSubject<CGFloat> = {
    let temp = PublishSubject<CGFloat>()
    frame()
    return temp
}()

private func frame(){
    let start = Date()
    delay(15){
        let end = Date()
        animationFrame.onNext(CGFloat(end.timeIntervalSince(start)))
        frame()
    }
}
