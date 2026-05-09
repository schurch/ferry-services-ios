import Observation
import QuickLook
import SwiftUI

@MainActor
@Observable
final class TimetableDocumentsViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case downloaded

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                "All Timetables"
            case .downloaded:
                "Downloaded"
            }
        }
    }

    var documents: [TimetableDocument] = []
    var isLoading = false
    var errorMessage: String?
    var previewURL: URL?
    var selectedFilter: Filter = .all

    private let serviceID: Int?
    private var downloadingDocumentIDs: Set<Int> = []
    private var downloadedDocumentIDs: Set<Int> = []

    init(serviceID: Int? = nil) {
        self.serviceID = serviceID
    }

    func loadDocuments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            documents = try await APIClient.fetchTimetableDocuments(serviceID: serviceID)
            refreshDownloadedDocumentIDs()
        } catch {
            refreshDownloadedDocumentIDs()
            errorMessage = "Unable to load timetable documents."
        }
    }

    func isDownloading(_ document: TimetableDocument) -> Bool {
        downloadingDocumentIDs.contains(document.id)
    }

    func isDownloaded(_ document: TimetableDocument) -> Bool {
        downloadedDocumentIDs.contains(document.id)
    }

    var filteredDocuments: [TimetableDocument] {
        switch selectedFilter {
        case .all:
            documents
        case .downloaded:
            documents.filter(isDownloaded)
        }
    }

    func open(_ document: TimetableDocument) {
        Task {
            downloadingDocumentIDs.insert(document.id)
            defer { downloadingDocumentIDs.remove(document.id) }

            do {
                previewURL = try await APIClient.downloadTimetableDocument(document)
                downloadedDocumentIDs.insert(document.id)
            } catch {
                errorMessage = downloadErrorMessage(for: document, error: error)
            }
        }
    }

    func delete(_ document: TimetableDocument) {
        do {
            let localURL = APIClient.localTimetableDocumentURL(for: document)
            try APIClient.deleteLocalTimetableDocument(document)
            downloadedDocumentIDs.remove(document.id)
            if previewURL == localURL {
                previewURL = nil
            }
        } catch {
            errorMessage = "Couldn’t remove the downloaded timetable. Please try again."
        }
    }

    private func downloadErrorMessage(for document: TimetableDocument, error: Error) -> String {
        let title = document.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let documentName = title.isEmpty ? "this timetable" : "\"\(title)\""

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
                return "Couldn’t download \(documentName). Check your connection and try again."
            default:
                break
            }
        }

        return "Couldn’t download \(documentName) right now. Please try again."
    }

    private func refreshDownloadedDocumentIDs() {
        downloadedDocumentIDs = Set(
            documents
                .filter { APIClient.localTimetableDocumentURL(for: $0) != nil }
                .map(\.id)
        )
    }
}

struct TimetableDocumentsView: View {
    private struct DocumentGroup: Identifiable {
        let name: String
        let imageName: String?
        let documents: [TimetableDocument]

        var id: String { name }
    }

    @State private var viewModel: TimetableDocumentsViewModel
    let title: String

    init(serviceID: Int? = nil, title: String = "Timetables") {
        _viewModel = State(initialValue: TimetableDocumentsViewModel(serviceID: serviceID))
        self.title = title
    }

    var body: some View {
        ZStack {
            List {
                ForEach(groupedDocuments) { group in
                    Section {
                        ForEach(group.documents) { document in
                            Button {
                                viewModel.open(document)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(displayTitle(for: document))
                                            .foregroundStyle(.primary)

                                        if let subtitle = subtitle(for: document) {
                                            Text(subtitle)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
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
                                .padding(.top, 2)
                                .padding(.bottom, 2)
                            }
                            .accessibilityElement(children: .combine)
                            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if viewModel.isDownloaded(document) {
                                    Button {
                                        viewModel.delete(document)
                                    } label: {
                                        Label("Delete Download", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                    } header: {
                        HStack(spacing: 8) {
                            if let imageName = group.imageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25)
                                    .accessibilityHidden(true)
                            }

                            Text(group.name)
                        }
                    }
                }
            }
            .opacity(shouldShowPlaceholder ? 0 : 1)

            if shouldShowPlaceholder {
                placeholderView
            }
        }
        .navigationTitle(title)
        .background(.colorBackground)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Filter", selection: $viewModel.selectedFilter) {
                        ForEach(TimetableDocumentsViewModel.Filter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.selectedFilter == .downloaded ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .task {
            await viewModel.loadDocuments()
        }
        .refreshable {
            await viewModel.loadDocuments()
        }
        .quickLookPreview(previewURLBinding)
        .alert("Timetables", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var groupedDocuments: [DocumentGroup] {
        Dictionary(grouping: viewModel.filteredDocuments, by: \.organisationName)
            .values
            .sorted { ($0.first?.organisationName ?? "").localizedCaseInsensitiveCompare($1.first?.organisationName ?? "") == .orderedAscending }
            .map { documents in
                let sortedDocuments = documents.sorted {
                    $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                let name = sortedDocuments.first?.organisationName ?? ""
                return DocumentGroup(
                    name: name,
                    imageName: Self.imageName(forOrganisationID: sortedDocuments.first?.organisationId),
                    documents: sortedDocuments
                )
            }
    }

    private var emptyStateText: String {
        switch viewModel.selectedFilter {
        case .all:
            "No timetable documents available."
        case .downloaded:
            "No downloaded timetables."
        }
    }

    private var shouldShowPlaceholder: Bool {
        groupedDocuments.isEmpty
    }

    @ViewBuilder
    private var placeholderView: some View {
        if viewModel.isLoading && viewModel.documents.isEmpty {
            ProgressView()
        } else if groupedDocuments.isEmpty {
            Text(emptyStateText)
                .foregroundStyle(.secondary)
        }
    }

    private static func imageName(forOrganisationID organisationID: Int?) -> String? {
        switch organisationID {
        case 1: return "calmac-logo"
        default: return nil
        }
    }

    private func displayTitle(for document: TimetableDocument) -> String {
        var title = document.title.trimmingCharacters(in: .whitespacesAndNewlines)

        let redundantPrefixes = [
            "\(document.organisationName): ",
            "Caledonian MacBrayne: "
        ]

        for prefix in redundantPrefixes where title.hasPrefix(prefix) {
            title.removeFirst(prefix.count)
            break
        }

        let printablePrefix = "Download a printable "
        if title.localizedLowercase.hasPrefix(printablePrefix.localizedLowercase) {
            title.removeFirst(printablePrefix.count)
        }

        if title == title.lowercased() {
            return title.localizedCapitalized
        }

        return title
    }

    private func subtitle(for document: TimetableDocument) -> String? {
        let routes = document.serviceIds
            .compactMap { serviceRoutesByID[$0] }
            .uniquedPreservingOrder()

        guard !routes.isEmpty else { return nil }

        if routes.count == 1 {
            return routes[0]
        }

        if routes.count == 2 {
            return routes.joined(separator: " • ")
        }

        return "Applies to \(routes.count) services"
    }

    private var serviceRoutesByID: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: Service.defaultServices.map { ($0.serviceId, $0.route) }
        )
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

    private var previewURLBinding: Binding<URL?> {
        Binding(
            get: { viewModel.previewURL },
            set: { viewModel.previewURL = $0 }
        )
    }
}

private extension Array where Element: Hashable {
    func uniquedPreservingOrder() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
