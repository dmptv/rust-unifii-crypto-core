import Swinject

// Deliberately knows nothing about any concrete client type. Every feature
// module can safely depend on this to resolve its own dependency, without
// creating a cycle back to the app target - only CryptoCoreApp (which
// already depends on every feature) is in a position to register the
// concrete Live* implementations. See
// App/Sources/AppDependencyContainer+Registration.swift for that side.
public enum AppDependencyContainer {
    public static let shared = Container()
}
