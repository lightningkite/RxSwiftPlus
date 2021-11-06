//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import SearchTextField
import RxSwift
import RxCocoa



public extension ObservableType where Element: Collection {
    @discardableResult
    func showIn<Obs: ObserverType>(_ view: SearchTextField, onItemSelected: Obs, toString: @escaping (Element.Element) -> String) -> Self where Obs.Element == Element.Element {
        return showIn(view, onItemSelected: { onItemSelected.onNext($0) }, toString: toString)
    }
    @discardableResult
    func showIn(_ view: SearchTextField, onItemSelected: @escaping (Element.Element) -> Void, toString: @escaping (Element.Element) -> String) -> Self{
        if let font = view.font { view.theme.font = font }
        if let textColor = view.textColor { view.theme.fontColor = textColor }
        
        var optionsMap = Dictionary<String, Element.Element>()
        subscribe(
            onNext: { value in
                optionsMap = [:]
                for item in value {
                    let original = toString(item)
                    var asString = original
                    var index = 2
                    while optionsMap[asString] != nil {
                        asString = original + " (\(index))"
                        index += 1
                    }
                    optionsMap[asString] = item
                }
                let array = Array(optionsMap.keys)
                view.filterStrings(array)
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        view.itemSelectionHandler = { (items, itemPosition) in
            if let item = optionsMap[items[itemPosition].title] {
                onItemSelected(item)
            }
        }
        return self
    }
}
