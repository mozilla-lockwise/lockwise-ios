# Firefox Lockwise for iOS Architecture

## RxSwift

Firefox Lockwise for iOS makes extensive use of RxSwift, an implementation of the Observable pattern from ReactiveX. More information and many marble diagrams can be found in the [ReactiveX documentation](http://reactivex.io/). The rest of this document relies on a basic understanding of the reader of the ReactiveX-style Observer implementation. Their intro document is a [good starting point](http://reactivex.io/intro.html).

## Flux

### Architecture Pattern

In short, Flux architecture design maintains a unidirectional data flow, in which a global Dispatcher receives Actions & dispatches them to appropriate Stores. The Stores, in turn, process data & provide the source of truth for the Views. As users interact with the Views, any updates are made via a dispatched Action and the cycle begins again. See this [flux architecture](https://facebook.github.io/flux/docs/overview.html) writeup for more details on the original Flux architecture scheme.

Lockbox implements a modified version of the described architecture (LockFlux), keeping in mind that the original implementation ignores asynchronous work. The key difference is in the implementation of an `ActionHandler` class. The `ActionHandler`s in some cases are a simple pass-through class for the dispatcher, but in others do some background work before dispatching the `Action`.

### Memory Management

The six major components of this architecture (`View`, `Presenter`, `Store`, `Dispatcher`, `ActionHandler`, and `Action`) have distinct lifecycle management based on their functions.

`View`/`Presenter` pairs are allocated and de-allocated as views get displayed or hidden in turn.

`Store`s, `ActionHandler`s, and the `Dispatcher` are global singleton objects, meaning that they get lazy-loaded by the application as their shared members get accessed by the `Presenter`s for view configuration or dispatching.

`Action`s get deallocated as soon as they reach the end observer for their intended function.

### View/Presenter

All views are bound to a presenter[[1](#note-1)]. In this separation, the presenter is responsible for all business logic, and the view is abstracted to a simple protocol. The view is responsible for UIKit-specific configuration and passing user input to its presenter for handling. This allows any complex view-related configuration to be abstracted when dealing with business logic changes, and vice versa. Presenters should never import UIKit in this separation of concerns. The `View` component of these view-presenter pairs maintains a strong reference to its `Presenter`, while the `Presenter` maintains a `weak` reference to the view to avoid retain cycles under `ARC`.

### Action

Actions are tiny `struct`s or `enum`s that contain declarative language about either the triggering user action or the update request for a given `Store`.

### Dispatcher

The dispatcher class is the simplest in the application; it provides an `Action`-accepting method as a wrapper for the `PublishSubject<Action>` that publishes all dispatched actions to interested `Stores`:

```
class Dispatcher {
    static let shared = Dispatcher()
    private let storeDispatchSubject = PublishSubject<Action>()

    open var register: Observable<Action> {
        return self.storeDispatchSubject.asObservable()
    }

    open func dispatch(action: Action) {
        self.storeDispatchSubject.onNext(action)
    }
}
```

### Store

Stores provide an opaque wrapper around system storage or simple `Replay- /Publish- Subject`s for the purposes of data access and view configuration.

### View Routing

The special case in this scenario is view routing. To handle the view-changing component of the architecture, there is a `RouteStore` observed by a `RootPresenter` that rides along on the back of a `RootView`. This “containing” view will never be displayed to the user; rather, it will perform the role of listening for navigation-specific `Action`s & performing the necessary top-level navigation stack swapping or navigation stack manipulation. Routing logic lives entirely separately from individual view configuration logic, allowing for modular view manipulation and easy testing.

### Example

To fully understand the concept, it's useful to trace one user action through its lifecycle of use in the app. Following is a simplified description of how the filter field (or search box) on the main item list screen works.

1. When a user enters text into the search field, the textfield binding[[2](#note-2)] on the `ItemListView` emits an event to an observer on the `ItemListPresenter`.
2. The `ItemListPresenter` dispatches a `ItemListFilterAction`, which is a simple struct with one property - `filteringText: String`.
3. The struct does a round trip through the `ItemListDisplayActionHandler`, `Dispatcher`, and `ItemListDisplayStore` before getting combined with the most recent list of items back in the `ItemListPresenter`.
4. This combined `Observable` stream with both the text and the items filters the list of items and maps the filtered list into individual cell configurations.
5. The view, on receiving the updated / filtered list, re-renders the list of items to only show the ones that the user is searching for.

There are a few other listeners for `ItemListFilterAction`s; for example, the `Observable` bound to the `isHidden` property of the Cancel button in the search bar maps the `ItemListFilterAction` with a simple `!isEmpty` check -- if the `ItemListFilterAction.filteringText` is empty, the cancel button is hidden, and if not, it's displayed. While it may seem like a lot of work to make the roundtrip with the `Dispatcher`,

### Current `ActionHandler` technical debt / area for improvement

In the current LockFlux implementation, there is a discrepancy in the ways that asynchronous work is done. In some cases, async work is done behind the scenes at the `Store` level, and in others, as part of the pass-through setup between `ActionHandler`s and the `Dispatcher`. Ideally, we would get rid of the `ActionHandler` concept altogether, and `Presenter`s would construct and dispatch `Action`s directly to the `Dispatcher`. This will simplify tests and the architecture quite a bit.

---

<a name="note-1"/>[1] the name here is pure semantics -- can be thought of as a ViewModel

<a name="note-2"/>[2] an `Observable` stream coming from the `RxCocoa` bindings for `UITextField`
