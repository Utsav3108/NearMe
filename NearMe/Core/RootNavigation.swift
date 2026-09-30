//
//  RootNavigation.swift
//  MyApp
//
//  Created by Utsav Hitendrabhai Pandya on 01/10/26.
//

import SwiftUI

struct NavigationRoot: View {
    
    
    // MARK: - Environment
    @Environment(AppRouter.self) private var appRouter
    
    // MARK: - View
    var body: some View {
        
        @Bindable var appRouter = appRouter
        
        NavigationStack(path: $appRouter.paths) {
            
            Home()
//            GettingStarted()
//                .navigationDestination(for: Route.self) { route in
//                    
//                    switch route {
//                    case .home:
//                        Home()
//                    }
//                    
//                }
            
        }
    }
}
