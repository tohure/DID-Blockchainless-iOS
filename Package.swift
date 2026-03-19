// swift-tools-version: 5.9
// DIDBlockchainlessDemo — Package.swift
//
// Solo se usa para gestionar dependencias externas via Swift Package Manager (SPM).
// El proyecto principal es un .xcodeproj al que se agrega este paquete manualmente.

import PackageDescription

let package = Package(
    name: "DIDBlockchainlessDemo",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        // swift-secp256k1: wrapper de libsecp256k1 con API tipo CryptoKit
        // Equivalente a BouncyCastle (secp256k1) de Android
        // Repo: https://github.com/21-DOT-DEV/swift-secp256k1
        .package(
            url: "https://github.com/21-DOT-DEV/swift-secp256k1",
            from: "0.18.0"
        )
    ],
    targets: [
        .target(
            name: "DIDBlockchainlessDemo",
            dependencies: [
                .product(name: "secp256k1", package: "swift-secp256k1")
            ],
            path: "DIDBlockchainlessDemo"
        ),
        .testTarget(
            name: "DIDBlockchainlessDemoTests",
            dependencies: ["DIDBlockchainlessDemo"],
            path: "DIDBlockchainlessDemoTests"
        )
    ]
)
