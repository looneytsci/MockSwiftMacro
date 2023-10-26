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

@available(macOS 13.0, *)
public struct MockMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let clock = ContinuousClock()
        var result: [DeclSyntax] = []
        let time = try! clock.measure {
            guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else { throw MockMacroError.appliedOnlyWithProtocols }
            
            let protocolName = protocolDecl.name.text.filter { $0 != " " }
            let mockClassName = "\(protocolName)Mock"
            
            let members = protocolDecl.memberBlock.members
                .compactMap { $0.as(MemberBlockItemSyntax.self) }
            let associatedType = members.compactMap { $0.decl.as(AssociatedTypeDeclSyntax.self)?.name }.first
            let functions = members
                .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            let variables = members
                .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            
            let typealiaseType = hasAssociatedType(node: node)
            let hasAssociatedType = associatedType != nil && typealiaseType != nil
            let functionsBlock = FunctionsBlockBuilder.makeFunctionsBlock(
                functions: functions,
                associatedType: associatedType,
                typealiaseType: typealiaseType
            )
            let variablesBlock = VariablesBlockBuilder.makeVariablesBlock(variables: variables)
            
            let mockBody = [variablesBlock.text, functionsBlock.text]
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")

            result = ["""
            
            \nfinal class \(raw: mockClassName): \(raw: protocolName) {
            \(raw: mockBody)
            }
            """]
        }
        
        let string = "\(time)"
        
        return result
    }

    private static func hasAssociatedType(node: AttributeSyntax) -> TokenSyntax? {
        if let associatedTypeArgument = node.arguments?.as(LabeledExprListSyntax.self)?.first,
           associatedTypeArgument.label == .identifier("associatedType"),
           let segments = associatedTypeArgument.expression.as(StringLiteralExprSyntax.self)?.segments,
           let value = segments.first?.as(StringSegmentSyntax.self)?.content,
           !value.text.isEmpty {
            return value
        }

        return nil
    }
}

@available(macOS 13.0, *)
@main
struct MacroLearningPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MockMacro.self
    ]
}
