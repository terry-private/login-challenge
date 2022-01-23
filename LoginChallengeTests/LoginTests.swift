//
//  LoginTests.swift
//  LoginChallengeTests
//
//  Created by 若江照仁 on 2022/01/23.
//

import XCTest
@testable import Entities
@testable import LoginChallenge

// MARK: - ログインテスト用のモック置き場
private final class LoginModelMock: LoginModelProtocol {
    private var loginCallBack: (() async throws -> Void)?
    func logInWith(id: String, password: String) async throws {
        do {
            try await Task.sleep(nanoseconds: 100_000_000)
            try await loginCallBack?()
        } catch {
            throw error
        }
    }
    init(loginCallBack: (() async throws -> Void)? = nil) {
        self.loginCallBack = loginCallBack
    }
}

private final class LoginViewMock: LoginOutput {
    var id: String? = "koher"
    var password: String? = "1234"
    var presenter: LoginInput?
    // テスト結果確認用のプロパティ
    var showIndicatorAt: Date?
    var closeIndicatorAt: Date?
    var transitionToHomeViewAt: Date?
    var showErrorAlertAt: Date?
    var errorTitle: String?
    var errorMessage: String?
    
    func showIndicator() async { showIndicatorAt = Date() }
    func closeIndicator() async { closeIndicatorAt = Date() }
    func transitionToHomeView() async { transitionToHomeViewAt = Date() }
    func showErrorAlert(title: String, message: String) async {
        errorTitle = title
        errorMessage = message
        showErrorAlertAt = Date()
    }
}

// MARK: - ログインテスト
class LoginTests: XCTestCase {
    func testLoginPresenter_loginWithメソッドの動作テスト() {
        // MARK: 成功時のテスト
        runAsyncActivity(name: "ログイン成功時のテスト") {
            let model = LoginModelMock()
            let view = LoginViewMock()
            let presenter = LoginPresenter(view: view, model: model)
            await presenter.loginButtonPressed(id: view.id, password: view.password)
            // アンラップしながらnilチェック
            //「インジケータ表示」「非表示」「アラート表示」が実行されたかどうかの確認もしている。
            let showIndicatorAt = try XCTUnwrap(view.showIndicatorAt)
            let closeIndicatorAt = try XCTUnwrap(view.closeIndicatorAt)
            let transitionToHomeViewAt = try XCTUnwrap(view.transitionToHomeViewAt)
            // 「インジケータ表示」⇨「非表示」⇨「アラート表示」の順になっているかどうか"
            XCTAssertLessThan(showIndicatorAt, closeIndicatorAt)
            XCTAssertLessThan(closeIndicatorAt, transitionToHomeViewAt)
        }
        // MARK: エラー時のテスト
        /// エラー時に必須のメソッドをcallしているか、順番通りか、エラーアラートの文言は正しいかどうか
        /// - Parameters:
        ///   - error: T: Error このエラーをthrowするmodelを作成
        ///   - title: String エラータイトル
        ///   - message: String エラーメッセージ
        func testErrorAlert<T: Error>(error: T, title: String, message: String) async throws {
            // 必ず引数のerrorをthrowするmodelを作成
            let model = LoginModelMock() {
                throw error
            }
            let view = LoginViewMock()
            let presenter = LoginPresenter(view: view, model: model)
            await presenter.loginButtonPressed(id: view.id, password: view.password)
            // アンラップしながらnilチェック
            //「インジケータ表示」「非表示」「アラート表示」が実行されたかどうかの確認もしている。
            let showIndicatorAt = try XCTUnwrap(view.showIndicatorAt)
            let closeIndicatorAt = try XCTUnwrap(view.closeIndicatorAt)
            let showErrorAlertAt = try XCTUnwrap(view.showErrorAlertAt)
            // 「インジケータ表示」⇨「非表示」⇨「アラート表示」の順になっているかどうか"
            XCTAssertLessThan(showIndicatorAt, closeIndicatorAt)
            XCTAssertLessThan(closeIndicatorAt, showErrorAlertAt)
            // エラーアラートの内容が合っているかどうか
            XCTAssertEqual(view.errorTitle, title)
            XCTAssertEqual(view.errorMessage, message)
        }
        runAsyncActivity(name: "LoginError時のテスト") {
            try await testErrorAlert(error: LoginError(), title: "ログインエラー", message: "IDまたはパスワードが正しくありません。")
        }
        runAsyncActivity(name: "NetworkError時のテスト") {
            try await testErrorAlert(error: NetworkError(cause: GeneralError(message: "Timeout.")), title: "ネットワークエラー", message: "通信に失敗しました。ネットワークの状態を確認して下さい。")
        }
        runAsyncActivity(name: "ServerError時のテスト") {
            try await testErrorAlert(error: ServerError.internal(cause: GeneralError(message: "Rate limit exceeded.")), title: "サーバーエラー", message: "しばらくしてからもう一度お試し下さい。")
        }
        runAsyncActivity(name: "ServerError時のテスト") {
            try await testErrorAlert(error: GeneralError(message: "System error."), title: "システムエラー", message: "エラーが発生しました。")
        }
    }
}

