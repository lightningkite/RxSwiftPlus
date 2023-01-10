import KhrysalisRuntime
import Foundation

public protocol ForegroundNotificationHandler: AnyObject {
    
    func handleNotificationInForeground(_ map: Dictionary<String, String>) -> ForegroundNotificationHandlerResult
}
public extension ForegroundNotificationHandler {
    func handleNotificationInForeground(_ map: Dictionary<String, String>) -> ForegroundNotificationHandlerResult {
        return ForegroundNotificationHandlerResult.ShowNotification
    }
}

public enum ForegroundNotificationHandlerResult: KotlinEnum, Codable, Hashable, Comparable {
    case SuppressNotification
    case ShowNotification
    case Unhandled
    
    public static let caseNames = ["SuppressNotification", "ShowNotification", "Unhandled"]
}


