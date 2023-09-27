//
//  FunctionsBlockBuilder.swift
//
//
//  Created by Дмитрий Головин on 27.09.2023.
//

import SwiftSyntax

fileprivate struct FunctionArgumentType {
    let typeSyntax: TokenSyntax
    let isOptional: Bool

    var postfixMark: String {
        isOptional ? "?" : ""
    }
    var typeName: String {
        typeSyntax.text + postfixMark
    }
}

enum FunctionsBlockBuilder {
    // TODO: Добавить поддержку firstName secondName у имен параметров функций
    // TODO: Подумать что ретарнить Closure в функциях с возвращаемым значением
    // TODO: Проверить опционалы
    static func makeFunctionsBlock(functions: [FunctionDeclSyntax]) -> TokenSyntax {
        var functionBlocks: [String] = []
        
        functions.forEach { function in
            let funcName = function.name
            
            let parameterClause = function.signature.parameterClause
            let returnType = makeReturnType(returnClause: function.signature.returnClause)
            
            let parameters = parameterClause.parameters
                .compactMap { $0.as(FunctionParameterSyntax.self) }
            let parametersInSignature = parameters
                .map { "\($0.firstName): \(makeParameterType(parameter: $0)?.typeName ?? "")" }
                .joined(separator: ", ")
            let parameterTypes = parameters
                .compactMap { makeParameterType(parameter: $0)?.typeName }
                .filter { $0 != "" }
                .joined(separator: ", ")
            let parameterNames = parameters
                .map { "\($0.firstName)" }
                .joined(separator: ", ")
            
            let hasReturnType = returnType != nil
            let returnTypeName = returnType?.typeName ?? ""
            let returnTypeSyntax = hasReturnType ? TokenSyntax(stringLiteral: [" -> ", returnTypeName].joined()) : ""
            let returnValuePostfix = (returnType?.isOptional ?? false) ? "" : "!"
            let returnTypeWithPostfix = returnTypeName + returnValuePostfix
            let returnValueStroke = hasReturnType ? TokenSyntax(stringLiteral: "var \(funcName)ReturnValue: \(returnTypeWithPostfix)") : ""
            let returnValueCallingStroke = hasReturnType ? TokenSyntax(stringLiteral: "\nreturn \(funcName)ReturnValue") : ""
            let closureReturnType = hasReturnType ? returnTypeName : "Void"
            
            functionBlocks.append("""
            // MARK: - \(function.name)
            
            func \(funcName)(\(parametersInSignature))\(returnTypeSyntax) {
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

    private static func makeReturnType(returnClause: ReturnClauseSyntax?) -> FunctionArgumentType? {
        if let type = returnClause?.type.as(OptionalTypeSyntax.self),
           let name = type.wrappedType.as(IdentifierTypeSyntax.self)?.name {
            return .init(typeSyntax: name, isOptional: true)
        } else if let type = returnClause?.type.as(IdentifierTypeSyntax.self)?.name {
            return .init(typeSyntax: type, isOptional: false)
        }

        return nil
    }

    private static func makeParameterType(parameter: FunctionParameterSyntax) -> FunctionArgumentType? {
        if let type = parameter.type.as(OptionalTypeSyntax.self),
           let name = type.wrappedType.as(IdentifierTypeSyntax.self)?.name {
            return .init(typeSyntax: name, isOptional: true)
        } else if let type = parameter.type.as(IdentifierTypeSyntax.self)?.name {
            return .init(typeSyntax: type, isOptional: false)
        }

        return nil
    }
}
