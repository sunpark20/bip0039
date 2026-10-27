import UIKit
import SwiftUI

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication,
                     shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        extensionPointIdentifier != .keyboard
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var privacyWindow: UIWindow?
    private var host: UIHostingController<AnyView>?
    private let session = SearchSession()

    func scene(_ scene: UIScene, willConnectTo sceneSession: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let mainWindow = UIWindow(windowScene: windowScene)
        mainWindow.overrideUserInterfaceStyle = .light
        let controller = UIHostingController(rootView: AnyView(WordListView(session: session)))
        host = controller
        mainWindow.rootViewController = controller
        window = mainWindow
        mainWindow.makeKeyAndVisible()

        // A separate opaque UIKit window covers the UI synchronously, before a
        // SwiftUI render or the system's app-switcher snapshot can occur.
        let shield = UIWindow(windowScene: windowScene)
        shield.windowLevel = .alert + 1
        shield.overrideUserInterfaceStyle = .light
        let shieldController = UIViewController()
        shieldController.view.backgroundColor = .white
        shieldController.view.accessibilityIdentifier = "privacyShield"
        shieldController.view.accessibilityViewIsModal = true
        shield.rootViewController = shieldController
        privacyWindow = shield
        shield.isHidden = false
    }

    func sceneWillResignActive(_ scene: UIScene) {
        concealAndReset()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        concealAndReset()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        concealAndReset()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Replace the old view tree under the shield, so stale filtered rows and
        // scroll position cannot flash during foreground restoration.
        session.reset()
        refreshContent()
        privacyWindow?.isHidden = true
        window?.accessibilityElementsHidden = false
    }

    private func concealAndReset() {
        privacyWindow?.isHidden = false
        privacyWindow?.rootViewController?.view.layoutIfNeeded()
        window?.accessibilityElementsHidden = true
        session.reset()
        refreshContent()
    }

    private func refreshContent() {
        host?.rootView = AnyView(WordListView(session: session).id(UUID()))
        host?.view.setNeedsLayout()
        host?.view.layoutIfNeeded()
    }
}
