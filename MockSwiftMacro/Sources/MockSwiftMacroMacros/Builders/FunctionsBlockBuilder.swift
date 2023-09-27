//
//  FunctionsBlockBuilder.swift
//
//
//  Created by Дмитрий Головин on 27.09.2023.
//

import SwiftSyntax

enum FunctionsBlockBuilder {
    // TODO: Добавить поддержку firstName secondName у имен параметров функций
    // TODO: Подумать что ретарнить Closure в функциях с возвращаемым значением
    // TODO: Проверить опционалы
    static func makeFunctionsBlock(functions: [FunctionDeclSyntax]) -> TokenSyntax {
        var functionBlocks: [String] = []
        
        functions.forEach { function in
            let funcName = function.name
            
            let parameterClause = function.signature.parameterClause
            let returnTypeName = function.signature.returnClause?.type.as(IdentifierTypeSyntax.self)?.name.text ?? ""
            
            let parameters = parameterClause.parameters
                .compactMap { $0.as(FunctionParameterSyntax.self) }
            let parametersInSignature = parameters
                .map { "\($0.firstName): \($0.type.as(IdentifierTypeSyntax.self)?.name ?? "")" }
                .joined(separator: ", ")
            let parameterTypes = parameters
                .map { "\($0.type.as(IdentifierTypeSyntax.self)?.name ?? "")" }
                .filter { $0 != "" }
                .joined(separator: ", ")
            let parameterNames = parameters
                .map { "\($0.firstName)" }
                .joined(separator: ", ")
            
            let hasReturnType = !returnTypeName.isEmpty
            let returnType = hasReturnType ? TokenSyntax(stringLiteral: [" -> ", returnTypeName].joined()) : ""
            let returnValueStroke = hasReturnType ? TokenSyntax(stringLiteral: "var \(funcName)ReturnValue: \(returnTypeName)!") : ""
            let returnValueCallingStroke = hasReturnType ? TokenSyntax(stringLiteral: "\nreturn \(funcName)ReturnValue") : ""
            let closureReturnType = hasReturnType ? returnTypeName : "Void"
            
            functionBlocks.append("""
            // MARK: - \(function.name)
            
            func \(funcName)(\(parametersInSignature))\(returnType) {
                \(funcName)CallsCount += 1
                _ = \(funcName)Closure?(\(parameterNames))\(returnValueCallingStroke)
            }
            var \(funcName)CallsCount = 0
            var \(funcName)Called: Bool {
                \(funcName)CallsCount > 0
            }
            var \(funcName)Closure: ((\(parameterTypes)) -> \(closureReturnType))?\(returnValueStroke)
            """)
        }
        
        return .init(stringLiteral: functionBlocks.joined(separator: "\n\n"))
    }
}
