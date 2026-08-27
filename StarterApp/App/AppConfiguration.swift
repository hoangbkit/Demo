import AppFoundation
import Foundation

@MainActor
enum AppConfiguration {
    private static let fallbackDisplayName = "StarterApp"
    private static let fallbackBundleIdentifier = "com.hoangbkit.starterapp"

    static var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? fallbackDisplayName
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? fallbackBundleIdentifier
    }

    static let appStoreID: String? = nil

    static var appStoreURL: URL? {
        guard let appStoreID, !appStoreID.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    static let monthlyProductID = "com.hoangbkit.starterapp.pro.monthly"
    static let yearlyProductID = "com.hoangbkit.starterapp.pro.yearly"

    private static let purchaseModeEnvironmentKey = "APPFOUNDATION_PURCHASE_MODE"

    static var simulatedPurchaseModeDefaultsKey: String {
        "\(bundleIdentifier).developer.simulated-purchases-enabled"
    }

    static var simulatedPurchasePersistenceKey: String {
        "\(bundleIdentifier).simulated-purchases"
    }

    static var themeStateKey: String {
        "\(bundleIdentifier).theme-state"
    }

    static let supportURL = URL(string: "https://example.com/contact")!
    static let privacyURL = URL(string: "https://example.com/privacy")!
    static let termsURL = URL(string: "https://example.com/terms")!

    static let purchaseConfiguration = PurchaseConfiguration(
        productIDs: [
            monthlyProductID,
            yearlyProductID,
        ],
        preferredProductID: yearlyProductID
    )

    static let simulatedProducts: [StoreProduct] = [
        StoreProduct(
            id: monthlyProductID,
            displayName: "\(displayName) Pro Monthly",
            description: "Monthly access to every \(displayName) Pro feature.",
            displayPrice: "$4.99",
            price: 4.99,
            subscriptionPeriod: .init(value: 1, unit: .month)
        ),
        StoreProduct(
            id: yearlyProductID,
            displayName: "\(displayName) Pro Yearly",
            description: "Annual access to every \(displayName) Pro feature.",
            displayPrice: "$39.99",
            price: 39.99,
            subscriptionPeriod: .init(value: 1, unit: .year)
        ),
    ]

    static var isSimulatedPurchaseModeEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment[purchaseModeEnvironmentKey] == "simulated"
            || UserDefaults.standard.bool(forKey: simulatedPurchaseModeDefaultsKey)
        #else
        false
        #endif
    }

    static let paywallConfiguration = PaywallConfiguration(
        title: "Get more \(displayName)",
        subtitle: "Choose the plan that's right for you",
        planTitle: "\(displayName) Pro",
        planSubtitle: "Everything you need, without limits",
        features: [
            PaywallFeature(
                id: "all-features",
                systemImage: "sparkles",
                title: "All Pro features",
                message: "Unlock every premium feature in \(displayName)."
            ),
            PaywallFeature(
                id: "updates",
                systemImage: "arrow.down.circle",
                title: "Future updates",
                message: "Get every new Pro feature as it ships."
            ),
            PaywallFeature(
                id: "limits",
                systemImage: "infinity",
                title: "No limits",
                message: "Remove free-plan usage limits."
            ),
        ],
        preferredProductID: yearlyProductID,
        highlightedProductID: yearlyProductID,
        purchaseButtonTitle: "Get Pro plan",
        privacyURL: privacyURL,
        termsURL: termsURL
    )

    static let claudePaywallConfiguration = FoundationPaywallConfiguration(
        title: "Get more \(displayName)",
        subtitle: "Choose monthly or yearly access",
        features: [
            FoundationPaywallFeature(
                id: "all-features",
                systemImage: "checkmark",
                title: "All Pro features",
                message: "Unlock every Pro feature in \(displayName)."
            ),
            FoundationPaywallFeature(
                id: "themes-icons",
                systemImage: "checkmark",
                title: "Themes and icons",
                message: "Use every Pro theme and alternate app icon."
            ),
            FoundationPaywallFeature(
                id: "updates",
                systemImage: "checkmark",
                title: "Future updates",
                message: "Get every new Pro feature as it ships."
            ),
        ],
        highlightedProductID: yearlyProductID,
        privacyURL: privacyURL,
        termsURL: termsURL
    )

    static let proPlanSettingsConfiguration = ProPlanSettingsConfiguration(
        sectionTitle: "\(displayName) Pro",
        activePlanTitle: "\(displayName) Pro",
        unlockTitle: "Unlock \(displayName) Pro"
    )

    static func makePurchaseManager() -> PurchaseManager {
        PurchaseManager(
            configuration: purchaseConfiguration,
            simulated: isSimulatedPurchaseModeEnabled,
            simulatedProducts: simulatedProducts,
            simulatedPersistenceKey: simulatedPurchasePersistenceKey
        )
    }

    static func makeThemeManager() -> ThemeManager {
        ThemeManager(
            catalog: .foundationDefaults,
            stateStore: UserDefaultsThemeStateStore(storageKey: themeStateKey)
        )
    }

    static func makePreviewPurchaseManager() -> PurchaseManager {
        PurchaseManager(
            configuration: purchaseConfiguration,
            simulated: true,
            simulatedProducts: simulatedProducts,
            simulatedOperationDelay: .milliseconds(0)
        )
    }
}
