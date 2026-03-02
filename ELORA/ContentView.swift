import SwiftUI

/// Legacy wrapper — the app now uses MainTabView via ELORAApp.
/// Kept for backward compatibility with any storyboard/preview references.
struct ContentView: View {
    var body: some View {
        Text("ELORA")
            .font(.custom("Tenor Sans", size: 32))
            .foregroundColor(Color(red: 0.86, green: 0.53, blue: 0.38))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
