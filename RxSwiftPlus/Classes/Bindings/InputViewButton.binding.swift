//Stub file made with Butterfly 2 (by Lightning Kite)
import RxSwift
import RxCocoa

private extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}

private class CustomAlertDialog: UIViewController, UIGestureRecognizerDelegate {
    private var customTransitioningDelegate = TransitioningDelegate()
    var tapOutsideRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    let makeView: ()->UIView
    init(makeView: @escaping ()->UIView) {
        self.makeView = makeView
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = customTransitioningDelegate
        tapOutsideRecognizer.delegate = self
    }
    required init?(coder: NSCoder) {
        self.makeView = { UIView(frame: .zero) }
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = customTransitioningDelegate
        tapOutsideRecognizer.delegate = self
    }
    
    override func viewDidLoad() {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .trailing
        stack.distribution = .fill
        
        let dismissButton = UIButton(frame: .zero)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setTitle(NSLocalizedString("OK", comment: "OK"), for: .normal)
        dismissButton.setTitleColor(.systemBlue, for: .normal)
        dismissButton.onClick { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        dismissButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16)
        stack.addArrangedSubview(dismissButton)
        
        let contentView = makeView()
        stack.addArrangedSubview(contentView)
        contentView.leadingAnchor.constraint(equalTo: stack.leadingAnchor).isActive = true
        
        self.view.addSubview(stack)
        stack.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = .systemBackground
        } else {
            self.view.backgroundColor = .lightGray
        }
    }
}

class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting)
    }
}
class PresentationController: UIPresentationController {
    let viewSize: CGSize
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = presentingViewController.view.bounds
        let size = viewSize
        let origin = CGPoint(x: bounds.midX - size.width / 2, y: bounds.maxY - size.height)
        return CGRect(origin: origin, size: size)
    }

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
//        let sizeCap = presentingViewController?.viewIfLoaded?.frame.size ?? CGSize(width: 300, height: 200)
        self.viewSize = presentedViewController.view.subviews[0].systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        presentedView?.autoresizingMask = [
            .flexibleTopMargin,
            .flexibleBottomMargin,
            .flexibleLeftMargin,
            .flexibleRightMargin
        ]

        presentedView?.translatesAutoresizingMaskIntoConstraints = true
    }
}

private extension UIView {
    func launchPickerDialog(makeView: @escaping () -> UIView) {
        self.becomeFirstResponder()
        let dialog = CustomAlertDialog(makeView: makeView)
        dialog.modalPresentationStyle = .custom
        dialog.modalTransitionStyle = .coverVertical
        parentViewController?.present(dialog, animated: true, completion: nil)
//        let pickerView = makeView()
//        let alertView = UIAlertController(title: "", message: "", preferredStyle: UIAlertController.Style.alert)
//        alertView.view.addSubview(pickerView)
//        alertView.view.topAnchor.constraint(equalTo: pickerView.topAnchor).isActive = true
////        alertView.view.sub
//        alertView.view.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor).isActive = true
//        alertView.view.leftAnchor.constraint(equalTo: pickerView.leftAnchor).isActive = true
//        alertView.view.rightAnchor.constraint(equalTo: pickerView.rightAnchor).isActive = true
//        let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
//        alertView.addAction(action)
//        parentViewController?.present(alertView, animated: true, completion: nil)
    }
}


public extension ObservableType where Element: Collection, Element.Element: Equatable{
    
    @discardableResult
    func showIn<Subject: SubjectType>(_ view: UIButton, selected: Subject, _ toString: @escaping (Element.Element) -> String = {"\($0)"}) -> Self where Subject.Observer.Element == Subject.Element, Subject.Element == Element.Element {
        
        let boundDataSource = PickerBoundDataSourceString<Subject>(selected: selected, toString: toString)
        view.retain(item: boundDataSource).disposed(by: view.removed)
        
        var lastKnownValue: Element.Element? = nil
        selected.subscribe(onNext: {
            lastKnownValue = $0
        }).disposed(by: view.removed)
        
        view.setOnClickListener { v in
            v.launchPickerDialog {
                let picker = UIPickerView()
                picker.dataSource = boundDataSource
                picker.delegate = boundDataSource
                if let lastKnownValue = lastKnownValue, let index = boundDataSource.data.firstIndex(of: lastKnownValue) {
                    picker.selectRow(index, inComponent: 0, animated: false)
                }
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
        
        let sel: Observable<Element.Element> = selected.asObservable()
        sel.map(toString).subscribeAutoDispose(view, UIButton.setTitle)
        
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
