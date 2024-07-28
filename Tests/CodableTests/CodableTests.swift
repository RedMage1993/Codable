import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CodableMacros)
import CodableMacros

let testMacros: [String: Macro.Type] = [
    "Codable": CodableMacro.self
]
#endif

final class CodableTests: XCTestCase {
    func testInternalExtension() throws {
        #if canImport(CodableMacros)
        assertMacroExpansion(
            """
            @Codable
            class Coordinate {
                let latitude: Double?
                let longitude: Double
                let elevation: Double
                let random: [Int]?
            }
            """,
            expandedSource: """
            class Coordinate {
                let latitude: Double?
                let longitude: Double
                let elevation: Double
                let random: [Int]?

                enum CodingKeys: String, CodingKey {
                    case latitude
                    case longitude
                    case elevation
                    case random
                }

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
                    longitude = try container.decode(Double.self, forKey: .longitude)
                    elevation = try container.decode(Double.self, forKey: .elevation)
                    random = try container.decodeIfPresent([Int].self, forKey: .random)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(latitude, forKey: .latitude)
                    try container.encode(longitude, forKey: .longitude)
                    try container.encode(elevation, forKey: .elevation)
                    try container.encode(random, forKey: .random)
                }
            }

            extension Coordinate: Codable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicExtension() throws {
        #if canImport(CodableMacros)
        assertMacroExpansion(
            """
            @Codable
            public class Coordinate {
                let latitude: Double?
                let longitude: Double
                let elevation: Double
                let random: [Int]?
            }
            """,
            expandedSource: """
            public class Coordinate {
                let latitude: Double?
                let longitude: Double
                let elevation: Double
                let random: [Int]?

                enum CodingKeys: String, CodingKey {
                    case latitude
                    case longitude
                    case elevation
                    case random
                }

                public required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
                    longitude = try container.decode(Double.self, forKey: .longitude)
                    elevation = try container.decode(Double.self, forKey: .elevation)
                    random = try container.decodeIfPresent([Int].self, forKey: .random)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(latitude, forKey: .latitude)
                    try container.encode(longitude, forKey: .longitude)
                    try container.encode(elevation, forKey: .elevation)
                    try container.encode(random, forKey: .random)
                }
            }

            extension Coordinate: Codable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
