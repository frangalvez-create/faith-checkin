//
//  ContentView.swift
//  Centered
//
//  Created by Family Galvez on 8/31/25.
//

import SwiftUI
import UIKit

// Helper view to safely load images that may not exist in asset catalog
struct SafeImage: View {
    let name: String
    let height: CGFloat?
    let width: CGFloat?
    
    init(_ name: String, height: CGFloat? = nil, width: CGFloat? = nil) {
        self.name = name
        self.height = height
        self.width = width
    }
    
    var body: some View {
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
        } else {
            // Return empty view if image doesn't exist
            Color.clear
                .frame(width: width, height: height)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @State private var journalResponse: String = ""
    @State private var textEditorHeight: CGFloat = 150
    @State private var showCenteredButton: Bool = false
    @State private var isTextLocked: Bool = false
    @State private var showTextEditDropdown: Bool = false
    @State private var showCenteredButtonClick: Bool = false
    @State private var currentAIResponse: String = ""
    @State private var showFavoriteButton: Bool = false
    @State private var isFavoriteClicked: Bool = false
    @State private var isGeneratingAI: Bool = false
    @State private var isLoadingGenerating: Bool = false // Track if we're generating AI vs saving
    
    // OPEN QUESTION SECTION STATE (Duplicate all state variables)
    @State private var openJournalResponse: String = ""
    @State private var openTextEditorHeight: CGFloat = 150
    @State private var openShowCenteredButton: Bool = false
    @State private var openIsTextLocked: Bool = false
    @State private var openShowTextEditDropdown: Bool = false
    @State private var openShowCenteredButtonClick: Bool = false
    @State private var openCurrentAIResponse: String = ""
    @State private var openShowFavoriteButton: Bool = false
    @State private var openIsFavoriteClicked: Bool = false
    @State private var openIsGeneratingAI: Bool = false
    @State private var openIsLoadingGenerating: Bool = false // Track if we're generating AI vs saving
    
    // Follow-Up Question State
    @State private var followUpJournalResponse: String = ""
    @State private var followUpIsTextLocked: Bool = false
    @State private var followUpShowCenteredButton: Bool = false
    @State private var followUpShowCenteredButtonClick: Bool = false
    @State private var followUpCurrentAIResponse: String = ""
    @State private var followUpShowFavoriteButton: Bool = false
    @State private var followUpIsFavoriteClicked: Bool = false
    @State private var followUpIsGeneratingAI: Bool = false
    @State private var followUpIsLoadingGenerating: Bool = false
    @State private var followUpTextEditorHeight: CGFloat = 150
    @State private var followUpShowTextEditDropdown: Bool = false
    @State private var isFollowUpQuestionDay: Bool = false
    
    // Navigation Tab Selection
    @State private var selectedTab: Int = 0
    
    // Centered Page Goal Text
    @State private var goalText: String = ""
    @State private var isGoalLocked: Bool = false
    @State private var showCPRefreshButton: Bool = false
    @State private var goalTextHeight: CGFloat = 40
    
    // Favorites Page State
    @State private var expandedEntries: Set<UUID> = []
    
    // Info Popup State
    @State private var showInfoPopup: Bool = false
    @State private var showGoalInfoPopup: Bool = false
    
    // Profile Settings Navigation
    @State private var showSettingsFromPopup: Bool = false
    
    // Q3 Popup for Guided Questions
    @State private var showQ3InfoPopup: Bool = false
    
    // Q4 Popup for Analyzer
    @State private var showQ4InfoPopup: Bool = false
    
    // Authentication State
    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var showOTPInput: Bool = false
    @State private var otpSent: Bool = false
    
    // Welcome Message State
    @State private var showWelcomeMessage: Bool = false
    
    // Loading View State
    @State private var showLoadingView: Bool = false
    
    // Analyzer
    @StateObject private var analyzerViewModel = AnalyzerViewModel()
    @State private var showCenteredSelfSheet: Bool = false
    
    private let analyzerMoodColors: [Color] = [
        Color(hex: "583F82"),
        Color(hex: "3F8259"),
        Color(hex: "823F47"),
        Color(hex: "82713F"),
        Color(hex: "3F5982")
    ]
    
    var body: some View {
        rootContent
        .onAppear {
            Task {
                await journalViewModel.checkAuthenticationStatus()
                // Ensure Journal tab is selected after authentication
                selectedTab = 0
                
                // Don't load data here - wait for authentication to complete,
                // then LoadingView will appear, then Journal view's onAppear will load data
            }
        }
        .onChange(of: journalViewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                // When user becomes authenticated, show Loading View first
                showLoadingView = true
                selectedTab = 0
                
                // Check if this is a first-time user (will show after Loading View)
                checkAndShowWelcomeMessage()
            }
        }
        .onChange(of: journalViewModel.analyzerEntries) { oldValue, newValue in
            recalculateAnalyzerState()
        }
        .onChange(of: journalViewModel.journalEntries.map { $0.id }) { oldValue, newValue in
            recalculateAnalyzerState()
        }
        .onChange(of: journalViewModel.openQuestionJournalEntries.map { $0.id }) { oldValue, newValue in
            recalculateAnalyzerState()
        }
        .onChange(of: journalViewModel.followUpQuestionEntries.map { $0.id }) { oldValue, newValue in
            recalculateAnalyzerState()
        }
        .alert("Oh No!", isPresented: .constant(journalViewModel.errorMessage != nil)) {
            Button("OK") {
                journalViewModel.errorMessage = nil
            }
        } message: {
            Text(journalViewModel.errorMessage ?? "")
        }
    }
    
