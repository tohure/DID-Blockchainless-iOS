// RSAScreen.swift
// DIDBlockchainlessDemo
//
// Pantalla de cifrado AES-256-GCM.

import SwiftUI

struct RSAScreen: View {
    @State private var viewModel = RSAViewModel()

    var body: some View {
        ZStack {
            LinearGradient.appGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Clave AES
                    InfoCard(title: "Clave AES-256-GCM", icon: "key.fill") {
                        VStack(spacing: 12) {
                            if viewModel.state.keyExists {
                                HStack {
                                    Text("Clave en:").font(.appCaption).foregroundStyle(Color.textSecondary)
                                    StatusBadge(level: viewModel.state.securityLevel)
                                    Spacer()
                                }
                            } else {
                                Text("Sin clave generada")
                                    .font(.appCaption).foregroundStyle(Color.textSecondary)
                            }

                            HStack(spacing: 8) {
                                PrimaryButton(
                                    viewModel.state.keyExists ? "Clave lista ✓" : "Generar clave",
                                    icon: "plus.circle.fill",
                                    isLoading: viewModel.state.isLoading
                                ) {
                                    viewModel.generateKey()
                                }
                                .disabled(viewModel.state.keyExists)

                                if viewModel.state.keyExists {
                                    DestructiveButton(title: "Eliminar") {
                                        viewModel.deleteKey()
                                    }
                                    .frame(width: 100)
                                }
                            }
                        }
                    }

                    // MARK: - Cifrado
                    InfoCard(title: "Cifrar texto", icon: "lock.fill") {
                        VStack(spacing: 12) {
                            TextField("Texto a cifrar...", text: $viewModel.state.inputText, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.appBody)
                                .foregroundStyle(Color.textPrimary)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .tint(Color.appPrimary)

                            PrimaryButton("Cifrar", icon: "lock.fill", isLoading: viewModel.state.isLoading) {
                                viewModel.encrypt()
                            }
                            .disabled(!viewModel.state.keyExists || viewModel.state.inputText.isEmpty)

                            if !viewModel.state.encryptedText.isEmpty {
                                Divider().background(Color.cardBorder)
                                MonoText(label: "Texto cifrado (Base64URL AES-GCM)", value: viewModel.state.encryptedText)
                            }
                        }
                    }

                    // MARK: - Descifrado
                    InfoCard(title: "Descifrar", icon: "lock.open.fill") {
                        VStack(spacing: 12) {
                            PrimaryButton("Descifrar", icon: "lock.open.fill", isLoading: viewModel.state.isLoading) {
                                viewModel.decrypt()
                            }
                            .disabled(!viewModel.state.keyExists || viewModel.state.encryptedText.isEmpty)

                            if !viewModel.state.decryptedText.isEmpty {
                                Divider().background(Color.cardBorder)
                                MonoText(label: "Texto descifrado", value: viewModel.state.decryptedText)
                            }
                        }
                    }

                    // Status
                    StatusBar(message: viewModel.state.statusMessage, isLoading: viewModel.state.isLoading)
                }
                .padding(16)
            }
        }
        .navigationTitle("Cifrado AES-256")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .biometricAuth(
            isPresented: Binding(
                get: { viewModel.state.showBiometricPrompt },
                set: { _ in }
            ),
            onSuccess: { viewModel.onBiometricSuccess() },
            onFailure: { viewModel.onBiometricFailure() },
            onDismissed: { viewModel.onBiometricDismissed() }
        )
    }
}
