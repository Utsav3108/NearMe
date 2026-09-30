//
//  GettingStartedVM.swift
//  MyApp
//
//  Created by Utsav Hitendrabhai Pandya on 30/09/26.
//


import Observation
import SwiftUI

struct User : Hashable {
    var name : String
    var img: ImageResource
    var preferences : [String]
    var address : String
    var coordinatesOfPlaces : [[Double]] = []
}

@Observable
class GettingStartedVM {
    
    var user : User!
    
    func getStarted(){
        user = createUser()
    }
    
    func navigateToSignIn(){
        user = createUser()
    }
    
    private func createUser() -> User {
        return User(name: "Utsav", img: .person, preferences: [], address: "Vastral, Ahmedabad")
    }
    
}
