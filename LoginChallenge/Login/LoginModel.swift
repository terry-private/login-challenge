//
//  LoginModel.swift
//  LoginChallenge
//
//  Created by 若江照仁 on 2022/01/22.
//

import APIServices
import Logging

protocol LoginModelProtocol {
    func logInWith(id: String, password: String) async throws
}

actor LoginModel: LoginModelProtocol {
    // String(reflecting:) はモジュール名付きの型名を取得するため。
    private let logger: Logger = .init(label: String(reflecting: LoginViewController.self))
    func logInWith(id: String, password: String) async throws {
        do {
            try await AuthService.logInWith(id: id, password: password)
        } catch {
            logger.info("\(error)")
            throw error
        }
    }
}
