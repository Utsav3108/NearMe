import SwiftUI

@main struct MyApp: App {
    
    @State var appRouter : AppRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            NavigationRoot()
                .environment(appRouter)
        }
    }
}
