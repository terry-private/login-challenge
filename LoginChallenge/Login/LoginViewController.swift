import UIKit
import SwiftUI

@MainActor
final class LoginViewController: UIViewController {
    @IBOutlet private var idField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    private var presenter: LoginInput?
    
    func inject(presenter: LoginInput) {
        self.presenter = presenter
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // VC を表示する前に View の状態のアップデートし、状態の不整合を防ぐ。
        toggleEnabled(to: true)
    }
    
    /// ログインボタンが押されたときにログイン処理を実行。
    @IBAction private func loginButtonPressed(_ sender: UIButton) {
        Task {
            await presenter?.loginButtonPressed(id: idField.text, password: passwordField.text)
        }
    }
    
    /// ID およびパスワードのテキストが変更されたときに View の状態を更新。
    @IBAction private func inputFieldValueChanged(sender: UITextField) {
        loginButton.isEnabled = canLogin
    }
}

private extension LoginViewController {
    /// loginButton が有効かどうか
    /// ID およびパスワードが空でない場合だけ有効。
    var canLogin: Bool {
        !(
            idField.text?.isEmpty ?? true ||
            passwordField.text?.isEmpty ?? true
        )
    }
    /// 画面が操作可能かどうか切り替える
    /// - Parameter isEnabled: 可能: true 不可能: false
    /// - loginButtonはisEnabled=trueでもcanLogin状態じゃない場合はfalse
    func toggleEnabled(to isEnabled: Bool) {
        // isEnabled = trueの子機はcanLoginかどうか、false の時は必ず無効
        loginButton.isEnabled = isEnabled ? canLogin : false
        idField.isEnabled = true
        passwordField.isEnabled = true
    }
}

extension LoginViewController: LoginOutput {
    /// Activity Indicator を表示。
    func showIndicator() async {
        toggleEnabled(to: false)
        let activityIndicatorViewController: ActivityIndicatorViewController = .init()
        activityIndicatorViewController.modalPresentationStyle = .overFullScreen
        activityIndicatorViewController.modalTransitionStyle = .crossDissolve
        await present(activityIndicatorViewController, animated: true)
    }
    /// Activity Indicator を非表示。
    func closeIndicator() async {
        await dismiss(animated: true)
        toggleEnabled(to: true)
    }
    /// HomeViewへ遷移(ログイン成功時処理)
    func transitionToHomeView() async {
        let destination = UIHostingController(rootView: HomeView(dismiss: { [weak self] in
            await self?.dismiss(animated: true)
        }))
        destination.modalPresentationStyle = .fullScreen
        destination.modalTransitionStyle = .flipHorizontal
        await present(destination, animated: true)
        // HomeViewController に遷移。
        //performSegue(withIdentifier: "Login", sender: nil)
        
        // この VC から遷移するのでボタンの押下受け付けは再開しない。
        // 遷移アニメーション中に処理が実行されることを防ぐ。
    }
    /// エラーアラート表示(ログイン失敗時処理)
    func showErrorAlert(title: String, message: String) async {
        let alertController: UIAlertController = .init(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
        await present(alertController, animated: true)
    }
}
