//
//  PlaceDetailsVM.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 04/10/26.
//


import Observation
import Foundation

@Observable
@MainActor
class PlaceDetailsVM {
    
    var placeDetail : PlaceDDetail? = nil
    
    private let placeProvider: any PlacesRepository
    
    init(placeProvider: any PlacesRepository) {
        self.placeProvider = placeProvider
    }
    
    func loadPlace(id: String) async {
        do {
            placeDetail = try await placeProvider.getPlaceDetails(id: id)
        } catch {
            
        }
    }
    
    
}
