//
//  MockMacro.swift
//
//
//  Created by Дмитрий Головин on 25.09.2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftCompilerPlugin

enum MockMacroError: CustomStringConvertible, Error {
    case appliedOnlyWithProtocols
    
    var description: String {
        switch self {
        case .appliedOnlyWithProtocols:
            return "@Mock должен быть использован только с протоколами."
        }
    }
}

/// UserDefaultsFacadeMock
public struct MockMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else { throw MockMacroError.appliedOnlyWithProtocols }
        
        let protocolName = protocolDecl.name.text.filter { $0 != " " }
        let mockClassName = "\(protocolName)Mock"
        
        let members = protocolDecl.memberBlock.members
            .compactMap { $0.as(MemberBlockItemSyntax.self) }
        let functions = members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
        let variables = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
        
        let functionsBlock = FunctionsBlockBuilder.makeFunctionsBlock(functions: functions)
        let variablesBlock = VariablesBlockBuilder.makeVariablesBlock(variables: variables)
        
        let mockBody = [variablesBlock.text, functionsBlock.text]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        
        return ["""
        \nfinal class \(raw: mockClassName): \(protocolDecl.name) {
        \(raw: mockBody)
        }
        """]
        
    }
}

@main
struct MacroLearningPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MockMacro.self
    ]
}
