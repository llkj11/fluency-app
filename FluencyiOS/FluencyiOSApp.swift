import SwiftUI
import SwiftData

@main
struct FluencyiOSApp: App {
    let sharedModelContainer: ModelContainer
    
    init() {
        // Configure SwiftData - try App Group first, fall back to local if not configured
        let schema = Schema([Transcription.self])
        
        // Try with App Group first (for keyboard extension sharing)
        do {
            let groupConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.fluency.ios")
            )
            sharedModelContainer = try ModelContainer(for: schema, configurations: [groupConfig])
            print("✅ Using App Group container for SwiftData")
        } catch {
            // Fall back to local storage if App Group not available
            print("⚠️ App Group not available, using local storage: \(error.localizedDescription)")
            do {
                let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                sharedModelContainer = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Dictate", systemImage: "waveform")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
