//
//  AuthUIView.swift
//  TeaElephant
//
//  Created by Andrew Khasanov on 13/08/2023.
//

import SwiftUI
import AuthenticationServices

struct AuthUIView: View {
    var body: some View {
        SignInWithAppleButton(onRequest: { request in
            request.requestedScopes = [.fullName]
        }, onCompletion: { response in
            switch response {
            case .success(let authResults):
                guard let credentials = authResults.credential as? ASAuthorizationAppleIDCredential, let code = credentials.authorizationCode, let codeString = String(data: code, encoding: .utf8) else { return }
                Task {
                    await AuthManager.shared.Auth(codeString)
                }
            case .failure(let error):
                print("complete error \(error.localizedDescription)")
            }
        })
    }
}

struct AuthUIView_Previews: PreviewProvider {
    static var previews: some View {
        AuthUIView()
    }
}
