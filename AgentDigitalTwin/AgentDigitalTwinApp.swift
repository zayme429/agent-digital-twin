import SwiftUI

@main
struct AgentDigitalTwinApp: App {
    @StateObject private var scheduleManager = ScheduleManager()
    @StateObject private var personaManager  = PersonaManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scheduleManager)
                .environmentObject(personaManager)
                .preferredColorScheme(.light)
        }
    }
}
