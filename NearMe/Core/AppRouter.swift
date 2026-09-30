//
//  AppRouter.swift
//  MyApp
//
//  Created by Utsav Hitendrabhai Pandya on 30/09/26.
//

import Observation

enum Route : Hashable {
    case home
}


@Observable
class AppRouter {
    
    var paths : [Route] = []
    
    func push(_ route: Route) {
        paths.append(route)
    }
    
    func popLast() -> Route {
        return paths.removeLast()
    }
    
    func popAll() {
        return paths.removeAll()
    }
    
}
