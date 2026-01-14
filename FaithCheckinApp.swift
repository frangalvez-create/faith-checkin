//
//  FaithCheckinApp.swift
//  FaithCheckin
//
//  Created by Family Galvez on 8/31/25.
//

import SwiftUI

@main
struct FaithCheckinApp: App {
    @StateObject private var journalViewModel = JournalViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(journalViewModel)
                .onAppear {
                    // Check for existing authentication session on app startup
                    Task {
                        await journalViewModel.checkAuthenticationStatus()
                    }
                }
        }
    }
}
