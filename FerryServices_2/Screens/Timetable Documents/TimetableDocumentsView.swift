import Observation
import QuickLook
import SwiftUI

@MainActor
@Observable
final class TimetableDocumentsViewModel {
    var documents: [TimetableDocument] = []
    var isLoading = false
    var errorMessage: String?
    var previewDocument: PreviewDocument?

    private let serviceID: Int?
    private var downloadingDocumentIDs: Set<Int> = []

    init(serviceID: Int? = nil) {
        self.serviceID = serviceID
    }

    func loadDocuments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            documents = try await APIClient.fetchTimetableDocuments(serviceID: serviceID)
        } catch {
            errorMessage = "Unable to load timetable documents."
        }
    }

    func isDownloading(_ document: TimetableDocument) -> Bool {
        downloadingDocumentIDs.contains(document.id)
    }

    func isDownloaded(_ document: TimetableDocument) -> Bool {
        APIClient.localTimetableDocumentURL(for: document) != nil
    }

    func open(_ document: TimetableDocument) {
        Task {
            downloadingDocumentIDs.insert(document.id)
            defer { downloadingDocumentIDs.remove(document.id) }

            do {
                previewDocument = PreviewDocument(url: try await APIClient.downloadTimetableDocument(document))
            } catch {
                errorMessage = "Unable to download this timetable document."
            }
        }
    }
}

struct TimetableDocumentsView: View {
    @State private var viewModel: TimetableDocumentsViewModel
    let title: String

    init(serviceID: Int? = nil, title: String = "Timetables") {
        _viewModel = State(initialValue: TimetableDocumentsViewModel(serviceID: serviceID))
        self.title = title
    }

    var body: some View {
        List {
            if viewModel.isLoading, viewModel.documents.isEmpty {
                ProgressView()
            }

            ForEach(groupedDocuments, id: \.key) { group in
                Section(group.key) {
                    ForEach(group.value) { document in
                        Button {
                            viewModel.open(document)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.colorTint)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.title)
                                        .foregroundStyle(.primary)
                                    Text(document.organisationName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if viewModel.isDownloading(document) {
                                    ProgressView()
                                } else if viewModel.isDownloaded(document) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if !viewModel.isLoading, viewModel.documents.isEmpty {
                Text("No timetable documents available.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
        .task {
            await viewModel.loadDocuments()
        }
        .refreshable {
            await viewModel.loadDocuments()
        }
        .sheet(item: previewDocumentBinding) { item in
            QuickLookPreview(url: item.url)
        }
        .alert("Timetables", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var groupedDocuments: [(key: String, value: [TimetableDocument])] {
        Dictionary(grouping: viewModel.documents, by: \.organisationName)
            .mapValues { documents in
                documents.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private var previewDocumentBinding: Binding<PreviewDocument?> {
        Binding(
            get: { viewModel.previewDocument },
            set: { viewModel.previewDocument = $0 }
        )
    }
}

struct PreviewDocument: Identifiable {
    let id = UUID()
    let url: URL
}

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            url as NSURL
        }
    }
}
