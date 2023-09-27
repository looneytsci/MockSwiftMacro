//
//  MockMacroTests.swift
//
//
//  Created by Дмитрий Головин on 25.09.2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

final class MockMacroTests: XCTestCase {
    func testMockMacro_funcWithOptionalParameter() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService {
                func doWork(arg: String?)
            }
            """,
            expandedSource:
            """
            protocol IService {
                func doWork(arg: String?)
            }
            
            final class IServiceMock: IService {
                // MARK: - doWork
            
                func doWork(arg: String?) {
                    doWorkCallsCount += 1
                    _ = doWorkClosure?(arg)
                }
                var doWorkCallsCount = 0
                var doWorkCalled: Bool {
                    doWorkCallsCount > 0
                }
                var doWorkClosure: ((String?) -> Void)?
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_funcWithOptionalReturnValue() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService {
                func doWork() -> String?
            }
            """,
            expandedSource:
            """
            protocol IService {
                func doWork() -> String?
            }
            
            final class IServiceMock: IService {
                // MARK: - doWork
            
                func doWork() -> String? {
                    doWorkCallsCount += 1
                    _ = doWorkClosure?()
                    return doWorkReturnValue
                }
                var doWorkCallsCount = 0
                var doWorkCalled: Bool {
                    doWorkCallsCount > 0
                }
                var doWorkClosure: (() -> String?)?
                var doWorkReturnValue: String?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_variablesWithFunctions() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService {
                var worker: String { get set }
                var optionalWorker: String? { get set }
                var forceUnwrappedWorker: String! { get set }
            
                func doWork()
                func doWorkWithArgs(string: String, arg2: Bool)
                func doWorkWithReturnValue() -> String
                func doWorkWithArgsAndReturnValue(string: String) -> String
            }
            """,
            expandedSource:
            """
            protocol IService {
                var worker: String { get set }
                var optionalWorker: String? { get set }
                var forceUnwrappedWorker: String! { get set }
            
                func doWork()
                func doWorkWithArgs(string: String, arg2: Bool)
                func doWorkWithReturnValue() -> String
                func doWorkWithArgsAndReturnValue(string: String) -> String
            }
            
            final class IServiceMock: IService {
                // MARK: - worker
            
                var worker: String {
                    get {
                        return underlyingWorker
                    }
                    set(value) {
                        underlyingWorker = value
                    }
                }
                var underlyingWorker: String!
            
                // MARK: - optionalWorker
            
                var optionalWorker: String?
            
                // MARK: - forceUnwrappedWorker
            
                var forceUnwrappedWorker: String!
            
                // MARK: - doWork
            
                func doWork() {
                    doWorkCallsCount += 1
                    _ = doWorkClosure?()
                }
                var doWorkCallsCount = 0
                var doWorkCalled: Bool {
                    doWorkCallsCount > 0
                }
                var doWorkClosure: (() -> Void)?
            
                // MARK: - doWorkWithArgs
            
                func doWorkWithArgs(string: String, arg2: Bool) {
                    doWorkWithArgsCallsCount += 1
                    _ = doWorkWithArgsClosure?(string, arg2)
                }
                var doWorkWithArgsCallsCount = 0
                var doWorkWithArgsCalled: Bool {
                    doWorkWithArgsCallsCount > 0
                }
                var doWorkWithArgsClosure: ((String, Bool) -> Void)?
            
                // MARK: - doWorkWithReturnValue
            
                func doWorkWithReturnValue() -> String {
                    doWorkWithReturnValueCallsCount += 1
                    _ = doWorkWithReturnValueClosure?()
                    return doWorkWithReturnValueReturnValue
                }
                var doWorkWithReturnValueCallsCount = 0
                var doWorkWithReturnValueCalled: Bool {
                    doWorkWithReturnValueCallsCount > 0
                }
                var doWorkWithReturnValueClosure: (() -> String)?
                var doWorkWithReturnValueReturnValue: String!
            
                // MARK: - doWorkWithArgsAndReturnValue
            
                func doWorkWithArgsAndReturnValue(string: String) -> String {
                    doWorkWithArgsAndReturnValueCallsCount += 1
                    _ = doWorkWithArgsAndReturnValueClosure?(string)
                    return doWorkWithArgsAndReturnValueReturnValue
                }
                var doWorkWithArgsAndReturnValueCallsCount = 0
                var doWorkWithArgsAndReturnValueCalled: Bool {
                    doWorkWithArgsAndReturnValueCallsCount > 0
                }
                var doWorkWithArgsAndReturnValueClosure: ((String) -> String)?
                var doWorkWithArgsAndReturnValueReturnValue: String!
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_variable() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                var worker: String { get set }
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                var worker: String { get set }
            }
            
