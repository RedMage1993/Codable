import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CodableMacro: ExtensionMacro, MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let codableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): Codable {}")

        return [codableExtension]
    }

    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else { return [] }

        let modifier = declaration.modifiers.first?.name.trimmed.text.appending(" ") ?? ""

        let bindings = classDecl.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { !$0.modifiers.contains { modifier in modifier.name.trimmed.text == "static" } }
            .compactMap { $0.bindings.first }
            .filter { $0.accessorBlock == nil }

        let identifiers = bindings.compactMap { $0.pattern.as(IdentifierPatternSyntax.self) }
        let types = bindings.compactMap { $0.typeAnnotation?.type }

        let codingKeysExpression = identifiers
            .map { "case \($0)" }
            .joined(separator: "\n")

        let decoderExpression = zip(identifiers, types)
            .compactMap {
                let asOptional = $0.1.as(OptionalTypeSyntax.self)
                let ifPresent = asOptional == nil ? "" : "IfPresent"
                let type = (asOptional?.wrappedType ?? $0.1)

                return "\($0.0.identifier) = try container.decode\(ifPresent)(\(type).self, forKey: .\($0.0.identifier))"
            }
            .joined(separator: "\n")

        let encoderExpression = zip(identifiers, types)
            .compactMap { "try container.encode(\($0.0.identifier), forKey: .\($0.0.identifier))" }
            .joined(separator: "\n")

        return [
            """
            enum CodingKeys: String, CodingKey {
                \(raw: codingKeysExpression)
            }
            """,
            """
            \(raw: modifier)required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(raw: decoderExpression)
            }
            """,
            """
            \(raw: modifier)func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                \(raw: encoderExpression)
            }
            """
        ]
    }
}

@main
struct CodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableMacro.self
    ]
}
