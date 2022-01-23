//
//  XCTest+async.swift
//  LoginChallengeTests
//
//  Created by 若江照仁 on 2022/01/23.
//

import XCTest

extension XCTestCase {
    // 参考記事
    // https://www.swiftbysundell.com/articles/unit-testing-code-that-uses-async-await/
    func runAsyncTest(
        named testName: String = #function,
        in file: StaticString = #file,
        at line: UInt = #line,
        withTimeout timeout: TimeInterval = 10,
        test: @escaping () async throws -> Void
    ) {
        var thrownError: Error?
        let errorHandler = { thrownError = $0 }
        let expectation = expectation(description: testName)

        Task {
            do {
                try await test()
            } catch {
                errorHandler(error)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        if let error = thrownError {
            XCTFail(
                "Async error thrown: \(error)",
                file: file,
                line: line
            )
        }
    }
    
    /// async func を利用するテストでrunActivityを使うためのメソッド
    func runAsyncActivity(name: String, test: @escaping () async throws -> Void) {
        XCTContext.runActivity(named: name){ _ in
            runAsyncTest {
                do {
                    try await test()
                } catch {
                    throw error
                }
            }
        }
    }
}
