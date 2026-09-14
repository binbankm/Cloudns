import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)

                Text("Cloudns")
                    .font(.largeTitle.bold())

                Text("项目已完全清空，等待重写")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("首页")
        }
    }
}

#Preview {
    ContentView()
}
