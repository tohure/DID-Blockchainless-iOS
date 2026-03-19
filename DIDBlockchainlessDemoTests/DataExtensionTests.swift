// DataExtensionTests.swift
// DIDBlockchainlessDemoTests

import Testing
@testable import DIDBlockchainlessDemo

struct DataBase64URLTests {

    @Test func roundtripEncoding() {
        let original = Data("Hello, DID World! 🔑".utf8)
        let encoded = original.base64URLEncodedString()
        let decoded = Data(base64URLEncoded: encoded)
        #expect(decoded == original)
    }

    @Test func encodingHasNoStandardBase64Chars() {
        let data = Data(repeating: 0xFF, count: 100)
        let encoded = data.base64URLEncodedString()
        #expect(!encoded.contains("+"))
        #expect(!encoded.contains("/"))
        #expect(!encoded.contains("="))
    }

    @Test func decodeWithoutPadding() {
        // RFC 4648: decode sin padding debe funcionar
        let base64url = "SGVsbG8gV29ybGQ"   // "Hello World" sin padding
        let decoded = Data(base64URLEncoded: base64url)
        #expect(decoded != nil)
        #expect(String(data: decoded!, encoding: .utf8) == "Hello World")
    }

    @Test func emptyDataRoundtrip() {
        let empty = Data()
        let encoded = empty.base64URLEncodedString()
        let decoded = Data(base64URLEncoded: encoded)
        #expect(decoded == empty)
    }
}

struct DataHexTests {

    @Test func encodeDecodeRoundtrip() {
        let original = Data([0x01, 0xAB, 0xCD, 0xFF, 0x00])
        let hex = original.hexEncodedString
        let decoded = Data(hexEncoded: hex)
        #expect(decoded == original)
    }

    @Test func hexEncodingIsLowerCase() {
        let data = Data([0xAB, 0xCD, 0xEF])
        #expect(data.hexEncodedString == "abcdef")
    }

    @Test func oddLengthHexFails() {
        let decoded = Data(hexEncoded: "abc")
        #expect(decoded == nil)
    }

    @Test func invalidHexCharsFail() {
        let decoded = Data(hexEncoded: "GHIJ")
        #expect(decoded == nil)
    }
}
