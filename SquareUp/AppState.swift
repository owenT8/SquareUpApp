//
//  AppState.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/25/25.
//
import Foundation

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var showSplash: Bool = true
    @Published var currentScreenGroup: AppScreen = .splash
    
    @Published var errorMessage: String?
    @Published var showErrorToast: Bool = false
        
    @Published var successMessage: String?
    @Published var showSuccessToast: Bool = false
}
