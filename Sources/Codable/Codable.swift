@attached(extension, conformances: Codable)
@attached(member, names: named(CodingKeys), named(init), named(encode))
public macro Codable() = #externalMacro(module: "CodableMacros", type: "CodableMacro")
