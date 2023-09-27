@attached(peer, names: suffixed(Mock))
public macro Mock() = #externalMacro(module: "MockSwiftMacroMacros", type: "MockMacro")
