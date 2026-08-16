import Combine
import CryptoCoreKit
import NavigationKit

@MainActor
public final class WatchlistSearchViewModel: ObservableObject {
    @Published public var query = ""
    @Published public var results: [CoinSearchResult] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let service: WatchlistServicing
    private var searchTask: Task<Void, Never>?

    public init(service: WatchlistServicing) {
        self.service = service
    }

    public func queryChanged() {
        searchTask?.cancel()
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            results = []
            errorMessage = nil
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await search(query: query)
        }
    }

    private func search(query: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            results = try await service.searchCoins(query: query)
        } catch {
            errorMessage = "\(error)"
        }
    }
}
