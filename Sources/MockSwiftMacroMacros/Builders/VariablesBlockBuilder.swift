//
//  VariablesBlockBuilder.swift
//
//
//  Created by Дмитрий Головин on 27.09.2023.
//

import SwiftSyntax

fileprivate struct VarTypeName {
    enum VarType {
        case nonOptional
        case optional
        case forceUnwrappedOptional
    }

    let typeName: TokenSyntax
    private let optionalType: VarType
    
    var optionalMark: String {
        switch optionalType {
        case .nonOptional:
            return ""
        case .optional:
            return "?"
        case .forceUnwrappedOptional:
            return "!"
        }
    }
    
    var isOptional: Bool {
        optionalType != .nonOptional
    }
    
    init(typeName: TokenSyntax, optionalType: VarType) {
        self.typeName = typeName
        self.optionalType = optionalType
    }
}

enum VariablesBlockBuilder {
    static func makeVariablesBlock(variables: [VariableDeclSyntax]) -> TokenSyntax {
        var variableBlocks: [String] = []
        
        variables.forEach { variable in
            guard let binding = variable.bindings.first,
                  let varType = makeVarType(binding: binding) else { return }

            let varName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier ?? ""
            
            var underlyingValueStrokes = ""
            
            if !varType.isOptional {
                let undelyingVarName = "underlying\(varName.text.capitalized)"
                
                underlyingValueStrokes = """
                get {
                    return \(undelyingVarName)
                }
                set(value) {
                    \(undelyingVarName) = value
                }
                }
                var \(undelyingVarName): \(varType.typeName.text + "!")
                """
            }
            
            variableBlocks.append("""
            // MARK: - \(varName)
            
            var \(varName): \(varType.typeName)\(varType.isOptional ? "" : "{")
            """.appending(varType.isOptional ? "" : underlyingValueStrokes))
        }
        
        return .init(stringLiteral: variableBlocks.joined(separator: "\n\n"))
    }

    private static func makeVarType(binding: PatternBindingSyntax) -> VarTypeName? {
        let type = binding.typeAnnotation?.type
        if let nonOptionalType = type?.as(IdentifierTypeSyntax.self)?.name {
            return .init(typeName: nonOptionalType, optionalType: .nonOptional)
        } else if let optionalType = type?.as(OptionalTypeSyntax.self),
                  let typeName = optionalType.wrappedType.as(IdentifierTypeSyntax.self)?.name {
            return .init(typeName: .init(stringLiteral: typeName.text + "?"), optionalType: .optional)
        } else if let implicitlyUnwrappedOptional = type?.as(ImplicitlyUnwrappedOptionalTypeSyntax.self),
                  let typeName = implicitlyUnwrappedOptional.wrappedType.as(IdentifierTypeSyntax.self)?.name {
            return .init(typeName: .init(stringLiteral: typeName.text + "!"), optionalType: .forceUnwrappedOptional)
        }
        
        return nil
    }
}
