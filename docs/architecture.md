# Lockbox Architecture

## RxSwift

Lockbox makes extensive use of RxSwift, an implementation of the Observable pattern from ReactiveX. More information and many marble diagrams can be found in the [ReactiveX documentation](http://reactivex.io/).

## Presenters & Views

All views are bound to a presenter[1]. In this separation, the presenter is responsible for all business logic, and the view is abstracted to a simple protocol. The view is responsible for UI-specific configuration and passing user input to its presenter for handling. This allows any complex view-related configuration to be abstracted when dealing with business logic changes, and vice versa. Presenters should never import UIKit.

## Flux

### Architecture Pattern

In short, Flux architecture design maintains a unidirectional data flow, in which a global Dispatcher receives Actions & dispatches them to appropriate Stores. The Stores, in turn, process data & provide the source of truth for the Views. As users interact with the Views, any updates are made via a dispatched Action and the cycle begins again. See this [flux architecture](https://facebook.github.io/flux/docs/overview.html) writeup for more details on the Flux architecture scheme.

### Usage

RxSwift observables are used as the hooks between the dispatcher and stores, the stores & views, and in Action-specific cases, to deal with asynchronous application requirements.

The View component of Flux is represented by the Presenter+View couples. The Presenter is responsible for listening to the appropriate Store observables, and firing Actions to their respective handlers.

### Routing

The special case in this scenario is view routing. To handle the view-changing component of the architecture, there will be a special Store observed by a ContainerView. This “containing” view will never be displayed to the user; rather, it will perform the role of listening for navigation-specific Actions & performing the necessary top-level navigation stack swapping or navigation stack manipulation.

### Async

Asynchronous pieces of work are not handled in the definition of Flux architecture. In keeping with the typical solution for this pattern, async pieces of work in Lockbox iOS will be bundled into Action handlers, keeping Stores simple in-memory repositories to track persistent data as required by the View components.

---

[1] the name here is pure semantics -- can be thought of as a ViewModel
