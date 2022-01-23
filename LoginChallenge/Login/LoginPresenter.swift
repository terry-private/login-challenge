//
//  LoginPresenter.swift
//  LoginChallenge
//
//  Created by 若江照仁 on 2022/01/22.
//

import APIServices
import Entities



protocol LoginInput {
    var view: LoginOutput? { get set }
    func loginButtonPressed(id: String?, password: String?) async
}

protocol LoginOutput: AnyObject {
    func showIndicator() async
    func closeIndicator() async
    func transitionToHomeView() async
    func showErrorAlert(title: String, message: String) async
}

final class LoginPresenter {
    internal weak var view: LoginOutput?
    var model: LoginModelProtocol
    init(view: LoginOutput, model: LoginModelProtocol) {
        self.view = view
        self.model = model
    }
}

extension LoginPresenter: LoginInput {
    func loginButtonPressed(id: String?, password: String?) async{
        guard
            let view = view,
            let id = id,
            let password = password else {
                return
            }
        await view.showIndicator()
        do {
            try await model.logInWith(id: id, password: password)
            await view.closeIndicator()
            await view.transitionToHomeView()
        } catch _ as LoginError {
            await view.closeIndicator()
            await view.showErrorAlert(
                title: "ログインエラー",
                message: "IDまたはパスワードが正しくありません。"
            )
        } catch _ as NetworkError {
            await view.closeIndicator()
            await view.showErrorAlert(
                title: "ネットワークエラー",
                message: "通信に失敗しました。ネットワークの状態を確認して下さい。"
            )
        } catch _ as ServerError {
            await view.closeIndicator()
            await view.showErrorAlert(
                title: "サーバーエラー",
                message: "しばらくしてからもう一度お試し下さい。"
            )
        } catch {
            await view.closeIndicator()
            await view.showErrorAlert(
                title: "システムエラー",
                message: "エラーが発生しました。"
            )
        }
    }
}
