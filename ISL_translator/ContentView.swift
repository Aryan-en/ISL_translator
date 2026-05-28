import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 230, ideal: 260, max: 320)
        } detail: {
            MainCameraView(viewModel: viewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .task { await viewModel.start() }
    }
}

#Preview {
    ContentView()
}
