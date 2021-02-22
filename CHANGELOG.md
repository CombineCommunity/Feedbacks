**v0.3.0 - Tyranus**:

- Feedback: introduce the "on:" keyword to explicitly declare the type of state that concerns the side effect
- Feedback: replace the parameter "sideEffect" by "perform" to have a nice readable sentence: ...(on: Loading.self, ..., perform: sideEffect)
- State Machine: introduce a new DSL based on From/On that allows to group transitions from the same state type
- State Machine: provide assert functions to ease the unit tests of transitions

**v0.2.0 - Vader**:

- UISystem: unify the UISystem concept for RawState and ViewState
- Improve the README

**v0.1.0 - Sidious:**

- Transitions, Transition, Feedacks, Feedback and System initial functional version
- Provide helpers to inject dependencies inside side effects 
- Ability to make loops communicate via Mediators
- Create Readme / Logo
- Add CounterApp and GiphyApp examples
- Add some community assets (PR template, code of conduct, ...)
