import Testing
@testable import ObServe

@Suite(.serialized)
struct SettingsManagerTests {
    // MARK: - pollingIntervalLabel

    @Test func pollingIntervalLabelForKnownValues() {
        let mgr = SettingsManager.shared

        let original = mgr.pollingIntervalSeconds

        mgr.pollingIntervalSeconds = 2
        #expect(mgr.pollingIntervalLabel() == "2 seconds")

        mgr.pollingIntervalSeconds = 5
        #expect(mgr.pollingIntervalLabel() == "5 seconds")

        mgr.pollingIntervalSeconds = 10
        #expect(mgr.pollingIntervalLabel() == "10 seconds")

        mgr.pollingIntervalSeconds = 30
        #expect(mgr.pollingIntervalLabel() == "30 seconds")

        mgr.pollingIntervalSeconds = 60
        #expect(mgr.pollingIntervalLabel() == "1 minute")

        // Restore original
        mgr.pollingIntervalSeconds = original
    }

    @Test func pollingIntervalLabelForUnknownValue() {
        let mgr = SettingsManager.shared
        let original = mgr.pollingIntervalSeconds

        mgr.pollingIntervalSeconds = 15
        #expect(mgr.pollingIntervalLabel() == "15 seconds")

        mgr.pollingIntervalSeconds = 120
        #expect(mgr.pollingIntervalLabel() == "120 seconds")

        mgr.pollingIntervalSeconds = original
    }

    // MARK: - pollingIntervalOptions

    @Test func pollingIntervalOptionsAreValid() {
        let options = SettingsManager.pollingIntervalOptions
        #expect(options == [2, 5, 10, 30, 60])
    }

    // MARK: - resetAllSettings

    @Test func resetAllSettingsRestoresDefaults() {
        let mgr = SettingsManager.shared

        // Save originals
        let origPrecise = mgr.preciseDataEnabled
        let origSafe = mgr.safeModeEnabled
        let origHaptics = mgr.hapticsEnabled
        let origAuto = mgr.autoConnectOnLaunch
        let origPolling = mgr.pollingIntervalSeconds

        // Set non-default values
        mgr.preciseDataEnabled = true
        mgr.safeModeEnabled = false
        mgr.hapticsEnabled = false
        mgr.autoConnectOnLaunch = true
        mgr.pollingIntervalSeconds = 60

        // Reset
        mgr.resetAllSettings()

        // Verify defaults
        #expect(mgr.preciseDataEnabled == false)
        #expect(mgr.safeModeEnabled == true)
        #expect(mgr.hapticsEnabled == true)
        #expect(mgr.autoConnectOnLaunch == false)
        #expect(mgr.pollingIntervalSeconds == 2)

        // Restore originals to not affect other tests
        mgr.preciseDataEnabled = origPrecise
        mgr.safeModeEnabled = origSafe
        mgr.hapticsEnabled = origHaptics
        mgr.autoConnectOnLaunch = origAuto
        mgr.pollingIntervalSeconds = origPolling
    }
}
