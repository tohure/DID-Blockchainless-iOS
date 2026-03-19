// DIDScreen.swift
// DIDBlockchainlessDemo
//
// Pantalla de identidad DID. Replica la funcionalidad de DidScreen.kt de Android.

import SwiftUI

struct DIDScreen: View {
    @State private var viewModel = DIDViewModel()

    var body: some View {
        ZStack {
            LinearGradient.appGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Paso 1: Identidad DID
                    identitySection

                    // MARK: - Paso 2: Solicitar VC
                    proofSection

                    // MARK: - Paso 3: Metadatos
                    metadataSection

                    // MARK: - Paso 4: Verificar VP
                    vpSection

                    // MARK: - Barra de estado
                    StatusBar(message: viewModel.state.statusMessage, isLoading: viewModel.state.isLoading)
                }
                .padding(16)
            }
        }
        .navigationTitle("Identidad DID")
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

    // MARK: - Secciones

    private var identitySection: some View {
        InfoCard(title: "Identidad DID", icon: "person.badge.key.fill") {
            VStack(spacing: 12) {
                if viewModel.state.didKeysExist {
                    MonoText(label: "DID (did:key)", value: viewModel.state.did)
                    MonoText(label: "Key ID", value: viewModel.state.keyID)
                    StatusBadge(level: viewModel.state.didSecurityLevel)
                } else {
                    Text("Sin claves DID generadas")
                        .font(.appBody).foregroundStyle(Color.textSecondary)
                }

                HStack(spacing: 8) {
                    PrimaryButton(
                        viewModel.state.didKeysExist ? "Claves creadas ✓" : "Generar claves",
                        icon: "key.fill",
                        isLoading: viewModel.state.isLoading && !viewModel.state.didKeysExist
                    ) {
                        viewModel.generateDIDKeys()
                    }
                    .disabled(viewModel.state.didKeysExist)

                    if viewModel.state.didKeysExist {
                        DestructiveButton(title: "Eliminar") {
                            viewModel.deleteDIDKeys()
                        }
                        .frame(width: 100)
                    }
                }
            }
        }
    }

    private var proofSection: some View {
        InfoCard(title: "Proof JWT & Credencial", icon: "doc.badge.gearshape.fill") {
            VStack(spacing: 12) {
                PrimaryButton(
                    "Solicitar Credencial",
                    icon: "arrow.down.doc.fill",
                    isLoading: viewModel.state.isLoading
                ) {
                    viewModel.requestCredentialWithNonce()
                }
                .disabled(!viewModel.state.didKeysExist || viewModel.state.isLoading)

                if !viewModel.state.lastProofJWT.isEmpty {
                    Divider().background(Color.cardBorder)
                    MonoText(label: "Proof JWT", value: viewModel.state.lastProofJWT)
                    MonoText(label: "Credencial cifrada (AES-256-GCM)", value: viewModel.state.encryptedCredential)
                }
            }
        }
    }

    private var metadataSection: some View {
        InfoCard(title: "Metadatos de Credenciales", icon: "list.bullet.rectangle.fill") {
            VStack(spacing: 12) {
                if !viewModel.state.decryptedMetadata.isEmpty {
                    MonoText(label: "Metadatos (JSON)", value: viewModel.state.decryptedMetadata)
                    DestructiveButton(title: "Limpiar metadatos") {
                        viewModel.clearDecryptedMetadata()
                    }
                } else {
                    Text("Sin metadatos. Solicita una credencial primero.")
                        .font(.appCaption).foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private var vpSection: some View {
        InfoCard(title: "Verifiable Presentation", icon: "checkmark.seal.fill") {
            VStack(spacing: 12) {
                PrimaryButton(
                    "Verificar VP",
                    icon: "checkmark.circle.fill",
                    isLoading: viewModel.state.isLoading
                ) {
                    viewModel.verifyVP()
                }
                .disabled(viewModel.state.encryptedCredential.isEmpty || viewModel.state.isLoading)

                if !viewModel.state.validationResponseJSON.isEmpty {
                    Divider().background(Color.cardBorder)
                    MonoText(label: "Respuesta del backend", value: viewModel.state.validationResponseJSON)
                }
            }
        }
    }
}
