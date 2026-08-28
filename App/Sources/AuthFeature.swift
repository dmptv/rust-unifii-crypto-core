import ComposableArchitecture

// Demo auth gate: exists to exercise the @Presents/.ifLet navigation
// pattern (optional-destination, whole-tree switch) that the rest of the
// app doesn't use elsewhere - Markets uses StackState push navigation,
// the root uses a plain TabView. Login always succeeds regardless of
// field contents; there's no real backend here.
@Reducer
struct AuthFeature {
    @ObservableState
    struct State: Equatable {
        var login: String = ""
        var password: String = ""
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case loginButtonTapped
        case loginSuccess
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .loginButtonTapped:
                return .send(.loginSuccess)

            case .loginSuccess:
                return .none
            }
        }
    }
}
