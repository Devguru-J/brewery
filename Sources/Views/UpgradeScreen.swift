import SwiftUI

struct UpgradeScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            HeroPanel()
            StepCards()
                .frame(height: 180)
            OutdatedList()
                .frame(minHeight: 180, maxHeight: .infinity)
                .layoutPriority(1)
        }
    }
}
