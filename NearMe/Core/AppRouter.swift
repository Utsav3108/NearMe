import Foundation
import Observation

enum Route: Hashable {
    case home
}

enum AppTab: String, CaseIterable, Hashable {
    case home
    case explore
    case create
    case saved
    case profile

    var title: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .explore: "safari"
        case .create: "plus.circle"
        case .saved: "bookmark"
        case .profile: "person"
        }
    }
}

@Observable
@MainActor
final class AppRouter {
    private enum StorageKey {
        static let isAuthenticated = "isLogin"
    }

    private let defaults: UserDefaults

    var isAuthenticated: Bool
    var showsSignIn = false
    var selectedTab: AppTab = .home
    var paths: [AppTab: [Route]] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isAuthenticated = defaults.bool(forKey: StorageKey.isAuthenticated)
    }

    func showSignIn() {
        showsSignIn = true
    }

    func showOnboarding() {
        showsSignIn = false
    }

    func completeAuthentication() {
        defaults.set(true, forKey: StorageKey.isAuthenticated)
        isAuthenticated = true
        showsSignIn = false
        selectedTab = .home
        paths.removeAll()
    }

    func signOut() {
        defaults.removeObject(forKey: StorageKey.isAuthenticated)
        isAuthenticated = false
        showsSignIn = false
        selectedTab = .home
        paths.removeAll()
    }

    func push(_ route: Route, in tab: AppTab? = nil) {
        let destinationTab = tab ?? selectedTab
        paths[destinationTab, default: []].append(route)
    }

    func popLast(in tab: AppTab? = nil) {
        let destinationTab = tab ?? selectedTab
        paths[destinationTab]?.removeLast()
    }

    func popAll(in tab: AppTab? = nil) {
        let destinationTab = tab ?? selectedTab
        paths[destinationTab] = []
    }
}
