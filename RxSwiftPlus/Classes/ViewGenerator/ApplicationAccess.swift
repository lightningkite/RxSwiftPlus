import UIKit
import RxSwift

public class ApplicationAccess {
    public static let INSTANCE = ApplicationAccess()

    //--- _applicationIsActive
    public let applicationIsActiveEvent = PublishSubject<Bool>()
    public let foreground: Observable<Bool>
    
    init() {
        foreground = applicationIsActiveEvent
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
    }
    
    public let softInputActive = ValueSubject<Bool>(false)
}
