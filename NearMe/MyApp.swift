import SwiftData
import SwiftUI

@main
struct MyApp: App {
    @State private var appRouter = AppRouter()

    var body: some Scene {
        WindowGroup {
            NavigationRoot()
                .environment(appRouter)
        }
        .modelContainer(for: [PlaceInteraction.self, SavedPlace.self])
    }
}
