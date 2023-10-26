@attached(peer, names: suffixed(Mock))
public macro Mock(associatedType: String = "") = #externalMacro(module: "MockSwiftMacroMacros", type: "MockMacro")
