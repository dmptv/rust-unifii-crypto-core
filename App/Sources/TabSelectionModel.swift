import Combine

enum AppTab: Hashable {
    case live, async, grpc, push
}

// Deep links into Markets push onto marketsCoordinator's NavigationStack,
// but that stack lives inside the Live tab specifically. Without this,
// routing to Markets while the user is looking at a different tab silently
// updates a screen they can't see - the coordinator's state is correct,
// nothing on screen changes.
@MainActor
final class TabSelectionModel: ObservableObject {
    @Published var selectedTab: AppTab = .live
}
