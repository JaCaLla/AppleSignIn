//
//  ContentView.swift
//  AppleSignInApp
//
//  Created by JAVIER CALATRAVA LLAVERIA on 27/4/25.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @State private var userID: String?
    @State private var userEmail: String?
    @State private var userName: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if let userID = userID {
                Text("Welcome 🎉")
                    .font(.title)
                Text("User ID: \(userID)")
                if let name = userName {
                    Text("Name: \(name)")
                }
                if let email = userEmail {
                    Text("Email: \(email)")
                }
            } else {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            handleAuthorization(authorization)
                        case .failure(let error):
                            print("Authentication error: \(error.localizedDescription)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(width: 280, height: 50)
                .cornerRadius(8)
                .padding()
            }
        }
        .padding()
    }
    
    private func handleAuthorization(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            userID = appleIDCredential.user
            userEmail = appleIDCredential.email
            if let fullName = appleIDCredential.fullName {
                userName = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }
            
            if let identityToken = appleIDCredential.identityToken,
               let tokenString = String(data: identityToken, encoding: .utf8) {
                authenticateWithServer(identityToken: tokenString)
            }
        }
    }
    
    private func authenticateWithServer(identityToken: String) {
        guard let url = URL(string: "http://localhost:3000/auth/apple") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["identityToken": identityToken]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) {
                print("Server response:", json)
            } else {
                print("Error communicating with server:", error?.localizedDescription ?? "Unknown error")
            }
        }.resume()
    }
}


#Preview {
    ContentView()
}
