//
//  LoginModel.swift
//  LoginChallenge
//
//  Created by 若江照仁 on 2022/01/22.
//

import APIServices

protocol LoginModelProtocol {
    func logInWith(id: String, password: String) async throws
}

actor LoginModel: LoginModelProtocol {
    func logInWith(id: String, password: String) async throws {
        do {
            try await AuthService.logInWith(id: id, password: password)
        } catch {
            throw error
        }
    }
}
