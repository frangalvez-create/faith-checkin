import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var journalViewModel: JournalViewModel
    @State private var showDeleteAccountConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showDeleteSuccessAlert = false
    @State private var showDeleteErrorAlert = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        ZStack {
            Color(hex: "E4DCC9")
                .ignoresSafeArea(.all)
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Logo
                        Image("Profile Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .padding(.top, 20) // 20pt from top
                        
                        // Legal Info Title
                        Text("Legal Info")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "772C2C"))
                            .padding(.top, 25) // 25pt below logo
                        
                        // Legal Information Section
                        VStack(spacing: 20) {
                            // Disclaimer Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Disclaimer")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "772C2C"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 50) // 50pt below Legal Info text
                                
                                Text("The materials on the CenteredSelf application are provided \"as is.\" CenteredSelf makes no warranties or guarantees that the information is correct, complete, or up to date. We link to OpenAI for AI-related content and cannot guarantee the accuracy, reliability, or suitability of the AI responses. All outputs displayed come directly from OpenAI's language model and are not edited or altered by CenteredSelf.\n\nThe content provided in the app, including AI-generated suggestions, journaling prompts, and insights, is for informational and self-reflection purposes only. It is not a substitute for professional medical, psychological, or therapeutic advice, diagnosis, or treatment. Always seek the guidance of a qualified health professional with any questions you may have regarding your mental health, physical health, or well-being.\n\nBy using CenteredSelf, you acknowledge and agree that:\n• You use the app at your own discretion and risk.\n• CenteredSelf and its affiliates are not responsible or liable for any actions you take or decisions you make based on the information provided.\n• We do not guarantee that the app will be error-free, uninterrupted, or free of harmful components.\n• Links to third-party services or resources are provided for convenience and do not imply endorsement.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below Disclaimer text
                            }
                            
                            // Terms of Use Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Terms of Use")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "772C2C"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below first chunk
                                
                                Text("By downloading, accessing, or using the CenteredSelf application (\"App\"), you agree to the following Terms of Use (\"Terms\"). Please read them carefully. If you do not agree, you may not use the App.\n\nPurpose of the App - CenteredSelf is a journaling and self-reflection tool that provides prompts, insights, and AI-generated content. The App is for personal use only and is not intended to provide medical, psychological, or therapeutic advice.\n\nEligibility - You must be at least 13 years old (or the minimum legal age in your country) to use the App. By using the App, you confirm that you meet these requirements.\n\nUser Responsibilities - You agree to use the App only for lawful and personal purposes. You are responsible for the content you create, upload, or store within the App. You may not misuse the App, attempt to disrupt its operation, or use it to harm others.\n\nAI-Generated Content - The App integrates with OpenAI to provide AI-generated insights. CenteredSelf does not control or guarantee the accuracy, reliability, or suitability of this content. All AI outputs are for informational purposes only and should not be relied upon as professional advice.\n\nPrivacy - Your privacy is important to us. Please review our Privacy Policy [link to policy] to understand how we collect, use, and protect your data.\n\nIntellectual Property - All content, design, and materials within the App (except user-generated entries) are the property of CenteredSelf or its licensors. You may not copy, distribute, or use them without permission.\n\nDisclaimers - The App is provided on an \"as is\" and \"as available\" basis. CenteredSelf makes no warranties or guarantees regarding the App's availability, reliability, or accuracy. The App does not replace professional medical, mental health, or legal advice.\n\nLimitation of Liability - To the maximum extent permitted by law, CenteredSelf and its affiliates will not be liable for any direct, indirect, incidental, or consequential damages resulting from your use of the App.\n\nTermination - We may suspend or terminate your access to the App at any time, without notice, if you violate these Terms or misuse the App.\n\nChanges of These Terms - We may update these Terms from time to time. Continued use of the App after changes are posted means you accept the revised Terms.\n\nGoverning Law - These Terms are governed by the laws of California, USA. Any disputes will be handled in the local courts.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below Terms of Use text
                            }
                            
                            // Privacy Policy Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Privacy Policy")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "772C2C"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below second chunk
                                
                                Text("At CenteredSelf, your privacy matters to us. This Privacy Policy explains how we collect, use, and protect your information when you use the CenteredSelf application (\"App\").\n\nInformation We Collect - 1) Journal Entries: Any content you choose to write and store in the App. 2) Account Information (if applicable): Such as your email, name, or preferences. 3) Usage Data: Non-identifiable information like device type, app activity, and performance logs to help us improve the App. We do not sell or share your personal journal entries with advertisers.\n\nHow We Use Your Information - Provide journaling features and insights. Deliver AI-generated suggestions and prompts (via OpenAI). Improve and maintain the App. Communicate with you about updates, features, or important notices.\n\nAI-Generated Content - The App connects to OpenAI to provide journaling prompts and insights. When you submit text for AI processing, it is transmitted to OpenAI's servers. CenteredSelf does not control or guarantee how OpenAI processes or stores this data—please review OpenAI's Privacy Policy for more information.\n\nData Storage and Security - Your journal entries are stored securely and are accessible only to you. We use reasonable security measures to protect your data, but no system is 100% secure. We cannot guarantee absolute protection.\n\nSharing of Information - We do not share, sell, or rent your personal information to third parties. Information may be shared only in the following cases: 1) With service providers who help us operate the App (e.g., cloud hosting). 2) If required by law or to protect the safety of users or the public.\n\nChildren's Privacy - CenteredSelf is not directed at children under 13 (or the minimum legal age in your country). We do not knowingly collect personal information from children.\n\nChanges to This Policy - We may update this Privacy Policy from time to time. We will notify you of material changes by posting the new version in the App. Continued use of the App means you accept the updated policy.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below Privacy Policy text
                                
                            }
                            
                            // Delete Account Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Delete account")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "772C2C"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below Privacy Policy section
                                
                                Text("If you no longer wish to keep your account with this app, you can delete your journal entries, user profiles and associated data at any time by simply clicking below.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below Delete account text
                                
                                // Delete Account Button
                                GeometryReader { geometry in
                                    Button(action: {
                                        showDeleteAccountConfirmation = true
                                    }) {
                                        Text("Delete Account")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red)
                                            .frame(width: geometry.size.width * 0.5) // 50% of screen width
                                            .padding(.vertical, 6) // Half the previous height (12pt -> 6pt)
                                            .background(Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.red, lineWidth: 1)
                                            )
                                    }
                                    .frame(maxWidth: .infinity) // Center the button
                                }
                                .frame(height: 40) // Fixed height for GeometryReader
                                .padding(.top, 15) // 15pt below description text
                            }
                        }
                        .frame(maxWidth: .infinity) // Expand to full width
                        .padding(.horizontal, 0) // Remove horizontal padding
                        .background(Color(hex: "E4DCC9")) // Background for main content
                    }
                    .frame(maxWidth: .infinity) // Expand main VStack to full width
                    .padding(.horizontal, 0) // Remove horizontal padding from main VStack
                }
                .frame(maxWidth: .infinity) // Expand ScrollView to full width
                .background(Color(hex: "E4DCC9")) // Background for ScrollView
                .navigationBarHidden(true)
            }
            .frame(maxWidth: .infinity) // Expand NavigationView to full width
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete Account", role: .destructive) {
                Task {
                    await deleteUserAccount()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Account Deleted", isPresented: $showDeleteSuccessAlert) {
            Button("OK") {
                // Navigate back to login screen will be handled by the ViewModel
            }
        } message: {
            Text("Your account and all associated data have been successfully deleted.")
        }
        .alert("Delete Failed", isPresented: $showDeleteErrorAlert) {
            Button("OK") { }
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    private func deleteUserAccount() async {
        isDeletingAccount = true
        
        do {
            // Call the delete account function from SupabaseService
            let success = try await journalViewModel.supabaseService.deleteUserAccount()
            
            if success {
                // Show success alert
                showDeleteSuccessAlert = true
                // Sign out user
                await journalViewModel.signOut()
            } else {
                // Show error alert
                deleteErrorMessage = "Failed to delete account. Please try again."
                showDeleteErrorAlert = true
            }
        } catch {
            // Show error alert
            deleteErrorMessage = "An error occurred while deleting your account. Please try again."
            showDeleteErrorAlert = true
        }
        
        isDeletingAccount = false
    }
}

#Preview {
    InfoView()
}
