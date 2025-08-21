//
//  ELAForKidsApp.swift
//  ELAForKids
//
//  Created by Linh Do Khanh (CV Phat trien phan mem ngoai core Cap 2 - Phong Phat trien ngoai Core - TT Phat trien - Khoi CNTT - SHB) on 21/08/2025.
//

import SwiftUI

@main
struct ELAForKidsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