            final class IServiceMock: IService {
                // MARK: - worker
            
                var worker: String {
                    get {
                        return underlyingWorker
                    }
                    set(value) {
                        underlyingWorker = value
                    }
                }
                var underlyingWorker: String!
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_optionalVariable() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                var worker: String? { get set }
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                var worker: String? { get set }
            }
            
            final class IServiceMock: IService {
                // MARK: - worker
            
                var worker: String?
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_implicitlyUnwrappedOptionalVariable() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                var worker: String! { get set }
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                var worker: String! { get set }
            }
            
            final class IServiceMock: IService {
                // MARK: - worker
            
                var worker: String!
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_function() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWork()
            }
            """,
            expandedSource: """
            protocol IService: AnyObject {
                func doWork()
            }
            
            final class IServiceMock: IService {
                // MARK: - doWork
            
                func doWork() {
                    doWorkCallsCount += 1
                    _ = doWorkClosure?()
                }
                var doWorkCallsCount = 0
                var doWorkCalled: Bool {
                    doWorkCallsCount > 0
                }
                var doWorkClosure: (() -> Void)?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_functionWithArgs() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWorkWithArgs(string: String, arg2: Bool)
            }
            """,
            expandedSource: """
            protocol IService: AnyObject {
                func doWorkWithArgs(string: String, arg2: Bool)
            }
            
            final class IServiceMock: IService {
                // MARK: - doWorkWithArgs
            
                func doWorkWithArgs(string: String, arg2: Bool) {
                    doWorkWithArgsCallsCount += 1
                    _ = doWorkWithArgsClosure?(string, arg2)
                }
                var doWorkWithArgsCallsCount = 0
                var doWorkWithArgsCalled: Bool {
                    doWorkWithArgsCallsCount > 0
                }
                var doWorkWithArgsClosure: ((String, Bool) -> Void)?
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_functionWithReturnValue() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWorkWithReturnValue() -> String
            }
            """,
            expandedSource: """
            protocol IService: AnyObject {
                func doWorkWithReturnValue() -> String
            }
            
            final class IServiceMock: IService {
                // MARK: - doWorkWithReturnValue
            
                func doWorkWithReturnValue() -> String {
                    doWorkWithReturnValueCallsCount += 1
                    _ = doWorkWithReturnValueClosure?()
                    return doWorkWithReturnValueReturnValue
                }
                var doWorkWithReturnValueCallsCount = 0
                var doWorkWithReturnValueCalled: Bool {
                    doWorkWithReturnValueCallsCount > 0
                }
                var doWorkWithReturnValueClosure: (() -> String)?
                var doWorkWithReturnValueReturnValue: String!
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_functionWithArgsAndReturnValue() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWorkWithArgsAndReturnValue(string: String) -> String
            }
            """,
            expandedSource: """
            protocol IService: AnyObject {
                func doWorkWithArgsAndReturnValue(string: String) -> String
            }
            
            final class IServiceMock: IService {
                // MARK: - doWorkWithArgsAndReturnValue
            
                func doWorkWithArgsAndReturnValue(string: String) -> String {
                    doWorkWithArgsAndReturnValueCallsCount += 1
                    _ = doWorkWithArgsAndReturnValueClosure?(string)
                    return doWorkWithArgsAndReturnValueReturnValue
                }
                var doWorkWithArgsAndReturnValueCallsCount = 0
                var doWorkWithArgsAndReturnValueCalled: Bool {
                    doWorkWithArgsAndReturnValueCallsCount > 0
                }
                var doWorkWithArgsAndReturnValueClosure: ((String) -> String)?
                var doWorkWithArgsAndReturnValueReturnValue: String!
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_whenAppliedNotToProtocol() {
        assertMacroExpansion(
            """
            @Mock
            class Service: IService {
                func doWork() {}
            }
            """,
            expandedSource: """
            class Service: IService {
                func doWork() {}
            }
            """,
            diagnostics: [.init(message: "@Mock должен быть использован только с протоколами.", line: 1, column: 1)],
            macros: testMacros
        )
    }
}
