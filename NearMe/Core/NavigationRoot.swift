//
//  RootNavigation.swift
//  MyApp
//
//  Created by Utsav Hitendrabhai Pandya on 01/10/26.
//

import SwiftUI


enum AppTab : Hashable {
    case home
    case explore
    case create
    case saved
    case profile
}

struct NavigationRoot: View {
    
    
    // MARK: Environment
    @Environment(AppRouter.self) private var appRouter
    
    // MARK: View
    var body: some View {
        
        MainTabView()
    }
}


struct MainTabView : View {
    
    @Environment(AppRouter.self) private var appRouter
    
    @State private var selectedTab : AppTab = .home
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            
            @Bindable var appRouter = appRouter
            
                Home()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .home:
                            Home()
                        }
                    }
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                .tag(AppTab.home)
            
        }
        
        
        
    }
}
