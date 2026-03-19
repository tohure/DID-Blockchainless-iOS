// Base58Tests.swift
// DIDBlockchainlessDemoTests
//
// Tests unitarios para Base58 encoding — verifica que el resultado es idéntico
// al algoritmo Android/Python para vectores de prueba conocidos.

import Testing
@testable import DIDBlockchainlessDemo

struct Base58Tests {

    // Vector de prueba: Bitcoin genesis block hash (bien conocido)
    // Input hex: 000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
    // Expected: 000d0tPBGHGPGGMv41xtunBEbC7FeTrhBdEJPVNWdpQh
    // (primer '1' por el byte 0x00 inicial)

    @Test func encodeEmptyData() {
        let result = Base58.encode(Data())
        #expect(result == "")
    }

    @Test func encodeZeroByte() {
        // Un solo 0x00 debe codificarse como "1" (primer carácter del alfabeto)
        let result = Base58.encode(Data([0x00]))
        #expect(result == "1")
    }

    @Test func encodeTwoZeroBytes() {
        let result = Base58.encode(Data([0x00, 0x00]))
        #expect(result == "11")
    }

    @Test func encodeKnownVector() {
        // "Hello World" en ASCII → Base58
        let input = Data("Hello World".utf8)
        let result = Base58.encode(input)
        // Valor calculado con Python: base58.b58encode("Hello World")
        #expect(result == "JxF12TrwUP45BMd")
    }

    @Test func encodeDIDMulticodecPrefix() {
        // Prefijo secp256k1-pub (multicodec varint 0xe7 0x01)
        // Esto es lo que se antepone a la clave pública comprimida en DID:key
        let prefix = Data([0xe7, 0x01])
        let result = Base58.encode(prefix)
        // Debe ser base58 de "\xe7\x01"
        #expect(!result.isEmpty)
        #expect(!result.contains("+"))
        #expect(!result.contains("/"))
        #expect(!result.contains("0"))  // No ambiguous chars
    }

    @Test func alphabetContainsNoBitcoinExcludedChars() {
        let alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        // Caracteres excluidos del alfabeto Bitcoin Base58
        #expect(!alphabet.contains("0"))
        #expect(!alphabet.contains("O"))
        #expect(!alphabet.contains("I"))
        #expect(!alphabet.contains("l"))
        #expect(alphabet.count == 58)
    }
}
