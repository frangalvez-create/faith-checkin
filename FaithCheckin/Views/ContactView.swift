import SwiftUI

struct ContactView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                        
                        // Contact Title
                        Text("Contact")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "772C2C"))
                            .padding(.top, 25) // 25pt below logo
                        
                        // Contact Information Section
                        VStack(spacing: 10) {
                            // Email Section
                            Text("Email")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "772C2C"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 25) // 25pt left padding
                                .padding(.top, 60) // 60pt below Contact text
                            
                            Text("centeredselfapp@gmail.com")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "772C2C"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 25) // 25pt from left edge
                                .padding(.top, 10) // 10pt below Email text
                            
                            // Website Section
                            Text("Website")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "772C2C"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 25) // 25pt left padding
                                .padding(.top, 40) // 40pt below email text
                            
                            Text("centeredselfapp.com")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "772C2C"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 25) // 25pt from left edge
                                .padding(.top, 10) // 10pt below Website text
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
    }
}

#Preview {
    ContactView()
}