    private var rootContent: some View {
        Group {
            if journalViewModel.isAuthenticated {
                // Show Loading View if requested, otherwise show main content
                if showLoadingView {
                    loadingView
                } else {
                VStack(spacing: 0) {
                    // Main Content Area
                    Group {
                        switch selectedTab {
                        case 0:
                            mainJournalView
                        case 1:
                            favoritesPageView
                        case 2:
                                analyzerPageView
                        case 3:
                                ProfileView(
                                    showSettingsFromPopup: $showSettingsFromPopup,
                                    openCenteredSelf: { showCenteredSelfSheet = true }
                                )
                        default:
                            mainJournalView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Custom Tab Bar
                    customTabBar
                }
                .background(Color(hex: "E3E0C9"))
                .ignoresSafeArea(.all)
                .overlay(
                    // Info Popup
                    Group {
                        if showInfoPopup {
                            infoPopupView
                        }
                        if showGoalInfoPopup {
                            goalInfoPopupView
                        }
                            if showQ3InfoPopup {
                                q3InfoPopupView
                            }
                            if showQ4InfoPopup {
                                q4InfoPopupView
                        }
                    }
                )
                .overlay(
                    // Welcome Message Modal
                    Group {
                        if showWelcomeMessage {
                            welcomeMessageView
                        }
                    }
                )
                    .sheet(isPresented: $showCenteredSelfSheet) {
                        centeredPageView
                            .environmentObject(journalViewModel)
                    }
                }
            } else {
                authenticationView
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            
            Image("Fav Logo")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            
            Text("Updating Daily Questions…")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "772C2C"))
                .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "E3E0C9"))
        .ignoresSafeArea(.all)
        .allowsHitTesting(true) // Block all interactions
        .onAppear {
            // Auto-switch back to Journal View after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    showLoadingView = false
                    // Ensure Journal tab is selected
                selectedTab = 0
            }
        }
        }
    }
    
    private var mainJournalView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
            // Date and Streak - positioned at top, scrolls with content
            HStack {
                Text(formatCurrentDate())
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "545555").opacity(1.0))
                    .padding(.top, 45)
                    .padding(.leading, 38)
                
                Spacer()
                
                Text("Streak: \(journalViewModel.calculateEntryStreak())")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "545555").opacity(1.0))
                    .padding(.top, 45)
                    .padding(.trailing, 30)
            }
            
            // Top Logo (CS Logo.png)
            SafeImage("CS Logo", height: 80)
                .padding(.top, -2)
            
            // Daily Journal Title (DJ.png) - Reduced to 2/3 size
            Image("DJ")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .padding(.top, 4)
                .padding(.bottom, 25)
            
            // Q Info Icon - positioned higher and to the right of DJ.png
            
            // Guided Question Text with Refresh Button - Loaded from Database
            HStack(spacing: 8) {
                if let currentQuestion = journalViewModel.currentQuestion {
                    Text(currentQuestion.questionText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textBlue)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else if journalViewModel.isLoading {
                    Text("Loading today's question...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textBlue.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else {
                    Text("What thing, person or moment filled you with gratitude today?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textBlue)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Guided Question Refresh Button (HIDDEN - Logic preserved for 2AM auto-click)
                // Button(action: {
                //     guidedRefreshButtonTapped()
                // }) {
                //     Image("guide_refresh")
                //         .resizable()
                //         .frame(width: 22, height: 22)
                // }
                // .disabled(journalViewModel.isLoading)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 10)
            
            // Text Input Field with Done Button - Dynamic height with proper sizing
            VStack {
                ZStack(alignment: .topLeading) {
                    // Background for the text editor
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.textFieldBackground)
                        .frame(height: (isTextLocked && !currentAIResponse.isEmpty) ? 400 : max(150, min(300, textEditorHeight)))
                    
                    // Q3 Icon inside text field - only show when no text is entered
                    if journalResponse.isEmpty {
                        VStack {
                            HStack {
                                Spacer()
                                    Button(action: {
                                        showQ3InfoPopup = true
                                    }) {
                                        Image("Q")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 27, height: 27)
                                            .opacity(0.7)
                                    }
                                .padding(.trailing, 4) // 4pt from right edge
                            }
                            Spacer()
                        }
                        .padding(.top, 4) // 4pt from top edge
                    }
                    
                    // Text Editor and AI Response Display
                    if isTextLocked && !currentAIResponse.isEmpty {
                        // Show both journal text and AI response when locked and response is available
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Journal text
                                    Text(journalResponse)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.textGrey)
                                        .multilineTextAlignment(.leading)
                                        .id("journalTextStart") // Identifier for scrolling to top
                                    
                                    // AI Response
                                    Text(currentAIResponse)
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(hex: "772C2C")) // Maroon #772C2C
                                        .multilineTextAlignment(.leading)
                                        .padding(.leading, 12) // Indent 3 characters to the right
                                        .id("aiResponseEnd") // Identifier for scroll detection
                                }
                                .padding(.top, 5)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                                .padding(.bottom, 40) // Reduced bottom padding
                            }
                            .background(Color.clear)
                            .onAppear {
                                // Scroll to TOP when AI response appears (not bottom)
                                withAnimation {
                                    proxy.scrollTo("journalTextStart", anchor: .top)
                                }
                                // Show favorite button after a delay to ensure scroll is complete
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showFavoriteButton = true
                                }
                            }
                        }
                        .frame(height: 400) // Always use max height when showing AI response
                        .clipped() // Ensure content doesn't extend beyond container
                        .overlay(
                            // Bottom fade mask to prevent text overlap with favorite button
                            VStack {
                                Spacer()
                                // Gradient mask with proper rounded bottom corners
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.clear, location: 0.0),
                                        .init(color: Color.textFieldBackground, location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 55) // Increased to 55pt
                                .clipShape(
                                    // Custom shape that matches the bottom rounded corners of the text field
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 0,
                                        bottomLeadingRadius: 20,
                                        bottomTrailingRadius: 20,
                                        topTrailingRadius: 0
                                    )
                                )
                            }
                        )
                    } else {
                        // Normal TextEditor when not locked or no AI response
                        TextEditor(text: $journalResponse)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textGrey)
                            .padding(.top, 5)
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                            .padding(.bottom, 30) // Extra bottom padding to avoid Done button
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                            .frame(height: max(150, min(300, textEditorHeight)))
                            .disabled(isTextLocked) // Lock text when Done is pressed
                            .overlay(
                                // Bottom fade mask to prevent text overlap with Done button
                                // Only show when AI response is not yet generated (before Centered button click)
                                Group {
                                    if !isTextLocked && currentAIResponse.isEmpty {
                                        VStack {
                                            Spacer()
                                            // Gradient mask with proper rounded bottom corners
                                            LinearGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: Color.clear, location: 0.0),
                                                    .init(color: Color.textFieldBackground, location: 1.0)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            .frame(height: 55) // 55pt height
                                            .clipShape(
                                                // Custom shape that matches the bottom rounded corners of the text field
                                                UnevenRoundedRectangle(
                                                    topLeadingRadius: 0,
                                                    bottomLeadingRadius: 20,
                                                    bottomTrailingRadius: 20,
                                                    topTrailingRadius: 0
                                                )
                                            )
                                        }
                                    }
                                }
                            )
                            .onChange(of: journalResponse) { oldValue, newValue in
                                updateTextEditorHeight()
                            }
                    }
                    
                    // Text Edit Button Centered (only show when text is locked but no AI response)
                    if isTextLocked && currentAIResponse.isEmpty {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                VStack {
                                    Button(action: {
                                        showTextEditDropdown.toggle()
                                    }) {
                                        Image("Text Edit Button")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                    }
                                    .frame(width: 44, height: 44)
                                    
                                    // Dropdown Menu
                                    if showTextEditDropdown {
                                        VStack(spacing: 0) {
                                            Button("Edit Log") {
                                                editLogSelected()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color.textFieldBackground)
                                            .foregroundColor(Color.textBlue)
                                            .font(.system(size: 14, weight: .medium))
                                            
                                            Divider()
                                                .background(Color.textBlue.opacity(0.3))
                                            
                                            Button("Delete Log") {
                                                deleteLogSelected()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color.textFieldBackground)
                                            .foregroundColor(Color.textBlue)
                                            .font(.system(size: 14, weight: .medium))
                                        }
                                        .background(Color.textFieldBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.textBlue.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(radius: 3)
                                        .offset(y: -10)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.bottom, 5) // 5pt from bottom edge
                        }
                        .frame(height: max(150, min(300, textEditorHeight)))
                    }
                    
                    // Done/Centered Button - Bottom Right (hidden when AI response is present or text is empty)
                    if currentAIResponse.isEmpty && !journalResponse.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    if showCenteredButton && !isGeneratingAI {
                                        centeredButtonTapped()
                                    } else if !isGeneratingAI {
                                        doneButtonTapped()
                                    }
                                }) {
                                    if isGeneratingAI {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "772C2C")))
                                            .frame(width: 37, height: 37)
                                    } else {
                                    Image(getButtonImageName())
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: showCenteredButton ? 37 : 24, height: showCenteredButton ? 37 : 24)
                                            .opacity(showCenteredButton ? 0.9 : 0.8)
                                            .scaleEffect(showCenteredButton ? 1.4 : 1.0)
                                        }
                                }
                                .frame(width: 44, height: 44) // Keep 44x44 touch target
                                .padding(.trailing, showCenteredButton ? 15 : 5)
                                .padding(.bottom, 5)
                            }
                        }
                    }
                    
                    // Favorite Button (only when AI response is present and scrolled to bottom)
                    if !currentAIResponse.isEmpty && showFavoriteButton {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    favoriteButtonTapped()
                                }) {
                                    Image(isFavoriteClicked ? "Fav Button Click" : "Fav Button")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                }
                                .frame(width: 44, height: 44) // Keep 44x44 touch target
                                .padding(.trailing, 5)
                                .padding(.bottom, 0) // Reduced from 5pt to 0pt to position closer to bottom edge
                            }
                        }
                    }
                }
                .frame(height: (isTextLocked && !currentAIResponse.isEmpty) ? 400 : max(150, min(300, textEditorHeight)))
            }
            .padding(.horizontal, 40)
            
            // OPEN QUESTION SECTION (25pt spacing below Guided Question)
            VStack(spacing: 0) {
                // Dynamic Question Text - Follow-Up or Open Question
                HStack(spacing: 8) {
                    if isFollowUpQuestionDay && !journalViewModel.currentFollowUpQuestion.isEmpty {
                        // Follow-Up Question (color #5F4083) - Show once loaded
                        Text(journalViewModel.currentFollowUpQuestion)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "5F4083"))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if isFollowUpQuestionDay && journalViewModel.isLoadingFollowUpQuestion {
                        // Show loading message while fetching pre-generated question
                        Text("Loading follow up question...")
                            .font(.system(size: 16, weight: .medium))
                            .italic()
                            .foregroundColor(Color(hex: "5F4083"))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if isFollowUpQuestionDay && journalViewModel.currentFollowUpQuestion.isEmpty {
                        // If it's a follow-up day but no eligible past entry found, show static open question
                        Text("Looking at today or yesterday, share moments, thoughts, or prayers that stood out?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textBlue)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        // Regular Open Question
                        Text("Looking at today or yesterday, share moments, thoughts, or prayers that stood out.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.textBlue)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Open Question Refresh Button (HIDDEN - Logic preserved for 2AM auto-click)
                    // Button(action: {
                    //     openRefreshButtonTapped()
                    // }) {
                    //     Image("open_refresh")
                    //         .resizable()
                    //         .frame(width: 22, height: 22)
                    // }
                    // .disabled(journalViewModel.isLoading)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                .padding(.top, 25) // 25pt spacing below Guided Question
                
                // Open Question Text Input Field with Done Button - Dynamic height with proper sizing
                VStack {
                    ZStack(alignment: .topLeading) {
                        // Background for the text editor
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.textFieldBackground)
                            .frame(height: ((isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && !(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty) ? 400 : max(150, min(300, isFollowUpQuestionDay ? followUpTextEditorHeight : openTextEditorHeight)))
                        
                        // Q Icon inside text field - only show when no text is entered
                        if (isFollowUpQuestionDay ? followUpJournalResponse : openJournalResponse).isEmpty {
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showInfoPopup = true
                                    }) {
                                        Image("Q")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 27, height: 27)
                                            .opacity(0.7)
                                    }
                                    .padding(.trailing, 4) // 4pt from right edge
                                }
                                Spacer()
                            }
                            .padding(.top, 4) // 4pt from top edge
                        }
                        
                        // Text Editor and AI Response Display
                        if (isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && !(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty {
                            // Show both journal text and AI response when locked and response is available
                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Journal text
                                        Text(isFollowUpQuestionDay ? followUpJournalResponse : openJournalResponse)
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.textGrey)
                                            .multilineTextAlignment(.leading)
                                            .id("openJournalTextStart") // Identifier for scrolling to top
                                        
                                        // AI Response
                                        Text(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse)
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: "772C2C")) // Maroon #772C2C
                                            .multilineTextAlignment(.leading)
                                            .padding(.leading, 12) // Indent 3 characters to the right
                                            .id("openAIResponseEnd") // Identifier for scroll detection
                                    }
                                    .padding(.top, 5)
                                    .padding(.leading, 15)
                                    .padding(.trailing, 15)
                                    .padding(.bottom, 40) // Reduced bottom padding
                                }
                                .background(Color.clear)
                                .onAppear {
                                    // Scroll to TOP when AI response appears (not bottom)
                                    withAnimation {
                                        proxy.scrollTo("openJournalTextStart", anchor: .top)
                                    }
                                    // Show favorite button after a delay to ensure scroll is complete
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        if isFollowUpQuestionDay {
                                            followUpShowFavoriteButton = true
                                        } else {
                                        openShowFavoriteButton = true
                                        }
                                    }
                                }
                            }
                            .frame(height: 400) // Always use max height when showing AI response
                            .clipped() // Ensure content doesn't extend beyond container
                            .overlay(
                                // Bottom fade mask to prevent text overlap with favorite button
                                VStack {
                                    Spacer()
                                    // Gradient mask with proper rounded bottom corners
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.clear, location: 0.0),
                                            .init(color: Color.textFieldBackground, location: 1.0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 55) // Same 55pt height as Guided Question
                                    .clipShape(
                                        // Custom shape that matches the bottom rounded corners of the text field
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 0,
                                            bottomLeadingRadius: 20,
                                            bottomTrailingRadius: 20,
                                            topTrailingRadius: 0
                                        )
                                    )
                                }
                            )
                        } else {
                            // Normal TextEditor when not locked or no AI response
                            TextEditor(text: isFollowUpQuestionDay ? $followUpJournalResponse : $openJournalResponse)
                                .font(.system(size: 16))
                                .foregroundColor(Color.textGrey)
                                .padding(.top, 5)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                                .padding(.bottom, 30) // Extra bottom padding to avoid Done button
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .frame(height: max(150, min(300, isFollowUpQuestionDay ? followUpTextEditorHeight : openTextEditorHeight)))
                                .disabled(isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) // Lock text when Done is pressed
                                .overlay(
                                    // Bottom fade mask to prevent text overlap with Done button
                                    // Only show when AI response is not yet generated (before Centered button click)
                                    Group {
                                        if !(isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && (isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty {
                                            VStack {
                                                Spacer()
                                                // Gradient mask with proper rounded bottom corners
                                                LinearGradient(
                                                    gradient: Gradient(stops: [
                                                        .init(color: Color.clear, location: 0.0),
                                                        .init(color: Color.textFieldBackground, location: 1.0)
                                                    ]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                                .frame(height: 55) // 55pt height
                                                .clipShape(
                                                    // Custom shape that matches the bottom rounded corners of the text field
                                                    UnevenRoundedRectangle(
                                                        topLeadingRadius: 0,
                                                        bottomLeadingRadius: 20,
                                                        bottomTrailingRadius: 20,
                                                        topTrailingRadius: 0
                                                    )
                                                )
                                            }
                                        }
                                    }
                                )
                                .onChange(of: isFollowUpQuestionDay ? followUpJournalResponse : openJournalResponse) { oldValue, newValue in
                                    if isFollowUpQuestionDay {
                                        updateFollowUpTextEditorHeight()
                                    } else {
                                    updateOpenTextEditorHeight()
                                    }
                                }
                        }
                        
                        // Text Edit Button Centered (only show when text is locked but no AI response)
                        if (isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && (isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty {
                            VStack {
                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    
                                    VStack {
                                        Button(action: {
                                            openShowTextEditDropdown.toggle()
                                        }) {
                                            Image("Text Edit Button")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 28, height: 28)
                                        }
                                        .frame(width: 44, height: 44)
                                        
                                        // Dropdown Menu
                                        if openShowTextEditDropdown {
                                            VStack(spacing: 0) {
                                                Button("Edit Log") {
                                                    openEditLogSelected()
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(Color.textFieldBackground)
                                                .foregroundColor(Color.textBlue)
                                                .font(.system(size: 14, weight: .medium))
                                                
                                                Divider()
                                                    .background(Color.textBlue.opacity(0.3))
                                                
                                                Button("Delete Log") {
                                                    openDeleteLogSelected()
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(Color.textFieldBackground)
                                                .foregroundColor(Color.textBlue)
                                                .font(.system(size: 14, weight: .medium))
                                            }
                                            .background(Color.textFieldBackground)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.textBlue.opacity(0.3), lineWidth: 1)
                                            )
                                            .shadow(radius: 3)
                                            .offset(y: -10)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.bottom, 5) // 5pt from bottom edge
                            }
                            .frame(height: max(150, min(300, openTextEditorHeight)))
                        }
                        
                        // Done/Centered Button - Bottom Right (hidden when AI response is present or text is empty)
                        if (isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty && !(isFollowUpQuestionDay ? followUpJournalResponse : openJournalResponse).isEmpty {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if isFollowUpQuestionDay {
                                            // Follow-up question button actions
                                            if followUpShowCenteredButton && !followUpIsGeneratingAI {
                                                followUpCenteredButtonTapped()
                                            } else if !followUpIsGeneratingAI {
                                                followUpDoneButtonTapped()
                                            }
                                        } else {
                                            // Open question button actions
                                            if openShowCenteredButton && !openIsGeneratingAI {
                                                openCenteredButtonTapped()
                                            } else if !openIsGeneratingAI {
                                            openDoneButtonTapped()
                                        }
                                        }
                                    }) {
                                        if (isFollowUpQuestionDay ? followUpIsGeneratingAI : openIsGeneratingAI) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "772C2C")))
                                                .frame(width: 37, height: 37)
                                        } else {
                                            let buttonImageName = isFollowUpQuestionDay ? getFollowUpButtonImageName() : getOpenButtonImageName()
                                            let showCenteredButton = isFollowUpQuestionDay ? followUpShowCenteredButton : openShowCenteredButton
                                            
                                            Image(buttonImageName)
                                            .resizable()
                                            .scaledToFit()
                                                .frame(width: showCenteredButton ? 37 : 24, height: showCenteredButton ? 37 : 24)
                                                .opacity(showCenteredButton ? 0.9 : 0.8)
                                                .scaleEffect(showCenteredButton ? 1.4 : 1.0)
                                        }
                                    }
                                    .frame(width: 44, height: 44) // Keep 44x44 touch target
                                    .padding(.trailing, (isFollowUpQuestionDay ? followUpShowCenteredButton : openShowCenteredButton) ? 15 : 5)
                                    .padding(.bottom, 5)
                                }
                            }
                        }
                        
                        // Favorite Button (only when AI response is present and scrolled to bottom)
                        if !(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty && (isFollowUpQuestionDay ? followUpShowFavoriteButton : openShowFavoriteButton) {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if isFollowUpQuestionDay {
                                            followUpFavoriteButtonTapped()
                                        } else {
                                        openFavoriteButtonTapped()
                                        }
                                    }) {
                                        let isFavoriteClicked = isFollowUpQuestionDay ? followUpIsFavoriteClicked : openIsFavoriteClicked
                                        Image(isFavoriteClicked ? "Fav Button Click" : "Fav Button")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                    }
                                    .frame(width: 44, height: 44) // Keep 44x44 touch target
                                    .padding(.trailing, 5)
                                    .padding(.bottom, 0) // Reduced from 5pt to 0pt to position closer to bottom edge
                                }
                            }
                        }
                    }
                    .frame(height: ((isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && !(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty) ? 400 : max(150, min(300, isFollowUpQuestionDay ? followUpTextEditorHeight : openTextEditorHeight)))
            }
            .padding(.horizontal, 40)
            
            // Embossed gray line - 20pt below open question text box
            ZStack {
                // Shadow line (darker)
                Rectangle()
                    .fill(Color(hex: "545555"))
                    .opacity(0.225) // 75% of 0.3
                    .frame(height: 1)
                    .offset(y: 1)
                
                // Main line (lighter)
                Rectangle()
                    .fill(Color(hex: "545555"))
                    .opacity(0.075) // 75% of 0.1
                    .frame(height: 1)
            }
            .padding(.top, 25) // 25pt below open question text box
            .padding(.horizontal, 40)
            
            // Goal section - 16pt below embossed line
            VStack(spacing: 4) {
                Text("My Goal is to be…")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "545555"))
                
                // Goal text field with button overlay
                ZStack(alignment: .trailing) {
                    ZStack {
                        // Custom TextEditor with dynamic height and centered text
                        TextEditor(text: $goalText)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "545555"))
                        .multilineTextAlignment(.center) // Center the text
                        .padding(.leading, 15)
                        .padding(.trailing, (isGoalLocked || goalText.isEmpty) ? 15 : 50) // Center when locked or empty, make room for button when unlocked and has text
                        .padding(.top, 0)
                        .padding(.bottom, 6)
                        .background(Color(hex: "F5F4EB"))
                        .cornerRadius(8)
                        .disabled(isGoalLocked) // Disable editing when locked
                        .frame(height: max(40, goalTextHeight)) // Dynamic height starting at 40pt
                        .scrollContentBackground(.hidden)
                        .onChange(of: goalText) { oldValue, newValue in
                            updateGoalTextHeight()
                            // Character limit for multiline
                            if goalText.count > 50 {
                                goalText = String(goalText.prefix(50))
                            }
                        }
                        
                        // Custom placeholder text with smaller font
                        if goalText.isEmpty {
                            Text("ex. More patient, more kind, less boastful")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "545555").opacity(0.6))
                                .multilineTextAlignment(.center)
                                .allowsHitTesting(false) // Allow taps to go through to TextEditor
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                                .padding(.top, 6)
                                .padding(.bottom, 6)
                        }
                    }
                    
                    // CP Done/Refresh Button positioned at the right edge (only show when text is entered)
                    if !goalText.isEmpty {
                        Button(action: {
                        if showCPRefreshButton {
                            // CP Refresh button clicked - reset
                            cpRefreshButtonTapped()
                        } else {
                            // CP Done button clicked - lock in
                            cpDoneButtonTapped()
                        }
                    }) {
                        Image(showCPRefreshButton ? "CP Refresh" : "CP Done")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .opacity(showCPRefreshButton ? 0.6 : 0.8) // 60% opacity for CP Refresh, 80% for CP Done
                    }
                    .padding(.trailing, 5) // 5pt from right edge
                    }
                }
                .padding(.horizontal, 40) // Centered with more padding
            }
            .padding(.top, 16) // 16pt below embossed line
            .overlay(
                // Q2 Icon as overlay - positioned to the right of "My Goal is to be..." text
                Button(action: {
                    showGoalInfoPopup = true
                }) {
                    Image("Q2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27, height: 27)
                }
                .offset(x: 330, y: 10), // 330pt to the right, 10pt down
                alignment: .topLeading
            )
        }
        
        // Emergency Support Reminder - 175pt below Goal text field
        VStack(spacing: 8) {
            Text("Emergency Support Reminder")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "545555"))
                .opacity(0.8)
                .multilineTextAlignment(.center)
            
            Text("If you are experiencing a crisis or thinking about harming yourself, do not rely on this App. Call 988 in the U.S. or your local emergency number.")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "545555"))
                .opacity(0.8)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 175)
        
        // Add bottom padding for future navigation tabs
        Spacer(minLength: 5) // Extra space at bottom for navigation tabs
            }
            .padding(.bottom, 50) // Additional padding for navigation tabs
            }
            .background(Color.backgroundBeige)
            .ignoresSafeArea(.all, edges: .top)
        }
        .overlay(
            // Loading indicator
            Group {
                if journalViewModel.isLoading {
                    ZStack {
                        Color(hex: "4E4C4C").opacity(0.5)
                            .ignoresSafeArea()
                        
        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(getLoadingText())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "F5F4EB"))
                                .padding(.top, 10)
                        }
                        .padding(20)
                        .background(Color(hex: "772C2C"))
                        .cornerRadius(10)
                    }
                }
            }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Dismiss keyboard when tapping outside text fields
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
        .refreshable {
            // Pull to refresh gesture - immediately switch to Loading View
            await MainActor.run {
                showLoadingView = true
            }
        }
        .onAppear {
            Task {
                await reloadJournalDataSequence(suppressErrors: false)
            }
            
            // Set up the callbacks for UI state management
            journalViewModel.clearUIStateCallback = {
                print("🧹 Direct callback triggered - clearing UI state")
                clearAllUIState()
            }
            
            journalViewModel.populateUIStateCallback = {
                print("🔄 Direct callback triggered - populating UI state")
                populateUIStateFromJournalEntries()
            }
        }
        .onChange(of: journalViewModel.shouldClearUIState) { oldValue, newValue in
            print("🔄 onChange triggered - shouldClear: \(newValue)")
            if newValue {
                print("🧹 Clearing UI state due to user sign out")
                clearAllUIState()
                // Reset the trigger
                journalViewModel.shouldClearUIState = false
                print("🧹 UI state cleared and trigger reset")
            }
        }
        .onDisappear {
            // Global timer handles 2AM reset - no cleanup needed here
            print("🕐 View disappeared - global timer continues running")
        }
    }
    
    // Format current date as "Sept 24th" format
    private func formatCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        
        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        
        let monthDay = formatter.string(from: Date())
        let ordinalDay = ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        
        return monthDay.replacingOccurrences(of: "\(day)", with: ordinalDay)
    }
    
    private var authenticationView: some View {
        VStack(spacing: 20) {
            // Centered Logo - moved to 100pt from top
            SafeImage("CS Logo", height: 120)
                .padding(.top, 100)
            
            // Welcome to text - 22pt regular, Maroon #772C2C
            Text("Welcome to")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "772C2C"))
            
            // CenteredApp Logo - 5pt below Welcome to
            SafeImage("CenteredApp Logo", height: 60)
                .padding(.top, 5)
            
            VStack(spacing: 15) {
                if !showOTPInput {
                    // Email Input Screen
                    VStack(spacing: 15) {
                        // Instruction text - only show on email screen
                        Text("Enter your email to get started")
                            .font(.body)
                            .foregroundColor(Color(hex: "772C2C"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Email TextField with fixed background color
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(hex: "F5F4EB"))
                            .cornerRadius(12)
                            .foregroundColor(.black)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            Task {
                                await journalViewModel.sendOTP(email: email)
                                if journalViewModel.errorMessage == nil {
                                    showOTPInput = true
                                    otpSent = true
                                }
                            }
                        }) {
                            Text("Send One Time Passcode")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "772C2C"))
                                .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || journalViewModel.isLoading)
                        .padding(.horizontal, 40)
                    }
                } else {
                    // OTP Code Input Screen
                    VStack(spacing: 15) {
                        // Check your email text - 5pt below logo (adjusted spacing)
                        Text("Check your email for the OTP code")
                            .font(.body)
                            .foregroundColor(Color(hex: "772C2C"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 5) // 5pt padding as requested
                        
                        // OTP TextField with fixed background color
                        TextField("Enter OTP code", text: $otpCode)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.vertical, 12) // Reduced height (3/4 of current size)
                            .background(Color(hex: "F5F4EB"))
                            .cornerRadius(12)
                            .foregroundColor(.black)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 20, weight: .medium))
                            .padding(.horizontal, 40)
                            .padding(.top, 5) // 5pt padding as requested
                        
                        HStack(spacing: 15) {
                        Button(action: {
                            showOTPInput = false
                            otpSent = false
                        }) {
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "772C2C"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "772C2C"), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            Task {
                                await journalViewModel.verifyOTP(email: email, token: otpCode)
                            }
                        }) {
                            Text("Verify")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "772C2C"))
                                .cornerRadius(8)
                        }
                            .disabled(otpCode.isEmpty || journalViewModel.isLoading)
                        }
                        .padding(.horizontal, 40)
                        
                        Button(action: {
                            // Resend OTP Code
                            Task {
                                await journalViewModel.sendOTP(email: email)
                            }
                        }) {
                        Text("Resend Code")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "772C2C").opacity(0.7))
                        }
                        .disabled(journalViewModel.isLoading)
                    }
                }
            }
            
            Spacer()
        }
        .background(Color.backgroundBeige)
        .ignoresSafeArea(.all)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func updateTextEditorHeight() {
        // If we have AI response, always use max height for scrolling
        if isTextLocked && !currentAIResponse.isEmpty {
            textEditorHeight = 250
            return
        }
        
        // Return early if text is empty to avoid NaN calculations
        guard !journalResponse.isEmpty else {
            textEditorHeight = 150
            return
        }
        
        let font = UIFont.systemFont(ofSize: 16)
        // Use a reasonable default width instead of UIScreen.main
        let maxWidth: CGFloat = 300 // Account for padding
        
        // Ensure maxWidth is valid
        guard maxWidth > 0 else {
            textEditorHeight = 150
            return
        }
        
        let boundingRect = journalResponse.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Validate the calculated height to prevent NaN
        let calculatedHeight = boundingRect.height + 60 // Extra padding for comfort
        let validatedHeight = calculatedHeight.isNaN || calculatedHeight.isInfinite ? 150 : calculatedHeight
        
        textEditorHeight = max(150, min(250, validatedHeight))
    }
    
    private func getButtonImageName() -> String {
        if showCenteredButtonClick {
            return "Centered Button Click"
        } else if showCenteredButton {
            return "Centered Button"
        } else {
            return "Done Button"
        }
    }
    
    private func doneButtonTapped() {
        print("🚨🚨🚨 DONE BUTTON TAPPED - METHOD CALLED!")
        print("🚨🚨🚨 DONE BUTTON TAPPED - METHOD CALLED!")
        print("🚨🚨🚨 DONE BUTTON TAPPED - METHOD CALLED!")
        print("🔘🔘🔘 DONE BUTTON TAPPED - Content: \(journalResponse)")
        print("🔘🔘🔘 DONE BUTTON TAPPED - Content: \(journalResponse)")
        print("🔘🔘🔘 DONE BUTTON TAPPED - Content: \(journalResponse)")
        
        // Change to Centered Button and lock text (no animation on Done button)
        showCenteredButton = true
        isTextLocked = true
        isLoadingGenerating = false // This is saving, not generating
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save journal entry to Supabase
        Task {
            print("📝📝📝 Calling journalViewModel.createJournalEntry with content: \(journalResponse)")
            await journalViewModel.createJournalEntry(content: journalResponse)
        }
        
        print("Done button tapped - Journal entry saved to Supabase: \(journalResponse)")
        print("Text locked and button changed to Centered Button")
    }
    
    private func centeredButtonTapped() {
        // Prevent multiple clicks during AI generation
        guard !isGeneratingAI else { 
            print("⚠️ AI generation already in progress, ignoring click")
            return 
        }
        
        // Change to Centered Button Click state
        showCenteredButtonClick = true
        isGeneratingAI = true
        isLoadingGenerating = true // This is generating AI, not saving
        
        // Reset retry attempt to 1 for new generation
        journalViewModel.currentRetryAttempt = 1
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate AI prompt and update journal entry
        Task {
            do {
                try await generateAndSaveAIPrompt()
                // Reset loading state on success
                await MainActor.run {
                    self.isGeneratingAI = false
                    self.isLoadingGenerating = false
                }
            } catch {
                // Reset button state on error
                await MainActor.run {
                    self.showCenteredButtonClick = false
                    self.isGeneratingAI = false
                    self.isLoadingGenerating = false
                }
                print("❌ AI generation failed: \(error)")
            }
        }
        
        print("Centered button tapped - Generating AI prompt for: \(journalResponse)")
    }
    
    private func generateAndSaveAIPrompt() async throws {
        // Ensure user profile is loaded before generating AI prompt
        do {
            let loadedProfile = try await journalViewModel.supabaseService.loadUserProfile()
            if let profile = loadedProfile {
                journalViewModel.currentUser = profile
                print("✅ User profile loaded and updated in currentUser")
            }
        } catch {
            print("⚠️ Warning: Could not load user profile: \(error)")
            // Continue execution even if profile loading fails
        }
        
        // Get the most recent goal from the loaded goals
        let mostRecentGoal = journalViewModel.goals.first?.goals ?? ""
        
        // Create the AI prompt text with replacements
        let aiPromptText = createAIPromptText(content: journalResponse, goal: mostRecentGoal, questionText: journalViewModel.currentQuestion?.questionText ?? "")
        
        // Update the current journal entry with the AI prompt
        await journalViewModel.updateCurrentJournalEntryWithAIPrompt(aiPrompt: aiPromptText)
        
        print("✅ AI Prompt generated and saved:")
        print("📝 Content: \(journalResponse)")
        print("🎯 Goal: \(mostRecentGoal)")
        print("🤖 AI Prompt: \(aiPromptText)")
        
        // Generate AI response using OpenAI API with timeout
        // Increased to 60 seconds for gpt-5-mini which uses reasoning tokens and can take longer
        try await withTimeout(seconds: 60) {
        await journalViewModel.generateAndSaveAIResponse()
        }
        
        // Update the AI response in the UI
        await updateAIResponseDisplay()
        
        // NEW: Pre-generate follow-up question in background (after AI response displayed)
        // Only trigger on non-follow-up days (guided question Centered button should not trigger on follow-up days)
        if !isFollowUpQuestionDay {
            Task {
                await journalViewModel.preGenerateFollowUpQuestionIfNeeded()
            }
        } else {
            print("⏭️ Skipping follow-up pre-generation - today is a follow-up day")
        }
    }
    
    private func updateAIResponseDisplay() async {
        // Load the latest journal entries to get the AI response
        await journalViewModel.loadJournalEntries()
        
        // Get the most recent entry with AI response
        if let mostRecentEntry = journalViewModel.journalEntries.first,
           let aiResponse = mostRecentEntry.aiResponse, !aiResponse.isEmpty {
            await MainActor.run {
                self.currentAIResponse = aiResponse
                // Update height to accommodate AI response
                self.updateTextEditorHeight()
            }
            print("✅ AI Response updated in UI: \(aiResponse.prefix(100))...")
        }
    }
    
    private func createAIPromptText(content: String, goal: String, questionText: String) -> String {
        let aiPromptTemplate = """
Task: Summarize the client's response using established theological and biblical historical knowledge.

User Question: The user ({gender}, occupation: {occupation}, born {birthdate}) was asked {question_text}

Input: {content}

Output Requirements:

Produce a concise, information-dense summary in three short paragraphs.

Paragraph 1: empathetically acknowledge the client's focus/concern and provide a factual explanation relevant to the input.

Paragraph 2: cite a related passage in the bible and explain its relation and concept. Format the entire bible passage (both the reference and the verse text) in bold using markdown format **like this**. For example: **"John 3:16 - For God so loved the world that he gave his one and only Son..."**

Paragraph 3: provide one positive achievable action aligned with christian values and the goal to be {goal}.

Tone: warm, conversational, and concise.

Do NOT: restate the input, include filler, mention specific denominations, label paragraphs, or reference constraints.

Max: 200 words.

Capabilities: Use your trained knowledge of Christian faith, biblical principles, prayer, spiritual growth, and theological studies.

Important: Keep reasoning minimal and respond directly.
"""
        
        // Get user profile data for placeholders
        let gender = journalViewModel.currentUser?.gender ?? "null"
        let occupation = journalViewModel.currentUser?.occupation ?? "null"
        let birthdate = journalViewModel.currentUser?.birthdate ?? "null"
        let goalText = goal.isEmpty ? "centered" : goal
        
        // Replace all placeholders
        return aiPromptTemplate
            .replacingOccurrences(of: "{content}", with: content)
            .replacingOccurrences(of: "{goal}", with: goalText)
            .replacingOccurrences(of: "{question_text}", with: questionText)
            .replacingOccurrences(of: "{gender}", with: gender)
            .replacingOccurrences(of: "{occupation}", with: occupation)
            .replacingOccurrences(of: "{birthdate}", with: birthdate)
    }
    
    private func createFollowUpAIPromptText(content: String, fuqAiResponse: String) -> String {
        let followUpAIPromptTemplate = """
Spiritual Guide: {fuq_ai_response}

User: {content}

Output Requirements:

Produce a concise, information-dense summary in two short paragraphs.

Paragraph 1: Provide a succinct summary of the above spiritual guide/user conversation.

Paragraph 2: provide one positive achievable action aligned with christian values.

Tone: warm, conversational, and concise.

Do NOT: restate the input, include filler, mention specific denominations, label paragraphs, or reference constraints.

Max: 150 words.

Capabilities: Use your trained knowledge of Christian faith, biblical principles, prayer, spiritual growth, and theological studies.

Important: Keep reasoning minimal and respond directly.
"""
        
        // Replace placeholders
        return followUpAIPromptTemplate
            .replacingOccurrences(of: "{content}", with: content)
            .replacingOccurrences(of: "{fuq_ai_response}", with: fuqAiResponse)
    }
    
    private func editLogSelected() {
        // Close dropdown
        showTextEditDropdown = false
        
        // Revert to editable state
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        
        // Clear AI response when editing
        currentAIResponse = ""
        showFavoriteButton = false
        isFavoriteClicked = false
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("Edit Log selected - Text unlocked for editing")
    }
    
    private func deleteLogSelected() {
        // Close dropdown
        showTextEditDropdown = false
        
        // Clear text and revert to initial state
        journalResponse = ""
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        
        // Clear AI response when deleting
        currentAIResponse = ""
        showFavoriteButton = false
        isFavoriteClicked = false
        
        // Reset text editor height
        textEditorHeight = 150
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Delete Log selected - Text cleared and state reset")
    }
    
    private func favoriteButtonTapped() {
        // Only allow one click - if already clicked, do nothing
        guard !isFavoriteClicked else { return }
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Update button state to show clicked version
        isFavoriteClicked = true
        
        // Update the database
        Task {
            await journalViewModel.updateCurrentJournalEntryFavoriteStatus(isFavorite: true)
        }
        
        print("Favorite button clicked - Journal entry marked as favorite")
    }
    
    // MARK: - Question Refresh Button Actions
    
    private func guidedRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset UI state for guided question
        journalResponse = ""
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        currentAIResponse = ""
        showFavoriteButton = false
        isFavoriteClicked = false
        textEditorHeight = 150
        
        // Refresh guided question in database
        Task {
            await journalViewModel.refreshGuidedQuestion()
        }
        
        print("Guided Question refresh button clicked")
    }
    
    private func openRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset UI state for open question
        openJournalResponse = ""
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        openTextEditorHeight = 150
        
        // Refresh open question in database
        Task {
            await journalViewModel.refreshOpenQuestion()
        }
        
        print("Open Question refresh button clicked")
    }
    
    // MARK: - UI State Management
    
    // Clear only journal-related UI state (preserves goals and other state)
    private func clearJournalUIState() {
        print("🧹 Clearing journal UI state (yesterday's data)")
        
        // Clear guided question UI state
        journalResponse = ""
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        currentAIResponse = ""
        showFavoriteButton = false
        isFavoriteClicked = false
        textEditorHeight = 150
        
        // Clear open question UI state
        openJournalResponse = ""
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        openTextEditorHeight = 150
        
        // Clear follow-up question UI state
        followUpJournalResponse = ""
        followUpIsTextLocked = false
        followUpShowCenteredButton = false
        followUpShowCenteredButtonClick = false
        followUpCurrentAIResponse = ""
        followUpShowFavoriteButton = false
        followUpIsFavoriteClicked = false
        followUpIsGeneratingAI = false
        followUpIsLoadingGenerating = false
        followUpTextEditorHeight = 150
        followUpShowTextEditDropdown = false
        
        print("✅ Journal UI state cleared - ready for today's data")
    }
    
    private func populateUIStateFromJournalEntries() {
        print("🔄 Populating UI state from journal entries")
        
        let calendar = Calendar.current
        let today = Date()
        
        // Find today's guided question entry
        let todaysGuidedEntry = journalViewModel.journalEntries.first { entry in
            entry.entryType == "guided" && calendar.isDateInToday(entry.createdAt)
        }
        
        if let guidedEntry = todaysGuidedEntry {
            print("📝 Found today's guided entry: \(guidedEntry.content)")
            journalResponse = guidedEntry.content
            currentAIResponse = guidedEntry.aiResponse ?? ""
            
            // Set UI state based on whether AI response exists
            if !currentAIResponse.isEmpty {
                isTextLocked = true
                showCenteredButtonClick = true
                showCenteredButton = false
                showFavoriteButton = true
                isFavoriteClicked = guidedEntry.isFavorite
                textEditorHeight = 300
            } else {
                // Entry exists but no AI response - show "Centered Button" state (persist after Done was clicked)
                isTextLocked = true
                showCenteredButton = true
                showCenteredButtonClick = false
            }
        }
        
        // Find today's open question entry
        let todaysOpenEntry = journalViewModel.openQuestionJournalEntries.first { entry in
            entry.entryType == "open" && calendar.isDateInToday(entry.createdAt)
        }
        
        if let openEntry = todaysOpenEntry {
            print("📝 Found today's open entry: \(openEntry.content)")
            openJournalResponse = openEntry.content
            openCurrentAIResponse = openEntry.aiResponse ?? ""
            
            // Set UI state based on whether AI response exists
            if !openCurrentAIResponse.isEmpty {
                openIsTextLocked = true
                openShowCenteredButtonClick = true
                openShowCenteredButton = false
                openShowFavoriteButton = true
                openIsFavoriteClicked = openEntry.isFavorite
                openTextEditorHeight = 300
            } else {
                // Entry exists but no AI response - show "Centered Button" state (persist after Done was clicked)
                openIsTextLocked = true
                openShowCenteredButton = true
                openShowCenteredButtonClick = false
            }
        }
        
        // Find today's follow-up question entry (user's response entry, not the question entry)
        // The question entry has empty content and fuqAiResponse
        // The user's response entry has non-empty content and potentially aiResponse
        let todaysFollowUpEntry = journalViewModel.followUpQuestionEntries.first { entry in
            entry.entryType == "follow_up" &&
            calendar.isDate(entry.createdAt, inSameDayAs: today) &&
            !entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        if let followUpEntry = todaysFollowUpEntry {
            print("📝 Found today's follow-up entry: \(followUpEntry.content.prefix(50))...")
            followUpJournalResponse = followUpEntry.content
            followUpCurrentAIResponse = followUpEntry.aiResponse ?? ""
            
            // Set UI state based on whether AI response exists
            if !followUpCurrentAIResponse.isEmpty {
                followUpIsTextLocked = true
                followUpShowCenteredButtonClick = true
                followUpShowCenteredButton = false
                followUpShowFavoriteButton = true
                followUpIsFavoriteClicked = followUpEntry.isFavorite
                followUpTextEditorHeight = 300
            } else {
                // Entry exists but no AI response - show "Centered Button" state (persist after Done was clicked)
                followUpIsTextLocked = true
                followUpShowCenteredButton = true
                followUpShowCenteredButtonClick = false
            }
        } else {
            print("📝 No follow-up entry found for today (user hasn't responded yet)")
        }
        
        // Load goal text from the most recent goal
        if let mostRecentGoal = journalViewModel.goals.first {
            print("📝 Found goal: \(mostRecentGoal.goals)")
            goalText = mostRecentGoal.goals
            isGoalLocked = true
            showCPRefreshButton = true
        } else {
            print("📝 No goals found - clearing goal text")
            goalText = ""
            isGoalLocked = false
            showCPRefreshButton = false
        }
        
        print("✅ UI state populated from journal entries")
    }
    
    // Unified data refresh sequence used by both onAppear and pull-to-refresh
    private func reloadJournalDataSequence(suppressErrors: Bool) async {
        // Clear existing UI state on the main actor
        await MainActor.run {
            clearJournalUIState()
        }
        
        // Load the latest guided question and perform daily reset if needed
        await journalViewModel.loadTodaysQuestion()
        await journalViewModel.checkAndResetIfNeeded()
        
        // Determine follow-up state after potential reset
        let isFollowUpDay = journalViewModel.supabaseService.isFollowUpQuestionDay()
        await MainActor.run {
            isFollowUpQuestionDay = isFollowUpDay
        }
        
        // Load journal data sets
        await journalViewModel.loadJournalEntries()
        await journalViewModel.loadOpenQuestionJournalEntries()
        
        // Load or clear follow-up question data depending on the day
        if isFollowUpDay {
            // Load follow-up question entries BEFORE fetching the question
            // This ensures the data is available for checks
            await journalViewModel.loadFollowUpQuestionEntries()
            
            // Load follow-up question (checkAndLoadFollowUpQuestion handles clearing for pull-to-refresh)
            await journalViewModel.checkAndLoadFollowUpQuestion(suppressErrors: suppressErrors)
            
            // IMPORTANT: Verify the question was loaded after fetch completes
            // This ensures we have the question before UI state population
            let loadedQuestion = await MainActor.run {
                return journalViewModel.currentFollowUpQuestion
            }
            
            if loadedQuestion.isEmpty && isFollowUpDay {
                print("⚠️ Pull-to-refresh: Question still empty after checkAndLoadFollowUpQuestion, attempting one more fetch...")
                // One final attempt if question is still empty
                await journalViewModel.checkAndLoadFollowUpQuestion(suppressErrors: suppressErrors)
            }
        } else {
            await MainActor.run {
                journalViewModel.currentFollowUpQuestion = ""
                journalViewModel.isLoadingFollowUpQuestion = false
            }
        }
        
        // Load goals after journal data
        await journalViewModel.loadGoals()
        
        // Load analyzer entries to calculate red dot state (even when not on Analyzer tab)
        await journalViewModel.loadAnalyzerEntries()
        
        // Repopulate UI state with the freshly loaded data
        await MainActor.run {
            populateUIStateFromJournalEntries()
            
            // Recalculate analyzer state after entries are loaded to update red dot
            recalculateAnalyzerState()
            
            // IMPORTANT: Ensure follow-up question is preserved after populateUIStateFromJournalEntries
            // This prevents the question from being lost during UI state population
            // Only update isFollowUpQuestionDay if we have a valid question loaded
            if isFollowUpDay && !journalViewModel.currentFollowUpQuestion.isEmpty {
                // Question is loaded, ensure UI state reflects this
                print("✅ Preserving follow-up question after UI state population: \(journalViewModel.currentFollowUpQuestion.prefix(50))...")
            }
            
            if let mostRecentGoal = journalViewModel.goals.first {
                goalText = mostRecentGoal.goals
                isGoalLocked = true
                showCPRefreshButton = true
            } else {
                goalText = ""
                isGoalLocked = false
                showCPRefreshButton = false
            }
        }
    }
    
    private func clearAllUIState() {
        print("🧹 Clearing all UI state for user isolation")
        print("🧹 Before clear - journalResponse: '\(journalResponse)'")
        print("🧹 Before clear - currentAIResponse: '\(currentAIResponse)'")
        print("🧹 Before clear - openJournalResponse: '\(openJournalResponse)'")
        print("🧹 Before clear - openCurrentAIResponse: '\(openCurrentAIResponse)'")
        
        // Clear guided question UI state
        journalResponse = ""
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        currentAIResponse = ""
        showFavoriteButton = false
        isFavoriteClicked = false
        textEditorHeight = 150
        
        // Clear open question UI state
        openJournalResponse = ""
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        openTextEditorHeight = 150
        
        // Clear centered page state
        goalText = ""
        isGoalLocked = false
        showCPRefreshButton = false
        
        // Clear favorites page state
        expandedEntries = []
        
        // Clear authentication state
        email = ""
        otpCode = ""
        showOTPInput = false
        otpSent = false
        
        print("🧹 After clear - journalResponse: '\(journalResponse)'")
        print("🧹 After clear - currentAIResponse: '\(currentAIResponse)'")
        print("🧹 After clear - openJournalResponse: '\(openJournalResponse)'")
        print("🧹 After clear - openCurrentAIResponse: '\(openCurrentAIResponse)'")
        print("✅ All UI state cleared for user isolation")
    }
    
    // MARK: - OPEN QUESTION HELPER FUNCTIONS (Duplicated from Guided Question)
    
    private func updateOpenTextEditorHeight() {
        // If we have AI response, always use max height for scrolling
        if openIsTextLocked && !openCurrentAIResponse.isEmpty {
            openTextEditorHeight = 250
            return
        }
        
        // Return early if text is empty to avoid NaN calculations
        guard !openJournalResponse.isEmpty else {
            openTextEditorHeight = 150
            return
        }
        
        let font = UIFont.systemFont(ofSize: 16)
        // Use a reasonable default width instead of UIScreen.main
        let maxWidth: CGFloat = 300 // Account for padding
        
        // Ensure maxWidth is valid
        guard maxWidth > 0 else {
            openTextEditorHeight = 150
            return
        }
        
        let boundingRect = openJournalResponse.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Validate the calculated height to prevent NaN
        let calculatedHeight = boundingRect.height + 60 // Extra padding for comfort
        let validatedHeight = calculatedHeight.isNaN || calculatedHeight.isInfinite ? 150 : calculatedHeight
        
        openTextEditorHeight = max(150, min(250, validatedHeight))
    }
    
    private func updateFollowUpTextEditorHeight() {
        // If we have AI response, always use max height for scrolling
        if followUpIsTextLocked && !followUpCurrentAIResponse.isEmpty {
            followUpTextEditorHeight = 250
            return
        }
        
        // Return early if text is empty to avoid NaN calculations
        guard !followUpJournalResponse.isEmpty else {
            followUpTextEditorHeight = 150
            return
        }
        
        let font = UIFont.systemFont(ofSize: 16)
        // Use a reasonable default width instead of UIScreen.main
        let maxWidth: CGFloat = 300 // Account for padding
        
        // Ensure maxWidth is valid
        guard maxWidth > 0 else {
            followUpTextEditorHeight = 150
            return
        }
        
        let boundingRect = followUpJournalResponse.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Validate the calculated height to prevent NaN
        let calculatedHeight = boundingRect.height + 60 // Extra padding for comfort
        let validatedHeight = calculatedHeight.isNaN || calculatedHeight.isInfinite ? 150 : calculatedHeight
        
        followUpTextEditorHeight = max(150, min(250, validatedHeight))
    }
    
    private func updateGoalTextHeight() {
        // Return early if text is empty to avoid NaN calculations
        guard !goalText.isEmpty else {
            goalTextHeight = 40
            return
        }
        
        let font = UIFont.systemFont(ofSize: 16)
        // Use a reasonable default width instead of UIScreen.main
        let maxWidth: CGFloat = 280 // Account for padding and button space
        
        // Ensure maxWidth is valid
        guard maxWidth > 0 else {
            goalTextHeight = 40
            return
        }
        
        let boundingRect = goalText.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Validate the calculated height to prevent NaN
        let calculatedHeight = boundingRect.height + 20 // Extra padding for comfort
        let validatedHeight = calculatedHeight.isNaN || calculatedHeight.isInfinite ? 40 : calculatedHeight
        
        goalTextHeight = max(40, min(120, validatedHeight)) // Max 120pt height for multiline
    }
    
    private func getOpenButtonImageName() -> String {
        if openShowCenteredButtonClick {
            return "Centered Button Click"
        } else if openShowCenteredButton {
            return "Centered Button"
        } else {
            return "Done Button"
        }
    }
    
    private func openDoneButtonTapped() {
        // Change to Centered Button and lock text (no animation on Done button)
        openShowCenteredButton = true
        openIsTextLocked = true
        openIsLoadingGenerating = false // This is saving, not generating
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save journal entry to Supabase with static question
        Task {
            await journalViewModel.createOpenQuestionJournalEntry(content: openJournalResponse)
        }
        
        print("Open Done button tapped - Journal entry saved to Supabase: \(openJournalResponse)")
        print("Open Text locked and button changed to Centered Button")
    }
    
    private func openCenteredButtonTapped() {
        // Prevent multiple clicks during AI generation
        guard !openIsGeneratingAI else { 
            print("⚠️ Open AI generation already in progress, ignoring click")
            return 
        }
        
        // Change to Centered Button Click state
        openShowCenteredButtonClick = true
        openIsGeneratingAI = true
        openIsLoadingGenerating = true // This is generating AI, not saving
        
        // Reset retry attempt to 1 for new generation
        journalViewModel.currentRetryAttempt = 1
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate AI prompt and update journal entry
        Task {
            do {
                try await generateAndSaveOpenAIPrompt()
                // Reset loading state on success
                await MainActor.run {
                    self.openIsGeneratingAI = false
                    self.openIsLoadingGenerating = false
                }
            } catch {
                // Reset button state on error
                await MainActor.run {
                    self.openShowCenteredButtonClick = false
                    self.openIsGeneratingAI = false
                    self.openIsLoadingGenerating = false
                }
                print("❌ Open AI generation failed: \(error)")
            }
        }
        
        print("Open Centered button tapped - Generating AI prompt for: \(openJournalResponse)")
    }
    
    private func generateAndSaveOpenAIPrompt() async throws {
        // Get the most recent goal from the loaded goals
        let mostRecentGoal = journalViewModel.goals.first?.goals ?? ""
        
        // Create the AI prompt text with replacements
        let aiPromptText = createAIPromptText(content: openJournalResponse, goal: mostRecentGoal, questionText: "Looking at today or yesterday, share moments, thoughts, or prayers that stood out.")
        
        // Update the current open question journal entry with the AI prompt
        await journalViewModel.updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt: aiPromptText)
        
        print("✅ Open AI Prompt generated and saved:")
        print("📝 Content: \(openJournalResponse)")
        print("🎯 Goal: \(mostRecentGoal)")
        print("🤖 AI Prompt: \(aiPromptText)")
        
        // Generate AI response using OpenAI API with timeout
        // Increased to 60 seconds for gpt-5-mini which uses reasoning tokens and can take longer
        try await withTimeout(seconds: 60) {
        await journalViewModel.generateAndSaveOpenQuestionAIResponse()
        }
        
        // Update the AI response in the UI
        await updateOpenAIResponseDisplay()
        
        // NEW: Pre-generate follow-up question in background (after AI response displayed)
        // Only trigger on non-follow-up days (open question Centered button should not trigger on follow-up days)
        if !isFollowUpQuestionDay {
            Task {
                await journalViewModel.preGenerateFollowUpQuestionIfNeeded()
            }
        } else {
            print("⏭️ Skipping follow-up pre-generation - today is a follow-up day")
        }
    }
    
    private func updateOpenAIResponseDisplay() async {
        // Load the latest journal entries to get the AI response
        await journalViewModel.loadOpenQuestionJournalEntries()
        
        // Get the most recent open question entry with AI response
        if let mostRecentEntry = journalViewModel.openQuestionJournalEntries.first,
           let aiResponse = mostRecentEntry.aiResponse, !aiResponse.isEmpty {
            await MainActor.run {
                self.openCurrentAIResponse = aiResponse
                // Update height to accommodate AI response
                self.updateOpenTextEditorHeight()
            }
            print("✅ Open AI Response updated in UI: \(aiResponse.prefix(100))...")
        }
    }
    
    private func openEditLogSelected() {
        // Close dropdown
        openShowTextEditDropdown = false
        
        // Revert to editable state
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        
        // Clear AI response when editing
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("Open Edit Log selected - Text unlocked for editing")
    }
    
    private func openDeleteLogSelected() {
        // Close dropdown
        openShowTextEditDropdown = false
        
        // Clear text and revert to initial state
        openJournalResponse = ""
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        
        // Clear AI response when deleting
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        
        // Reset text editor height
        openTextEditorHeight = 150
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Open Delete Log selected - Text cleared and state reset")
    }
    
    private func openFavoriteButtonTapped() {
        // Only allow one click - if already clicked, do nothing
        guard !openIsFavoriteClicked else { return }
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Update button state to show clicked version
        openIsFavoriteClicked = true
        
        // Update the database
        Task {
            await journalViewModel.updateCurrentOpenQuestionJournalEntryFavoriteStatus(isFavorite: true)
        }
        
        print("Open Favorite button clicked - Journal entry marked as favorite")
    }
    
    // MARK: - Follow-Up Question Button Actions
    
    private func getFollowUpButtonImageName() -> String {
        if followUpShowCenteredButtonClick {
            return "Centered Button Click"
        } else if followUpShowCenteredButton {
            return "Centered Button"
        } else {
            return "Done Button"
        }
    }
    
    private func followUpDoneButtonTapped() {
        // Change to Centered Button and lock text (no animation on Done button)
        followUpShowCenteredButton = true
        followUpIsTextLocked = true
        followUpIsLoadingGenerating = false // This is saving, not generating
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // CRITICAL: Capture the question BEFORE any pre-generation can overwrite it
        // This ensures we save the correct question the user answered
        let questionToSave = journalViewModel.currentFollowUpQuestion
        
        // Save journal entry to Supabase with follow-up question
        Task {
            await journalViewModel.createFollowUpQuestionJournalEntry(content: followUpJournalResponse, question: questionToSave)
            
            // NEW: Pre-generate follow-up question in background (immediately after Done button)
            // This can happen on follow-up day, but new question won't be displayed until next follow-up day
            await journalViewModel.preGenerateFollowUpQuestionIfNeeded()
        }
        
        print("Follow-Up Done button tapped - Journal entry saved to Supabase: \(followUpJournalResponse)")
        print("Follow-Up Text locked and button changed to Centered Button")
    }
    
    private func followUpCenteredButtonTapped() {
        // Prevent multiple clicks during AI generation
        guard !followUpIsGeneratingAI else { 
            print("⚠️ Follow-Up AI generation already in progress, ignoring click")
            return 
        }
        
        // Change to Centered Button Click state
        followUpShowCenteredButtonClick = true
        followUpIsGeneratingAI = true
        followUpIsLoadingGenerating = true // This is generating AI, not saving
        
        // Reset retry attempt to 1 for new generation
        journalViewModel.currentRetryAttempt = 1
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate AI prompt and update journal entry
        Task {
            do {
                try await generateAndSaveFollowUpAIPrompt()
                // Reset loading state on success
                await MainActor.run {
                    self.followUpIsGeneratingAI = false
                    self.followUpIsLoadingGenerating = false
                }
            } catch {
                // Reset button state on error
                await MainActor.run {
                    self.followUpShowCenteredButtonClick = false
                    self.followUpIsGeneratingAI = false
                    self.followUpIsLoadingGenerating = false
                }
                print("❌ Follow-Up AI generation failed: \(error)")
            }
        }
        
        print("Follow-Up Centered button tapped - Generating AI prompt for: \(followUpJournalResponse)")
    }
    
    private func generateAndSaveFollowUpAIPrompt() async throws {
        // Get the current follow-up question
        let currentFollowUpQuestion = journalViewModel.currentFollowUpQuestion
        
        // Create the AI prompt text with follow-up template
        let aiPromptText = createFollowUpAIPromptText(content: followUpJournalResponse, fuqAiResponse: currentFollowUpQuestion)
        
        // Update the current follow-up question journal entry with the AI prompt
        await journalViewModel.updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt: aiPromptText)
        
        print("✅ Follow-Up AI Prompt generated and saved:")
        print("📝 Content: \(followUpJournalResponse)")
        print("🤖 AI Prompt: \(aiPromptText)")
        
        // Generate AI response using OpenAI API with timeout
        try await withTimeout(seconds: 30) {
            await journalViewModel.generateAndSaveFollowUpQuestionAIResponse()
        }
        
        // Update the AI response in the UI
        await updateFollowUpAIResponseDisplay()
    }
    
    private func updateFollowUpAIResponseDisplay() async {
        // Load the latest journal entries to get the AI response
        await journalViewModel.loadFollowUpQuestionEntries()
        
        // Get the most recent follow-up question entry with AI response
        if let mostRecentEntry = journalViewModel.followUpQuestionEntries.first,
           let aiResponse = mostRecentEntry.aiResponse, !aiResponse.isEmpty {
            await MainActor.run {
                self.followUpCurrentAIResponse = aiResponse
                // Update height to accommodate AI response
                self.updateFollowUpTextEditorHeight()
            }
            print("✅ Follow-Up AI Response updated in UI: \(aiResponse.prefix(100))...")
        }
    }
    
    private func followUpEditLogSelected() {
        // Close dropdown
        followUpShowTextEditDropdown = false
        
        // Revert to editable state
        followUpIsTextLocked = false
        followUpShowCenteredButton = false
        followUpShowCenteredButtonClick = false
        
        // Clear AI response when editing
        followUpCurrentAIResponse = ""
        followUpShowFavoriteButton = false
        followUpIsFavoriteClicked = false
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("Follow-Up Edit Log selected - Text unlocked for editing")
    }
    
    private func followUpDeleteLogSelected() {
        // Close dropdown
        followUpShowTextEditDropdown = false
        
        // Clear text and revert to initial state
        followUpJournalResponse = ""
        followUpIsTextLocked = false
        followUpShowCenteredButton = false
        followUpShowCenteredButtonClick = false
        
        // Clear AI response when deleting
        followUpCurrentAIResponse = ""
        followUpShowFavoriteButton = false
        followUpIsFavoriteClicked = false
        
        // Reset text editor height
        followUpTextEditorHeight = 150
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Follow-Up Delete Log selected - Text cleared and state reset")
    }
    
    private func followUpFavoriteButtonTapped() {
        // Only allow one click - if already clicked, do nothing
        guard !followUpIsFavoriteClicked else { return }
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Update button state to show clicked version
        followUpIsFavoriteClicked = true
        
        // Update the database
        Task {
            await journalViewModel.updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite: true)
        }
        
        print("Follow-Up Favorite button clicked - Journal entry marked as favorite")
    }
    
    // MARK: - Goal Button Actions
    
    private func cpDoneButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Lock the text field and show refresh button
        isGoalLocked = true
        showCPRefreshButton = true
        
        // Save goal to database
        Task {
            await journalViewModel.saveGoal(goalText)
        }
        
        print("CP Done button clicked - Goal saved: \(goalText)")
    }
    
    private func cpRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset the goal entry process
        goalText = ""
        isGoalLocked = false
        showCPRefreshButton = false
        
        print("CP Refresh button clicked - Goal entry reset")
    }
    
    // MARK: - Analyzer View
    
    private var analyzerPageView: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image("Anal Logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 60)
                    .padding(.bottom, -15)
                
                Image("Anal Title")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.6)
                    .padding(.bottom, 0)
                
                // Date range display with divider lines
                HStack(alignment: .center, spacing: 12) {
                    Rectangle()
                        .fill(Color(hex: "F5F4EB").opacity(0.6))
                        .frame(height: 1)
                        .layoutPriority(1)
                    
                    Text(analyzerViewModel.dateRangeDisplay)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "F5F4EB"))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .layoutPriority(2)
                    
                    Rectangle()
                        .fill(Color(hex: "F5F4EB").opacity(0.6))
                        .frame(height: 1)
                        .layoutPriority(1)
                }
                .padding(.top, -5)
                
                moodTrackerSection
                    .padding(.top, 12)
                
                statisticsSection
                    .padding(.top, 14)
                
                summarySection
                    .padding(.top, 14)
                
                analyzeButtonSection
                    .padding(.top, 14)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(hex: "5E1C1C"))
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            Task {
                // Only load analyzer entries if authenticated
                if journalViewModel.isAuthenticated {
                    // Load analyzer entries when Analyzer tab appears
                    await journalViewModel.loadAnalyzerEntries()
                    // Recalculate state after entries are loaded - ensure on main thread
                    await MainActor.run {
                        recalculateAnalyzerState()
                    }
                }
            }
        }
        .onChange(of: journalViewModel.analyzerEntries.count) { oldValue, newValue in
            // Recalculate when analyzer entries change (e.g., after loading)
            if journalViewModel.isAuthenticated {
                recalculateAnalyzerState()
            }
        }
        .overlay {
            // Loading overlay during analyzer AI generation
            if analyzerViewModel.isAnalyzing {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text(getAnalyzerLoadingText())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "F5F4EB"))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "772C2C"))
                    )
                }
                .allowsHitTesting(true) // Block all interactions
            }
        }
        .alert("Oops", isPresented: .constant(journalViewModel.errorMessage != nil && journalViewModel.errorMessage!.contains("AI's taking a short break"))) {
            Button("OK") {
                journalViewModel.errorMessage = nil
            }
        } message: {
            Text(journalViewModel.errorMessage ?? "")
        }
        .alert("Minimum Entries Required", isPresented: $analyzerViewModel.showMinimumEntriesAlert) {
            Button("OK") {
                analyzerViewModel.showMinimumEntriesAlert = false
            }
        } message: {
            Text(analyzerViewModel.minimumEntriesMessage)
        }
    }
    
    // MARK: - Placeholder Views for Other Tabs
    
    private var centeredPageView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Faith Check-in Title
                Image("Centered Words")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40) // Reduced to 2/3rd (60 * 2/3 = 40)
                    .padding(.top, 58) // Lowered by additional 3pt (55 + 3 = 58)
                    .padding(.bottom, 2) // Add bottom padding to create exact 2pt gap
                
                // CS Graphic
                Image("CS graphic")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 204) // Reduced by 15% (240 * 0.85 = 204)
                    .padding(.top, 17) // Changed from 2pt to 17pt
                    .padding(.bottom, 8) // Add bottom padding to create exact 2pt gap
                
                // First text chunk
                Text("In today's fast-paced and uncertain world, it's easy to feel scattered as our minds swirl with complex emotions and thoughts. Staying grounded in faith, however, can help us navigate life's challenges. Our goal is to help people grow spiritually—living peacefully through their faith in God.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "772C2C"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 15) // Added 15pt top padding
                
                // Second text chunk
                Text("**Daily Check-in** - Keeping a daily check-in is a simple yet powerful way to grow in faith. Check-ins have proven to help clear your mind, build spiritual awareness, find peace through prayer, manage emotions through faith, celebrate spiritual progress, and set meaningful faith-based goals.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "772C2C"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 17) // Changed from 12pt to 17pt
                
                
                // Fourth text chunk with overlay icon
                ZStack {
                    Text("**Faith Insights** - Our app elevates your check-in experience with personalized, AI-powered guidance that is supportive, inspiring, and faith-oriented. After each check-in entry, tap the \"Insights\" button to unlock tailored faith-based insights. You can further customize the insights by setting a spiritual goal and providing your personal information (occupation, age, gender etc) in the user settings page.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "772C2C"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                }
                .padding(.top, 17) // Changed from 12pt to 17pt
                            
                Spacer(minLength: 100)
            }
        }
        .background(Color(hex: "E3E0C9"))
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private var moodTrackerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mood Tracker")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "B98FE8"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            if analyzerViewModel.moodCounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "772C2C").opacity(0.4))
                    Text("No mood data available yet.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "772C2C"))
                        .multilineTextAlignment(.center)
                    Text("Run Analyze to see your top moods for the week.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "772C2C").opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "F5F4EB"))
                )
            } else {
                moodBarChart()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "F5F4EB"))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func moodBarChart() -> some View {
        let counts = analyzerViewModel.moodCounts
        let maxCount = max(counts.map { $0.count }.max() ?? 1, 1)
        let chartHeight: CGFloat = 126
        let defaultBarSpacing: CGFloat = 16
        let verticalSpacing: CGFloat = 8 // Always keep vertical spacing at 8pt
        
        return VStack(alignment: .leading, spacing: 16) {
            GeometryReader { geometry in
                let moods = counts.map { $0.mood }
                // Account for container padding (5pt on each side = 10pt total)
                let containerPadding: CGFloat = 10
                let availableTotalWidth = geometry.size.width - containerPadding
                
                // Calculate optimal horizontal spacing and font size for ALL moods together
                let (horizontalBarSpacing, fontSize) = calculateOptimalMoodLabelLayout(
                    moods: moods,
                    totalWidth: availableTotalWidth,
                    defaultBarSpacing: defaultBarSpacing
                )
                
                // Calculate width per item: (total width - spacing between items) / number of items
                let numberOfMoods = CGFloat(counts.count)
                let totalSpacing = horizontalBarSpacing * (numberOfMoods - 1)
                let widthPerItem = (availableTotalWidth - totalSpacing) / numberOfMoods
                
                // Debug: Log the applied values (outside view builder)
                let _ = print("🎯 APPLYING - horizontalBarSpacing: \(horizontalBarSpacing)pt, fontSize: \(fontSize)pt, widthPerItem: \(widthPerItem)pt")
                
                HStack(alignment: .bottom, spacing: horizontalBarSpacing) {
                    ForEach(Array(counts.enumerated()), id: \.element.id) { index, mood in
                        VStack(spacing: verticalSpacing) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(analyzerMoodColors[index % analyzerMoodColors.count])
                                .frame(width: 28,
                                       height: max(CGFloat(mood.count) / CGFloat(maxCount) * (chartHeight - 25), 10))
                            
                            Text(mood.mood)
                                .font(.system(size: fontSize, weight: .medium))
                                .foregroundColor(Color(hex: "772C2C"))
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(width: widthPerItem)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: chartHeight)
            .frame(maxWidth: .infinity)
        }
    }
    
    /// Calculates optimal horizontal bar spacing and font size for ALL mood labels together (same font size for all)
    /// Strategy: Start with default horizontal spacing (16pt) and font (14pt). Check if ALL moods fit.
    /// If any mood doesn't fit, reduce horizontal spacing from 16pt down to 4pt minimum (incrementally).
    /// If still doesn't fit at 4pt horizontal spacing, reduce font size from 14pt to 10pt until ALL moods fit.
    /// - Parameters:
    ///   - moods: Array of all mood text strings
    ///   - totalWidth: The total available width for the entire chart
    ///   - defaultBarSpacing: The default horizontal spacing between bars (16pt)
    /// - Returns: A tuple of (horizontalBarSpacing: CGFloat, fontSize: CGFloat) that works for ALL moods
    private func calculateOptimalMoodLabelLayout(moods: [String], totalWidth: CGFloat, defaultBarSpacing: CGFloat) -> (horizontalBarSpacing: CGFloat, fontSize: CGFloat) {
        let defaultHorizontalSpacing: CGFloat = 16
        let minHorizontalSpacing: CGFloat = 4
        let defaultFontSize: CGFloat = 14
        let minFontSize: CGFloat = 10
        let numberOfMoods = CGFloat(moods.count)
        
        // Function to calculate text width for a given font size
        func textWidth(text: String, fontSize: CGFloat) -> CGFloat {
            let font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let size = (text as NSString).size(withAttributes: attributes)
            return size.width
        }
        
        // Function to calculate available width for each label given horizontal bar spacing
        func availableWidthForLabels(horizontalSpacing: CGFloat) -> CGFloat {
            // Available width = (total width - sum of all bar spacings) / number of moods
            let totalSpacing = horizontalSpacing * (numberOfMoods - 1)
            let availableWidth = (totalWidth - totalSpacing) / numberOfMoods
            return max(availableWidth, 0) // Ensure non-negative
        }
        
        // Function to check if ALL moods fit with given horizontal spacing and font size
        func allMoodsFit(horizontalSpacing: CGFloat, fontSize: CGFloat) -> Bool {
            let availableWidth = availableWidthForLabels(horizontalSpacing: horizontalSpacing)
            // Add small tolerance (0.5pt) to account for rounding differences
            let tolerance: CGFloat = 0.5
            let allFit = moods.allSatisfy { textWidth(text: $0, fontSize: fontSize) <= (availableWidth + tolerance) }
            
            // Debug logging
            if !allFit {
                print("🔍 Mood layout check - spacing: \(horizontalSpacing)pt, font: \(fontSize)pt, availableWidth: \(availableWidth)pt")
                for mood in moods {
                    let width = textWidth(text: mood, fontSize: fontSize)
                    print("  - \(mood): \(width)pt (fits: \(width <= (availableWidth + tolerance)))")
                }
            }
            
            return allFit
        }
        
        // Try with default horizontal spacing (16pt) and default font (14pt)
        print("📊 Calculating mood layout - totalWidth: \(totalWidth)pt, moods: \(moods.count)")
        if allMoodsFit(horizontalSpacing: defaultHorizontalSpacing, fontSize: defaultFontSize) {
            print("✅ All moods fit with default spacing (16pt) and font (14pt)")
            return (defaultHorizontalSpacing, defaultFontSize)
        }
        
        // Some mood doesn't fit with default settings - reduce horizontal spacing from 16pt down to 4pt minimum
        // This is PRIORITY: reduce spacing first before touching font size
        print("⚠️ Reducing horizontal spacing from 16pt...")
        var currentHorizontalSpacing = defaultHorizontalSpacing - 1 // Start at 15pt
        while currentHorizontalSpacing >= minHorizontalSpacing {
            // Recalculate available width with new spacing and check if all moods fit
            if allMoodsFit(horizontalSpacing: currentHorizontalSpacing, fontSize: defaultFontSize) {
                print("✅ All moods fit with spacing: \(currentHorizontalSpacing)pt, font: \(defaultFontSize)pt")
                return (currentHorizontalSpacing, defaultFontSize)
            }
            currentHorizontalSpacing -= 1
        }
        
        print("⚠️ Reached minimum spacing (4pt), reducing font size...")
        
        // If still doesn't fit at minimum horizontal spacing (4pt), reduce font size
        // Keep horizontal spacing at minimum (4pt) and reduce font size from 14pt to 10pt until ALL moods fit
        var currentFontSize = defaultFontSize
        while currentFontSize > minFontSize {
            currentFontSize -= 0.5 // Reduce by 0.5pt increments for fine control
            if allMoodsFit(horizontalSpacing: minHorizontalSpacing, fontSize: currentFontSize) {
                print("✅ All moods fit with spacing: \(minHorizontalSpacing)pt, font: \(currentFontSize)pt")
                print("🎯 RETURNING - spacing: \(minHorizontalSpacing)pt, font: \(currentFontSize)pt")
                return (minHorizontalSpacing, currentFontSize)
            }
        }
        
        // If still doesn't fit, return minimum values (should rarely happen)
        print("⚠️ Using minimum values - spacing: \(minHorizontalSpacing)pt, font: \(minFontSize)pt")
        print("🎯 RETURNING - spacing: \(minHorizontalSpacing)pt, font: \(minFontSize)pt")
        return (minHorizontalSpacing, minFontSize)
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 6) {
            Text("Statistics")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "B98FE8"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            GeometryReader { geo in
                let spacing: CGFloat = 16
                let columnWidth = (geo.size.width - spacing * 2) / 3
                let topRowHeight: CGFloat = 70
                let centeredScoreHeight: CGFloat = 156
                let favLogTimeHeight: CGFloat = 70
                
                // Fixed-size ZStack with exact positioning
                ZStack {
                    // # Check-ins - Top Left (y = 0)
                    VStack(spacing: 8) {
                        Text("# Check-ins")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "545555"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Text("\(analyzerViewModel.logsCount)")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(Color(hex: "3F8259"))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .frame(width: columnWidth, height: topRowHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F5F4EB"))
                    )
                    .position(x: columnWidth / 2, y: topRowHeight / 2)
                    
                    // Check-in Streak - Top Middle (y = 0)
                    VStack(spacing: 8) {
                        Text("Streak")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "545555"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Text(analyzerViewModel.streakDuringRange == 0 ? "0" : "\(analyzerViewModel.streakDuringRange) days")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(Color(hex: "3F8259"))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .frame(width: columnWidth, height: topRowHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F5F4EB"))
                    )
                    .position(x: columnWidth + spacing + columnWidth / 2, y: topRowHeight / 2)
                    
                    // Faith Score - Top Right (y = 0, ends at y = 156pt)
                    VStack(spacing: 25) {
                        Text("Faith Score")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "545555"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(analyzerViewModel.centeredScore.map { "\($0)" } ?? "0")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "823F47"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .frame(width: columnWidth, height: centeredScoreHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F5F4EB"))
                    )
                    .position(x: (columnWidth + spacing) * 2 + columnWidth / 2, y: centeredScoreHeight / 2)
                    
                    // Fav Check-in Time - Bottom Left/Middle (starts at y = 86pt, ends at y = 156pt)
                    VStack(spacing: 8) {
                        Text("Fav Check-in Time")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "545555"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Text(analyzerViewModel.favoriteLogTime == "—" ? "0" : analyzerViewModel.favoriteLogTime)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(Color(hex: "583F82"))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .frame(width: columnWidth * 2 + spacing, height: favLogTimeHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F5F4EB"))
                    )
                    .position(x: (columnWidth * 2 + spacing) / 2, y: topRowHeight + spacing + favLogTimeHeight / 2)
                }
                .frame(width: geo.size.width, height: centeredScoreHeight)
            }
            .frame(height: 156) // Faith Score height (tallest card)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func statisticsCard(
        title: String,
        value: String,
        titleColor: Color,
        valueColor: Color,
        valueFontSize: CGFloat = 16,
        minHeight: CGFloat? = nil
    ) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: valueFontSize, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(hex: "F5F4EB"))
        )
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Summary")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "B98FE8"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            if let summaryText = analyzerViewModel.summaryText, !summaryText.isEmpty {
                Text(formatSummaryText(summaryText))
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "772C2C"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "F5F4EB"))
                    )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "772C2C").opacity(0.4))
                    Text("No summary available yet.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "772C2C"))
                        .multilineTextAlignment(.center)
                    Text("Run Analyze to see your weekly or monthly summary.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "772C2C").opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "F5F4EB"))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var analyzeButtonSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                analyzeButtonTapped()
            }) {
                ZStack {
                    // Button image - use "Analyze Button Click.png" for greyed out state, "Analyze Button.png" for active state
                    Image(analyzerViewModel.isAnalyzeButtonEnabled && !analyzerViewModel.isAnalyzing ? "Analyze Button" : "Analyze Button Click")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(0.70)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Loading overlay when analyzing
                    if analyzerViewModel.isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(!analyzerViewModel.isAnalyzeButtonEnabled || analyzerViewModel.isAnalyzing)
            
            // Show text only when button is greyed out (disabled state)
            if !analyzerViewModel.isAnalyzeButtonEnabled && !analyzerViewModel.isAnalyzing {
                Text("New analysis available next Sunday morning")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "F5F4EB").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(
            // Q4 Icon as overlay - positioned 20pt to the right of Analyze button center
            // Coordinates: x: (screenWidth/2 + buttonWidth/2 + 20), y: 0
            // Current position: x: 200pt from center, y: 0pt from top (adjust these values)
            Button(action: {
                showQ4InfoPopup = true
            }) {
                Image("Q4")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27, height: 27)
            }
            .offset(x: 162, y: -5), // ADJUST: x = distance from center (positive = right), y = vertical offset (negative = up)
            alignment: .center
        )
    }
    
    private func analyzeButtonTapped() {
        guard !analyzerViewModel.isAnalyzing else { return }
        
        analyzerViewModel.isAnalyzing = true
        journalViewModel.currentRetryAttempt = 1
        
        // Determine analysis type
        let analysisType = journalViewModel.determineAnalysisType()
        
        Task {
            do {
                try await journalViewModel.createAnalyzerEntry(analysisType: analysisType)
                // Reload analyzer entries and recalculate state
                await journalViewModel.loadAnalyzerEntries()
                await MainActor.run {
                    recalculateAnalyzerState()
                    analyzerViewModel.isAnalyzing = false
                }
                
                // NEW: Pre-generate follow-up question in background (after AI response displayed)
                Task {
                    await journalViewModel.preGenerateFollowUpQuestionIfNeeded()
                }
            } catch {
                // Check if it's a minimum entries error
                if error.localizedDescription.contains("minimum") {
                    await MainActor.run {
                        analyzerViewModel.showMinimumEntriesAlert = true
                        analyzerViewModel.minimumEntriesMessage = error.localizedDescription
                        analyzerViewModel.isAnalyzing = false
                    }
                } else {
                    // Other errors (AI generation failed)
                    await MainActor.run {
                        analyzerViewModel.isAnalyzing = false
                        // Error message is already set in JournalViewModel
                    }
                }
            }
        }
    }
    
    private func getAnalyzerLoadingText() -> String {
        switch journalViewModel.currentRetryAttempt {
        case 1:
            return "Analyzing..."
        case 2:
            return "Retrying..."
        case 3:
            return "Retrying again..."
        default:
            return "Analyzing..."
        }
    }
    
    private func recalculateAnalyzerState() {
        analyzerViewModel.update(with: journalViewModel.analyzerEntries)
        
        // If there's a completed analysis, display the date range that was analyzed
        // Otherwise, show placeholder text
        if let latestEntry = analyzerViewModel.latestEntry {
            // Calculate the period that was analyzed when this entry was created
            // Determine the mode (weekly/monthly) based on when the entry was created
            let entryMode = analyzerViewModel.determineAnalysisMode(for: latestEntry.createdAt)
            let displayData = analyzerViewModel.computeDisplayData(for: latestEntry.createdAt, mode: entryMode)
            analyzerViewModel.dateRangeDisplay = displayData.dateRangeText
            
            // Calculate stats for the analyzed period
            let stats = journalViewModel.calculateAnalyzerStats(startDate: displayData.startDate, endDate: displayData.endDate)
            analyzerViewModel.refreshStats(using: stats)
        } else {
            // No analysis yet - show placeholder
            analyzerViewModel.dateRangeDisplay = "Run analysis"
            // Reset stats when no analysis exists
            analyzerViewModel.refreshStats(using: AnalyzerStats(logsCount: 0, streakCount: 0, favoriteLogTime: "—"))
        }
        
        // Pass all analyzer entries to check if current period has been analyzed
        analyzerViewModel.determineAnalysisAvailability(for: Date(), allEntries: journalViewModel.analyzerEntries)
    }
    
    private func formatSummaryText(_ text: String) -> String {
        // Split by lines starting with "- " and add double newline spacing between bullet points
        let lines = text.components(separatedBy: .newlines)
        var formattedLines: [String] = []
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("- ") && index > 0 {
                // Add empty line before bullet point (except the first one)
                formattedLines.append("")
            }
            formattedLines.append(line)
        }
        
        return formattedLines.joined(separator: "\n")
    }
    
    @State private var isEditingFavorites = false
    
    private var favoritesPageView: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Fav Logo - lowered by 5pt total from original position (3pt + 2pt)
                Image("Fav Logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 60) // 55 + 5 = 60pt (additional 2pt lower)
                    .padding(.bottom, -30) // Negative padding to reduce gap
                
                // Favorite title - much closer to logo
                Image("Favorite title")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.353) // Reduced to 2/3 of previous size (0.53 * 0.667)
                    .padding(.bottom, 0)
                
                // List of favorite entries with swipe-to-delete - 10pt below title
                if journalViewModel.favoriteJournalEntries.isEmpty {
                    // Show empty state message when no favorites exist
                    VStack {
                        Spacer()
                            .frame(height: 10) // Fixed height to raise text up 10pt
                        
                        Text("No favorite entries have been made yet..")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "545555"))
                            .opacity(0.7) // 70% opacity
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(journalViewModel.favoriteJournalEntries) { entry in
                            favoriteEntryView(entry: entry)
                                .listRowBackground(Color(hex: "E3E0C9"))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 7.5, leading: 8, bottom: 7.5, trailing: 8))
                        }
                        .onDelete { offsets in
                            Task {
                                await journalViewModel.deleteFavoriteEntries(at: offsets)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .environment(\.editMode, isEditingFavorites ? .constant(.active) : .constant(.inactive))
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color(hex: "E3E0C9"))
            
            // Edit Button positioned at top-right with functionality
            Button(action: {
                withAnimation {
                    isEditingFavorites.toggle()
                }
            }) {
                Text(isEditingFavorites ? "Done" : "Edit")
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "772C2C"))
            }
            .padding(.top, 60) // Same as logo top padding
            .padding(.trailing, 20)
        }
        .onAppear {
            Task {
                await journalViewModel.loadFavoriteEntries()
            }
        }
    }
    
    // MARK: - Favorite Entry View
    private func favoriteEntryView(entry: JournalEntry) -> some View {
        let isExpanded = expandedEntries.contains(entry.id)
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Date column - fixed width
                Text(formatDate(entry.createdAt))
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "772C2C"))
                    .frame(width: 80, alignment: .leading)
                
                // 3pt spacing
                Spacer()
                    .frame(width: 3)
                
                // Content column - takes remaining space
                VStack(alignment: .leading, spacing: 8) {
                    // Journal entry text
                    if isExpanded {
                        // Show full text
                        Text(entry.content)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "545555"))
                            .multilineTextAlignment(.leading)
                    } else {
                        // Show truncated text (max 3 lines)
                        Text(truncateText(entry.content, maxLines: 3))
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "545555"))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                    
                    // AI response text (only shown when expanded)
                    if isExpanded && !(entry.aiResponse?.isEmpty ?? true) {
                        Text(entry.aiResponse ?? "")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "772C2C"))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 5) // 5pt indent
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 8pt spacing before icon
                Spacer()
                    .frame(width: 8)
                
                // Icon - fixed position on right
                Button(action: {
                    if isExpanded {
                        expandedEntries.remove(entry.id)
                    } else {
                        expandedEntries.insert(entry.id)
                    }
                }) {
                    Image(isExpanded ? "Minus icon" : "Plus icon")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                }
                .frame(width: 17, alignment: .trailing)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
        }
        .background(Color(hex: "F5F4EB"))
        .cornerRadius(8)
    }
    
    // Helper function to format date as "Sept 2nd"
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let baseString = formatter.string(from: date)
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        let day = Int(dayFormatter.string(from: date)) ?? 1
        
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        return baseString + suffix
    }
    
    // Helper function to truncate text to max lines with "..."
    private func truncateText(_ text: String, maxLines: Int) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let approximateWordsPerLine = 8 // Rough estimate
        let maxWords = maxLines * approximateWordsPerLine
        
        if words.count > maxWords {
            let truncatedWords = Array(words.prefix(maxWords))
            return truncatedWords.joined(separator: " ") + "..."
        }
        return text
    }
    
    
    // Custom Tab Bar
    var customTabBar: some View {
        HStack {
            // Journal Tab
            Button(action: { selectedTab = 0 }) {
                Image(selectedTab == 0 ? "Journal Tab click" : "Journal Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity)
            
            // Centered Tab (now using Favorite Tab icons)
            Button(action: { selectedTab = 1 }) {
                Image(selectedTab == 1 ? "Fav Tab click" : "Fav Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity)
            
            // Favorites Tab (now using Centered Tab icons)
            Button(action: { selectedTab = 2 }) {
                ZStack(alignment: .topTrailing) {
                Image(selectedTab == 2 ? "Centered Tab click" : "Centered Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    
                    // Red dot indicator when Analyze button is enabled
                    if analyzerViewModel.isAnalyzeButtonEnabled {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 2, y: -2) // Position at top right
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Profile Tab
            Button(action: { selectedTab = 3 }) {
                Image(selectedTab == 3 ? "Profile Tab click" : "Profile Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, -5)
        .padding(.bottom, 22)
        .background(Color(hex: "E3E0C9"))
        .frame(height: 75) // Updated to 75pt height
    }
    
    // MARK: - Welcome Message
    
    private var welcomeMessageView: some View {
        OnboardingCarouselView {
                    dismissWelcomeMessage()
        }
    }
    
    private func checkAndShowWelcomeMessage() {
        // Get user-specific key to prevent data leakage between users
        let userId = journalViewModel.currentUser?.id.uuidString ?? "anonymous"
        let hasSeenWelcomeKey = "hasSeenWelcome_\(userId)"
        let hasSeenWelcome = UserDefaults.standard.bool(forKey: hasSeenWelcomeKey)
        if !hasSeenWelcome {
            showWelcomeMessage = true
        }
    }
    
    private func dismissWelcomeMessage() {
        showWelcomeMessage = false
        // Get user-specific key to prevent data leakage between users
        let userId = journalViewModel.currentUser?.id.uuidString ?? "anonymous"
        let hasSeenWelcomeKey = "hasSeenWelcome_\(userId)"
        UserDefaults.standard.set(true, forKey: hasSeenWelcomeKey)
    }
    
    private var infoPopupView: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showInfoPopup = false
                }
            
            // Simple popup content
            VStack(alignment: .leading, spacing: 8) {
                Text("Free write and Check In Questions")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• Share anything on your mind.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• Periodically, check in questions will ask about previous journal entries.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• After completing your entry, you can tap the \"Insight\" button to receive customized insights.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Check-in Reminder")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Whether you like to check in early in the morning or right before bed, you can set your own reminder times in the Notifications section of the User Settings page.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Tips")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("The more detail you share, the more helpful and accurate the AI insights will be.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("If you add your information (gender, occupation and birthdate) in the User Settings page (Here), the AI Insight will include this in its analysis and insights")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                    .onTapGesture {
                        showInfoPopup = false
                        selectedTab = 3 // Navigate to Profile tab
                        showSettingsFromPopup = true // Trigger settings sheet
                    }
                
                Text("New entries are available each morning. Swipe down to refresh")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
            }
            .padding(16)
            .background(Color(hex: "E3E0C9"))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
    
    private var q3InfoPopupView: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showQ3InfoPopup = false
                }
            
            // Simple popup content
            VStack(alignment: .leading, spacing: 8) {
                Text("Guided Questions")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• The guided question changes daily. The topics include gratitude, mindset, mental and physical health and other similar topics.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• These questions are designed to help you reflect on specific aspects of your life and well-being.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• After completing your entry, you have an option to tap the \"Insight\" button to receive customized AI insights.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• New questions are automatically refreshed at 2 AM every morning.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Tips")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("The more detail you share, the more helpful and accurate the AI insights will be.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("If yesterday's question/entry still appear, you can refresh by swiping down.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Check-in Reminder")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Whether you like to check in early in the morning or right before bed, you can set your own reminder times in the Notifications section of the User Settings page.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
            }
            .padding(16)
            .background(Color(hex: "E3E0C9"))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
    
    private var goalInfoPopupView: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showGoalInfoPopup = false
                }
            
            // Popup content
            VStack(spacing: 8) {
                Text("Goals")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("You can enter a personal goal in this field (e.g. 'less worried' or 'more patient'), and the AI will tailor its insights around it.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Since goals can change, you can update your goal anytime by clicking the refresh button and entering a new one.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(hex: "E3E0C9"))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
    
    private var q4InfoPopupView: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showQ4InfoPopup = false
                }
            
            // Popup content
            VStack(alignment: .leading, spacing: 8) {
                // Analyzer Section
                Text("Analyzer")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "8BECF8"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("• Tracks most common moods")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("• Calculates log entry statistics")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("• Generates a Faith Score - how mentally centered you are based on your log entries (0-100)")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("• Summarizes your week/month and provides actions and goals.")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Analysis Availability Section
                Text("Analysis Availability")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "8BECF8"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                
                Text("• Weekly analysis available every Sunday morning")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("• Monthly analysis available the Sunday after the month ends")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Analysis Entry Minimums Section
                Text("Analysis Entry Minimums")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "8BECF8"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                
                Text("• Weekly Analysis: 2 days of log entries / week")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("• Monthly Analysis: 9 days of log entries / month")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(hex: "772C2C"))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Loading Text Helper Function
    private func getLoadingText() -> String {
        if isLoadingGenerating || openIsLoadingGenerating {
            // Check retry attempt status
            switch journalViewModel.currentRetryAttempt {
            case 1:
                return "Generating..."
            case 2:
                return "Retrying..."
            case 3:
                return "Retrying again..."
            default:
                return "Generating..."
            }
        } else {
            return "Saving..."
        }
    }
}

// Color Extensions
extension Color {
    static let textBlue = Color(hex: "#772C2C")
    static let backgroundBeige = Color(hex: "#E3E0C9")
    static let textFieldBackground = Color(hex: "#F5F4EB")
    static let textGrey = Color(hex: "#545555")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Timeout Helper Function
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    var localizedDescription: String {
        return "Operation timed out after 30 seconds"
    }
}

#Preview {
    ContentView()
}
