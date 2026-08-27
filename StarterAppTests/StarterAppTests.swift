import AppFoundation
import Foundation
import XCTest
@testable import StarterApp

@MainActor
final class StarterAppTests: XCTestCase {
    func testStarterConfigurationUsesExpectedIdentity() {
        XCTAssertEqual(AppConfiguration.monthlyProductID, "com.hoangbkit.starterapp.pro.monthly")
        XCTAssertEqual(AppConfiguration.yearlyProductID, "com.hoangbkit.starterapp.pro.yearly")
        XCTAssertFalse(AppConfiguration.displayName.isEmpty)
        XCTAssertFalse(AppConfiguration.bundleIdentifier.isEmpty)
    }

    func testStarterURLsAreHTTPS() {
        XCTAssertEqual(AppConfiguration.supportURL.scheme, "https")
        XCTAssertEqual(AppConfiguration.privacyURL.scheme, "https")
        XCTAssertEqual(AppConfiguration.termsURL.scheme, "https")
    }

    func testAppStoreSharingStaysHiddenUntilConfigured() {
        XCTAssertNil(AppConfiguration.appStoreID)
        XCTAssertNil(AppConfiguration.appStoreURL)
    }

    func testPersistentKeysAreNamespaced() {
        XCTAssertTrue(AppConfiguration.simulatedPurchaseModeDefaultsKey.hasSuffix(".developer.simulated-purchases-enabled"))
        XCTAssertTrue(AppConfiguration.simulatedPurchasePersistenceKey.hasSuffix(".simulated-purchases"))
        XCTAssertTrue(AppConfiguration.themeStateKey.hasSuffix(".theme-state"))
        XCTAssertTrue(AppRouter.onboardingCompletionKey.hasSuffix(".has-completed-onboarding"))
    }

    func testPurchaseConfigurationUsesYearlyAsPreferredProduct() {
        XCTAssertEqual(
            AppConfiguration.purchaseConfiguration.productIDs,
            [
                AppConfiguration.monthlyProductID,
                AppConfiguration.yearlyProductID,
            ]
        )
        XCTAssertEqual(
            AppConfiguration.purchaseConfiguration.preferredProductID,
            AppConfiguration.yearlyProductID
        )
        XCTAssertEqual(
            AppConfiguration.purchaseConfiguration.entitledProductIDs,
            Set([
                AppConfiguration.monthlyProductID,
                AppConfiguration.yearlyProductID,
            ])
        )
    }

    func testPaywallUsesCurrentThemeAwareConfiguration() {
        XCTAssertEqual(
            AppConfiguration.paywallConfiguration.preferredProductID,
            AppConfiguration.yearlyProductID
        )
        XCTAssertEqual(AppConfiguration.paywallConfiguration.features.count, 3)
        XCTAssertNil(AppConfiguration.paywallConfiguration.themeOverride)
        XCTAssertNil(AppConfiguration.paywallConfiguration.tint)
    }

    func testRequestedSimulationIsSafeForCurrentBuild() {
        let effectiveMode = PurchaseServiceFactory.effectiveMode(for: .simulated)

        #if DEBUG
        XCTAssertEqual(effectiveMode, .simulated)
        #else
        XCTAssertEqual(effectiveMode, .live)
        #endif
    }

    func testPurchaseManagerUsesLiveModeByDefault() {
        #if DEBUG
        let defaults = UserDefaults.standard
        let key = AppConfiguration.simulatedPurchaseModeDefaultsKey
        let previousValue = defaults.object(forKey: key)
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.removeObject(forKey: key)
        XCTAssertFalse(AppConfiguration.isSimulatedPurchaseModeEnabled)
        #else
        XCTAssertFalse(AppConfiguration.isSimulatedPurchaseModeEnabled)
        #endif
    }

    func testRouterStartsWithOnboardingAndPersistsCompletion() {
        let suiteName = "StarterAppTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create isolated UserDefaults.")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let router = AppRouter(defaults: defaults)
        XCTAssertEqual(router.launchState, .preparing)

        router.prepare()
        XCTAssertEqual(router.launchState, .onboarding)

        router.completeOnboarding()
        XCTAssertEqual(router.launchState, .main)

        let relaunchedRouter = AppRouter(defaults: defaults)
        relaunchedRouter.prepare()
        XCTAssertEqual(relaunchedRouter.launchState, .main)
    }

    func testShowingOnboardingDoesNotForgetCompletion() {
        let suiteName = "StarterAppTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create isolated UserDefaults.")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let router = AppRouter(defaults: defaults)
        router.prepare()
        router.completeOnboarding()
        router.showOnboarding()

        XCTAssertEqual(router.launchState, .onboarding)
        XCTAssertTrue(defaults.bool(forKey: AppRouter.onboardingCompletionKey))
    }
}
