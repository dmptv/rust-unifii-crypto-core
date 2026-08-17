import SwiftUI

// Shared shape for "a screen that shows a spinner while loading, an error
// message if the request failed, or its real content otherwise" — the same
// three-way branch was copy-pasted across News, Markets, Async, and gRPC
// before this existed.
public struct RequestStateModifier: ViewModifier {
    let isLoading: Bool
    let errorMessage: String?

    public func body(content: Content) -> some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .padding()
        } else {
            content
        }
    }
}

public extension View {
    func requestState(isLoading: Bool, errorMessage: String?) -> some View {
        modifier(RequestStateModifier(isLoading: isLoading, errorMessage: errorMessage))
    }
}
