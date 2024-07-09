//
//  HelperRoomateApp.swift
//  HelperRoomate
//
//   Created by d0x1t on 02/07/2024.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct HelperRoomateApp: App {
    @StateObject private var authenticationViewModel = AuthenticationViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(authenticationViewModel)
        }
    }
    
}
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}
    

