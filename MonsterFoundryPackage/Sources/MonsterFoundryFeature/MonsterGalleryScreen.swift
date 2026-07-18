import SwiftUI
import UIKit

struct MonsterGalleryScreen: View {
    let library: CreationLibrary
    let onBack: () -> Void
    let onSelect: (SavedCreation) -> Void
    let onContinueStory: (SavedCreation) -> Void
    let onNewScene: (SavedCreation) -> Void
    let onMakeMovie: (SavedCreation, VideoLength) -> Void

    @State private var query = ""
    @State private var filter: CreationFilter = .all
    @State private var sortOrder: CreationSortOrder = .newest

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 16) {
                header

                if library.creations.isEmpty {
                    emptyLibraryState
                } else {
                    controls

                    if visibleCreations.isEmpty {
                        noMatchesState
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: proxy.size.width > 700 ? 300 : 245), spacing: 16)],
                                spacing: 16
                            ) {
                                ForEach(visibleCreations) { creation in
                                    CreationCard(
                                        creation: creation,
                                        imageData: library.imageData(for: creation),
                                        shareURLs: library.shareItems(for: creation),
                                        onOpen: { onSelect(creation) },
                                        onContinueStory: { onContinueStory(creation) },
                                        onNewScene: { onNewScene(creation) },
                                        onMakeMovie: { onMakeMovie(creation, $0) },
                                        onToggleFavorite: { library.setFavorite(!creation.isPinned, for: creation.id) },
                                        onDelete: { library.delete(creation) }
                                    )
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .frame(maxWidth: 1_360, maxHeight: .infinity)
            .padding(.horizontal, proxy.size.width > 650 ? 28 : 16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("monsterGalleryScreen")
    }

    private var visibleCreations: [SavedCreation] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return library.creations
            .filter { filter.includes($0) }
            .filter { creation in
                guard !search.isEmpty else { return true }
                return [
                    creation.profile.name,
                    creation.profile.species,
                    creation.profile.backstory,
                    creation.profile.personality,
                    creation.creaturePrompt,
                ].contains { $0.localizedCaseInsensitiveContains(search) }
            }
            .sorted { lhs, rhs in
                // Favourites float to the top regardless of sort order.
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                return sortOrder == .newest ? lhs.createdAt > rhs.createdAt : lhs.createdAt < rhs.createdAt
            }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.black))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.09), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel("Back to the foundry")

            VStack(alignment: .leading, spacing: 2) {
                Text("MY CREATIONS")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .tracking(2)
                    .foregroundStyle(MonsterTheme.mango)
                Text(library.creations.isEmpty ? "Your shelf is waiting" : "\(library.creations.count) adventure\(library.creations.count == 1 ? "" : "s") ready to replay")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "rectangle.stack.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(MonsterTheme.mint)
        }
    }

    private var controls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                searchField
                    .frame(maxWidth: 340)
                filterStrip
                sortMenu
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    searchField
                    sortMenu
                }
                filterStrip
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.42))
            TextField("Search names and stories", text: $query)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.42))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 44)
        .background(.white.opacity(0.09), in: Capsule())
        .accessibilityIdentifier("creationSearchField")
    }

    private var filterStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                ForEach(CreationFilter.allCases) { choice in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { filter = choice }
                    } label: {
                        Label(choice.title, systemImage: choice.symbol)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(filter == choice ? MonsterTheme.ink : .white.opacity(0.72))
                            .padding(.horizontal, 11)
                            .frame(height: 40)
                            .background(filter == choice ? MonsterTheme.mango : .white.opacity(0.08), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == choice ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Order", selection: $sortOrder) {
                ForEach(CreationSortOrder.allCases) { order in
                    Label(order.title, systemImage: order.symbol).tag(order)
                }
            }
        } label: {
            Image(systemName: sortOrder.symbol)
                .font(.headline.weight(.bold))
                .foregroundStyle(MonsterTheme.mint)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.09), in: Circle())
        }
        .accessibilityLabel("Sort \(sortOrder.title)")
        .accessibilityIdentifier("creationSortMenu")
    }

    private var emptyLibraryState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(MonsterTheme.purple.opacity(0.22))
                    .frame(width: 190, height: 190)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(MonsterTheme.mango)
            }
            Text("No creations live here yet")
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundStyle(.white)
            Text("Draw or describe anything—a creature, robot, vehicle, person, or impossible object—and its image, story, voice, and movie can live here.")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.56))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)
            Button("Create the first adventure", action: onBack)
                .buttonStyle(PrimaryMonsterButtonStyle())
                .frame(maxWidth: 380)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noMatchesState: some View {
        ContentUnavailableView {
            Label("Nothing matches yet", systemImage: "sparkle.magnifyingglass")
                .foregroundStyle(.white)
        } description: {
            Text("Try another search or choose a different creation type.")
                .foregroundStyle(.white.opacity(0.55))
        } actions: {
            Button("Show everything") {
                query = ""
                filter = .all
            }
            .buttonStyle(.borderedProminent)
            .tint(MonsterTheme.mango)
            .foregroundStyle(MonsterTheme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum CreationFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case movies
    case stories
    case postcards

    var id: Self { self }
    var title: String { self == .favorites ? "Favorites" : rawValue.capitalized }

    var symbol: String {
        switch self {
        case .all: "sparkles.rectangle.stack.fill"
        case .favorites: "star.fill"
        case .movies: "film.fill"
        case .stories: "book.fill"
        case .postcards: "photo.fill"
        }
    }

    func includes(_ creation: SavedCreation) -> Bool {
        switch self {
        case .all: true
        case .favorites: creation.isPinned
        case .movies: creation.videoFileName != nil || creation.brief.output.includesVideo
        case .stories: creation.brief.output.includesLongStory
        case .postcards: creation.brief.output == .postcard
        }
    }
}

private enum CreationSortOrder: String, CaseIterable, Identifiable {
    case newest
    case oldest

    var id: Self { self }
    var title: String { rawValue.capitalized }
    var symbol: String { self == .newest ? "arrow.down.circle.fill" : "arrow.up.circle.fill" }
}

private struct CreationCard: View {
    let creation: SavedCreation
    let imageData: Data?
    let shareURLs: [URL]
    let onOpen: () -> Void
    let onContinueStory: () -> Void
    let onNewScene: () -> Void
    let onMakeMovie: (VideoLength) -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    @State private var confirmsDelete = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        thumbnail
                        HStack(spacing: 5) {
                            if creation.narrationFileName != nil {
                                mediaBadge(title: "VOICE", symbol: "waveform")
                            }
                            if creation.videoFileName != nil {
                                mediaBadge(title: "MOVIE", symbol: "play.fill")
                            }
                        }
                        .padding(10)

                        if creation.isPinned {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(MonsterTheme.ink)
                                .padding(7)
                                .background(MonsterTheme.mango, in: Circle())
                                .padding(10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .aspectRatio(16 / 9, contentMode: .fit)

                    VStack(alignment: .leading, spacing: 9) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(creation.profile.name)
                                    .font(.system(.title3, design: .rounded, weight: .black))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(creation.profile.species)
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.48))
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(MonsterTheme.mango)
                        }

                        HStack(spacing: 6) {
                            GalleryChip(symbol: creation.brief.medium.symbol, text: creation.brief.medium.shortTitle)
                            GalleryChip(symbol: creation.brief.output.symbol, text: creation.brief.output.shortTitle)
                            Spacer()
                            Text(creation.createdAt, format: .dateTime.day().month(.abbreviated))
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white.opacity(0.36))
                        }
                    }
                    .padding(14)
                }
            }
            .buttonStyle(.plain)

            Divider().overlay(.white.opacity(0.10))

            HStack(spacing: 8) {
                continuationButton("Next chapter", symbol: "book.pages.fill", action: onContinueStory)
                continuationButton("New scene", symbol: "movieclapper.fill", action: onNewScene)
                overflowMenu
            }
            .padding(10)
        }
        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
        .contextMenu {
            cardActions
        }
        .confirmationDialog("Delete \(creation.profile.name)?", isPresented: $confirmsDelete) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Its saved picture, narration, and movie will be removed from this device.")
        }
        .accessibilityElement(children: .contain)
    }

    private func continuationButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(.caption2, design: .rounded, weight: .black))
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(.white.opacity(0.07), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var overflowMenu: some View {
        Menu {
            cardActions
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(.subheadline, design: .rounded, weight: .black))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 46, height: 36)
                .background(.white.opacity(0.07), in: Capsule())
        }
        .accessibilityLabel("More actions for \(creation.profile.name)")
    }

    @ViewBuilder
    private var cardActions: some View {
        Button(
            creation.isPinned ? "Unpin from top" : "Add to favorites",
            systemImage: creation.isPinned ? "star.slash" : "star.fill",
            action: onToggleFavorite
        )

        if let shareURL = shareURLs.first {
            ShareLink(item: shareURL) {
                Label(
                    creation.videoFileName != nil ? "Share movie" : "Share picture",
                    systemImage: "square.and.arrow.up"
                )
            }
        }

        Menu {
            ForEach(VideoLength.allCases) { length in
                Button("\(length.rawValue) seconds") { onMakeMovie(length) }
            }
        } label: {
            Label(creation.videoFileName != nil ? "Make a new movie" : "Make a movie", systemImage: "film.badge.plus")
        }

        Button("Delete creation", systemImage: "trash", role: .destructive) {
            confirmsDelete = true
        }
    }

    private func mediaBadge(title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(MonsterTheme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(MonsterTheme.mint, in: Capsule())
    }

    private var thumbnail: some View {
        ZStack {
            LinearGradient(
                colors: [MonsterTheme.purple.opacity(0.7), MonsterTheme.pink.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "scribble.variable")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .clipped()
    }
}

private struct GalleryChip: View {
    let symbol: String
    let text: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.68))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08), in: Capsule())
    }
}
