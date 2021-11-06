//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import MapKit
import EventKitUI


//--- ViewControllerAccess
public extension ViewControllerAccess {

    //--- ViewControllerAccess.openEvent(String, String, String, Date, Date)
    func openEvent(title: String, description: String, location: String, start: Date, end: Date) -> Void {
        let store = EKEventStore()
        store.requestAccess(to: .event) { (hasPermission, error) in
            if hasPermission {
                DispatchQueue.main.async {
                    let addController = EKEventEditViewController()
                    addController.eventStore = store
                    addController.editViewDelegate = self
                    let event = EKEvent(eventStore: store)
                    event.title = title
                    event.notes = description
                    event.location = location
                    event.startDate = start
                    event.endDate = end
                    addController.event = event
                    self.parentViewController.present(addController, animated: true, completion: nil)
                }
            }
        }
    }
}
extension ViewControllerAccess: EKEventEditViewDelegate {
    public func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.parentViewController.dismiss(animated: true)
    }
}
