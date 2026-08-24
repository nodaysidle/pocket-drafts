import SwiftUI
import SwiftData

/// Top-level popover content. Switches between the list (dashboard) and
/// the editor; the route keeps the dashboard state alive while editing.
struct RootView: View {
    enum Route {
        case dashboard
        case editor(Note?)
    }

    @State private var route: Route = .dashboard

    var body: some View {
        switch route {
        case .dashboard:
            DashboardView(
                onCreate: { route = .editor(nil) },
                onEdit: { note in route = .editor(note) }
            )
        case .editor(let note):
            NoteEditorView(note: note) {
                route = .dashboard
            }
        }
    }
}
