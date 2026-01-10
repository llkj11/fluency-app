import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var showingAPIKey = false
    @State private var launchAtLogin = false
    @State private var showSaveConfirmation = false
    @State private var selectedProvider: TranscriptionProvider = .openAI
    
    // API Verification states
    @State private var isVerifying = false
    @State private var verificationResult: VerificationResult?
    
    enum VerificationResult {
        case success
        case failure(String)
    }
    
    enum TranscriptionProvider: String, CaseIterable {
        case openAI = "GPT-4o Mini Transcribe"
        case whisper = "OpenAI Whisper (Coming Soon)"
        case deepgram = "Deepgram (Coming Soon)"
        case assemblyAI = "AssemblyAI (Coming Soon)"
        case localWhisper = "Local Whisper (Coming Soon)"
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .font(.headline)

                    HStack {
                        if showingAPIKey {
                            TextField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: apiKey) { _, newValue in
                                    autoSaveAPIKey(newValue)
                                }
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: apiKey) { _, newValue in
                                    autoSaveAPIKey(newValue)
                                }
                        }

                        Button {
                            showingAPIKey.toggle()
                        } label: {
                            Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }

                    HStack {
                        if !apiKey.isEmpty {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Enter your API key above")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Verify") {
                            verifyAPIKey()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(apiKey.isEmpty || isVerifying)

                        if !apiKey.isEmpty {
                            Button("Clear", role: .destructive) {
                                clearAPIKey()
                            }
                        }
                        
                        if isVerifying {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    if showSaveConfirmation {
                        Label("API key saved", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    if let result = verificationResult {
                        switch result {
                        case .success:
                            Label("API key is valid!", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        case .failure(let error):
                            Label(error, systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            } header: {
                Text("API Configuration")
            } footer: {
                Link("Get an API key from OpenAI", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.caption)
            }
            
            Section {
                Picker("Transcription Provider", selection: $selectedProvider) {
                    ForEach(TranscriptionProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue)
                            .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .disabled(selectedProvider != .openAI) // Only OpenAI works for now
            } header: {
                Text("Provider")
            } footer: {
                Text("More providers coming soon!")
                    .font(.caption)
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            } header: {
                Text("General")
            }
            
            Section {
                StatsView()
            } header: {
                Text("Your Stats")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Use")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        InstructionRow(number: 1, text: "Set 'Press 🌐 key to' → 'Do Nothing' in System Settings → Keyboard")
                        InstructionRow(number: 2, text: "Click in any text field")
                        InstructionRow(number: 3, text: "Hold the Fn key and speak")
                        InstructionRow(number: 4, text: "Release Fn to transcribe and paste")
                    }
                }
            } header: {
                Text("Instructions")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    PermissionRow(
                        title: "Microphone",
                        description: "Required to record your voice",
                        systemImage: "mic",
                        action: openMicrophoneSettings
                    )

                    PermissionRow(
                        title: "Accessibility",
                        description: "Required for hotkey detection and text paste",
                        systemImage: "accessibility",
                        action: openAccessibilitySettings
                    )
                }
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 450)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        if let key = KeychainHelper.getAPIKey() {
            apiKey = key
        }
        // Check launch at login status
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
    
    private func autoSaveAPIKey(_ key: String) {
        // Auto-save when the key changes (debounced effectively by onChange)
        if !key.isEmpty {
            KeychainHelper.saveAPIKey(key)
        }
        verificationResult = nil
    }

    private func saveAPIKey() {
        KeychainHelper.saveAPIKey(apiKey)
        showSaveConfirmation = true
        verificationResult = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSaveConfirmation = false
        }
    }
    
    private func verifyAPIKey() {
        isVerifying = true
        verificationResult = nil
        
        Task {
            let service = TranscriptionService()
            let result = await service.verifyAPIKey(apiKey)
            
            await MainActor.run {
                isVerifying = false
                switch result {
                case .success:
                    verificationResult = .success
                case .failure(let error):
                    verificationResult = .failure(error.localizedDescription)
                }
                
                // Auto-hide result after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    verificationResult = nil
                }
            }
        }
    }

    private func clearAPIKey() {
        KeychainHelper.deleteAPIKey()
        apiKey = ""
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }

    private func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 12))
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Open Settings") {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}
