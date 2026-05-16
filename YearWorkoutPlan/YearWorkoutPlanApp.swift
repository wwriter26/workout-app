import SwiftUI

@main
struct YearWorkoutPlanApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                // Run startup tasks: load persisted data, request HealthKit auth on
                // first launch, and fetch today's biometrics so Today screen is fresh.
                .task {
                    appState.load()
                    if !appState.onboardingCompleted {
                        // First run: prompt HealthKit authorization non-blockingly.
                        // We use try? so a denial (HealthKitError.notAvailable on simulator)
                        // doesn't surface as an unhandled error to the user.
                        try? await HealthKitManager.shared.requestAuthorization()
                    }
                    await appState.refreshHealthData()
                }
                // Refresh biometrics whenever the app returns to the foreground so
                // the recovery banner reflects fresh HRV/sleep data after a night's sleep.
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await appState.refreshHealthData() }
                    }
                }
        }
    }
}
