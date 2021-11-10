//Stub file made with Butterfly 2 (by Lightning Kite)
import XmlToXibRuntime
import RxSwift
import RxCocoa

private extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}

private extension UIView {
    func launchPickerDialog(makeView: () -> UIView) {
        let pickerView = makeView()
        let alertView = UIAlertController(title: "", message: "", preferredStyle: UIAlertController.Style.alert)
        alertView.view.addSubview(pickerView)
        let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alertView.addAction(action)
        parentViewController?.present(alertView, animated: true, completion: nil)
    }
}


public extension ObservableType where Element: Collection, Element.Element: Equatable{
    
    @discardableResult
    func showIn<Subject: SubjectType>(_ view: UIButton, selected: Subject, _ toString: @escaping (Element.Element) -> String = {"\($0)"}) -> Self where Subject.Observer.Element == Subject.Element, Subject.Element == Element.Element {
        
        let boundDataSource = PickerBoundDataSourceString<Subject>(selected: selected, toString: toString)
        view.retain(item: boundDataSource).disposed(by: view.removed)
        
        view.setOnClickListener { v in
            v.launchPickerDialog {
                let picker = UIPickerView()
                picker.dataSource = boundDataSource
                picker.delegate = boundDataSource
                return picker
            }
        }

        subscribe(
            onNext: { value in
                boundDataSource.data = Array(value)
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        
        return self
    }
    
//    func showInObservable(_ view: InputViewButton, _ selected: PublishSubject<Element.Element>, _ toString: @escaping (Element.Element) -> Observable<String>) -> Self{
//
//        let picker = UIPickerView()
//        let boundDataSource = PickerBoundDataSource<Element>(selected: selected, toString: toString)
//        picker.dataSource = boundDataSource
//        picker.delegate = boundDataSource
//        view.retain(item: boundDataSource).disposed(by: view.removed)
//
//        selected.flatMap(toString).subscribe(
//            onNext: { value in
//                view.setTitle(value, for: .normal)
//            },
//            onError: nil,
//            onCompleted: nil,
//            onDisposed: nil
//        ).disposed(by: view.removed)
//
//        selected.subscribe(
//            onNext: { value in
//                let index = boundDataSource.data.firstIndex(of: value) ?? -1
//                if index != -1 {
//                    picker.selectRow(index, inComponent: 0, animated: false)
//                }
//            },
//            onError: nil,
//            onCompleted: nil,
//            onDisposed: nil
//        ).disposed(by: view.removed)
//
//        subscribe(
//            onNext: { value in
//                boundDataSource.data = Array(value)
//                picker.reloadAllComponents()
//            },
//            onError: nil,
//            onCompleted: nil,
//            onDisposed: nil
//        ).disposed(by: view.removed)
//
//        return self
//    }
}

public extension SubjectType where Observer.Element == Element, Element == Optional<Date> {
    @discardableResult
    func bind(_ view: UIButton, _ mode:UIDatePicker.Mode, formatter: DateFormatter? = nil, nullText:String) -> Self {
        let formatter = formatter ?? ({
            let newF = DateFormatter()
            switch mode {
            case .time:
                newF.dateStyle = .none
                newF.timeStyle = .short
            case .date:
                newF.dateStyle = .short
                newF.timeStyle = .none
            case .dateAndTime:
                newF.dateStyle = .short
                newF.timeStyle = .short
            default:
                newF.dateStyle = .none
                newF.timeStyle = .none
            }
            return newF
        }())
        view.onClick(self.asObservable()) { [weak view] date in
            guard let view = view else { return }
            view.launchPickerDialog {
                let picker = UIDatePicker()
                if #available(iOS 13.4, *) {
                    picker.preferredDatePickerStyle = .wheels
                } else {
                    // Fallback on earlier versions
                }
                picker.datePickerMode = mode
                picker.date = date ?? Date()
                
                let observer = self.asObserver()
                picker.addAction(for: .valueChanged, action: {
                    observer.onNext(picker.date)
                }).disposed(by: view.removed)
                return picker
            }
        }
        
        subscribe(
            onNext: { value in
                if let value = value {
                    view.setTitle(formatter.string(from: value), for: .normal)
                } else {
                    view.setTitle(nullText, for: .normal)
                }
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        
        return self
    }
}

public extension SubjectType where Observer.Element == Element, Element == Date {
    @discardableResult
    func bind(_ view: UIButton, _ mode:UIDatePicker.Mode, formatter: DateFormatter? = nil) -> Self {
        let formatter = formatter ?? ({
            let newF = DateFormatter()
            switch mode {
            case .time:
                newF.dateStyle = .none
                newF.timeStyle = .short
            case .date:
                newF.dateStyle = .short
                newF.timeStyle = .none
            case .dateAndTime:
                newF.dateStyle = .short
                newF.timeStyle = .short
            default:
                newF.dateStyle = .none
                newF.timeStyle = .none
            }
            return newF
        }())
        view.onClick(self.asObservable()) { [weak view] date in
            guard let view = view else { return }
            view.launchPickerDialog {
                let picker = UIDatePicker()
                if #available(iOS 13.4, *) {
                    picker.preferredDatePickerStyle = .wheels
                } else {
                    // Fallback on earlier versions
                }
                picker.datePickerMode = mode
                picker.date = date
                
                let observer = self.asObserver()
                picker.addAction(for: .valueChanged, action: {
                    observer.onNext(picker.date)
                }).disposed(by: view.removed)
                return picker
            }
        }
        
        subscribe(
            onNext: { value in
                view.setTitle(formatter.string(from: value), for: .normal)
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        
        return self
    }
}


// This use to take in the old property style observable, but now it uses raw rx. However, getting the data is
// a bit more difficult. If i pass in the observable directly and subscribe and store the results in data I
// will need to do that in the init block, but that's not possible due to capturing self before the object is
// fully initialized. So we need to set data outside this object in a subscribe block. It's terrible I know.
class PickerBoundDataSourceString<Subject: SubjectType>: NSObject, UIPickerViewDataSource, UIPickerViewDelegate where Subject.Element == Subject.Observer.Element {
    typealias T = Subject.Element
    var data: Array<T> = []
    var selected: Subject
    let toString: (T) -> String

    init(selected: Subject, toString: @escaping (T) -> String) {
        self.selected = selected
        self.toString = toString
        super.init()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return toString(data[row])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selected.asObserver().onNext(data[row])
    }

}


// This use to take in the old property style observable, but now it uses raw rx. However, getting the data is
// a bit more difficult. If i pass in the observable directly and subscribe and store the results in data I
// will need to do that in the init block, but that's not possible due to capturing self before the object is
// fully initialized. So we need to set data outside this object in a subscribe block. It's terrible I know.
//class PickerBoundDataSource<T: Collection>: NSObject, UIPickerViewDataSource, UIPickerViewDelegate{
//    var data: Array<T.Element> = []
//    var selected: PublishSubject<T.Element>
//    let toString: (T.Element) -> Observable<String>
//
//    private var ext = ExtensionProperty<UIView, PublishSubject<T>>()
//
//    init(selected: PublishSubject<T.Element>, toString: @escaping (T.Element) -> Observable<String>) {
//        self.selected = selected
//        self.toString = toString
//        super.init()
//    }
//
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return data.count
//    }
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        <#code#>
//    }
//
////    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> Observable<String> {
////        return toString(data[row])
////    }
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        selected.onNext(data[row])
//    }
//
//}
