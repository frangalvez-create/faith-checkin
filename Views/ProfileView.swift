import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @State private var showingSettings = false
    @State private var showingContact = false
    @State private var showingInfo = false
    @State private var showingFAQ = false
    @Binding var showSettingsFromPopup: Bool
    var openCenteredSelf: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Logo
            Image("Profile Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .padding(.top, 60) // 60pt from top of screen
            
            
            // User Email
            Text(journalViewModel.currentUser?.email ?? "user@example.com")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "545555"))
                .padding(.top, 30) // 30pt below profile logo
            
            // Interactive Menu Sections
            VStack(spacing: 0) {
                // What is Centered Self Section
                Button(action: {
                    openCenteredSelf?()
                }) {
                    HStack {
                        Image("WhatCS")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.leading, 10) // 10pt from left edge
                        
                        Text("What is Faith Check-in?")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt to the right of icon
                        
                        Spacer()
                        
                        Image("contact forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.trailing, 20) // 20pt from right edge
                    }
                    .padding(.vertical, 15)
                    .background(Color(hex: "F5F4EB"))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Settings Section
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image("setting")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.leading, 10) // 10pt from left edge
                        
                        Text("User Settings")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt to the right of icon
                        
                        Spacer()
                        
                        Image("setting forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.trailing, 20) // 20pt from right edge
                    }
                    .padding(.vertical, 15)
                    .background(Color(hex: "F5F4EB"))
                    .cornerRadius(8)
                }
                .padding(.top, 25) // 25pt below "What is Centered Self?" section
                .buttonStyle(PlainButtonStyle())
                
                // Contact Section
                Button(action: {
                    showingContact = true
                }) {
                    HStack {
                        Image("mail")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.leading, 10) // 10pt from left edge
                        
                        Text("Contact")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt to the right of icon
                        
                        Spacer()
                        
                        Image("contact forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.trailing, 20) // 20pt from right edge
                    }
                    .padding(.vertical, 15)
                    .background(Color(hex: "F5F4EB"))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 25) // 25pt below Settings section
                
                // Info Section
                Button(action: {
                    showingInfo = true
                }) {
                    HStack {
                        Image("info")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.leading, 10) // 10pt from left edge
                        
                        Text("Info")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt to the right of icon
                        
                        Spacer()
                        
                        Image("info forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.trailing, 20) // 20pt from right edge
                    }
                    .padding(.vertical, 15)
                    .background(Color(hex: "F5F4EB"))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 25) // 25pt below Contact section
                
                // FAQ Section
                Button(action: {
                    showingFAQ = true
                }) {
                    HStack {
                        Image("faq")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.leading, 10) // 10pt from left edge
                        
                        Text("FAQ")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt to the right of icon
                        
                        Spacer()
                        
                        Image("info forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.trailing, 20) // 20pt from right edge
                    }
                    .padding(.vertical, 15)
                    .background(Color(hex: "F5F4EB"))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 25) // 25pt below Info section
            }
            .padding(.top, 50) // 50pt below email
            .padding(.leading, 10) // 10pt more left padding
            .padding(.trailing, 10) // 10pt right padding to match left
            
            Spacer()
            
            // Version text - positioned above logout button, 20pt from right edge
            HStack {
                Spacer()
                        Text("v 2.0")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "545555"))
                    .opacity(0.7)
                    .padding(.trailing, 20) // 20pt from right edge
            }
            
            // Log Out Button (separate from menu container) - centered
            Button(action: {
                Task {
                    await journalViewModel.signOut()
                }
            }) {
                Text("Log Out")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "545555"))
            }
            .padding(.bottom, 40) // 40pt from bottom
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "E3E0C9"))
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(journalViewModel)
        }
        .sheet(isPresented: $showingContact) {
            ContactView()
        }
        .sheet(isPresented: $showingInfo) {
            InfoView()
        }
        .sheet(isPresented: $showingFAQ) {
            FAQView()
        }
        .onAppear {
            // Load journal entries and open question entries to calculate streak
            Task {
                await journalViewModel.loadJournalEntries()
                await journalViewModel.loadOpenQuestionJournalEntries()
            }
        }
        .onChange(of: showSettingsFromPopup) { newValue in
            if newValue {
                showingSettings = true
                showSettingsFromPopup = false // Reset the binding
            }
        }
    }
}


#Preview {
    ProfileView(showSettingsFromPopup: .constant(false))
        .environmentObject(JournalViewModel())
}
