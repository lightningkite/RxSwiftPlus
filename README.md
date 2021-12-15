# RxSwiftPlus

An iOS/Swift equivalent for Android's [RxKotlin Plus](https://github.com/lightningkite/rxkotlin-plus), which makes binding RxSwift to views even easier.

## RxSwift Notice

This currently requires the lightweight fork of RxSwift [here](https://github.com/lightningkite/RxSwift).  The fork only adds `Subject` and makes `Observable` an open class.  It is maintained.  Eventually, it may no longer be necessary.

## Khrysalis

This package contains [Khrysalis](https://github.com/lightningkite/khrysalis) equivalents for usage with the Khrysalis Kotlin to Swift transpiler.  You don't need to use Khrysalis for this package to be useful, however.

## Sub specs

### Core

The core package, which contains some convenient extension functions for manipulating `Observable` and `Subject`.

Most important features:

- `ValueSubject<T>` - a `BehaviorSubject` that guarantees an initial value.  Also has the property `value` for getting/setting.
- `Subject.map` - allows bidirectional mapping of a subject.
- `Observable.withWrite` - transforms an `Observable` into a `Subject` by providing some action to perform when `onNext` is called.

### Http

A package allowing easy HTTP calls in Rx style.

### Resources

A package abstracting different types of images and video, allowing for easier binding to views.

### Bindings

Contains a bunch of functions for bidirectional binding of iOS views to `Subject`s, as well as a `DisposeBag` attached to a view's lifecycle.

Some sample features:

- `UIView.removed` - a `DisposeBag` that is disposed when the view is removed from the hierarchy
- `Observable.subscribeAutoDispose(UILabel, \UILabel.text)` - show the value in the given view and keep it updated, automatically disposed when the view is removed from the hierarchy
- `Subject<String>.bind(UITextField)` - bidirectional bind to the subject, automatically disposed when the view is removed from the hierarchy
- `Observable<List<T>>.showIn(UICollectionView) { obs: Observable<T> -> UIView }` - Shows updating content in a `UICollectionView`

### BindingsCosmo

Adds bindings for the [Cosmos](https://github.com/lightningkite/Cosmos) library.

### BindingsXibToXmlRuntime

Adds bindings for `LabeledToggle` from the [XmlToXibRuntime](https://github.com/lightningkite/android-xml-to-ios-xib).

### BindingsXibToXmlRuntimeKhrysalis

Adds bindings for `InputViewButton` from the [XmlToXibRuntime](https://github.com/lightningkite/android-xml-to-ios-xib) using [Khrysalis](https://github.com/lightningkite/khrysalis).

### BindingsSearchTextField

Adds bindings for [SearchTextField](https://cocoapods.org/pods/SearchTextField).

### ViewGenerator

An alternate way of handling view navigation in iOS.  Essentially a replacement for `ViewController`.

Built to be bare-bones, a `ViewGenerator` has the following interface:

```swift
protocol ViewGenerator {
    func generate(dependency: ViewControllerAccess): UIView
}
```

where `ViewControllerAccess` is an interface for accessing an `ViewController` and its callbacks.

You can then use a `SwapView` to display a stack of view generators:

```swift
let myStack = ValueSubject<Array<ViewGenerator>>([])
myStack.showIn(swapView, viewControllerAccess)
```

Now, pushing and popping views onto the stack is really easy:

```swift
myStack.push(SomeViewGenerator("Test Data"))  // push is a shortcut function
myStack.pop()  // pop is a shortcut function
myStack.value = [MyViewGenerator(myStack)]  // You can reset the whole stack easily
```

You may have noticed that this means we can use constructors in our views.  This is one of the biggest advantages of using view generators.

This pattern was adopted from Android's [RxKotlin Plus](https://github.com/lightningkite/rxkotlin-plus/blob/master/view-generator/README.md).  You can read more there.

### ViewGeneratorCalendar

Extensions allowing convenient operations with the calendar from view generators.

### ViewGeneratorImage

Extensions allowing convenient requesting of images, video, and other media from view generators.

### ViewGeneratorLocation

Extensions allowing convenient getting of location from view generators.
