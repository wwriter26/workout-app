import SwiftUI
import PhotosUI

// MARK: - Progress Photos View
/// Biweekly physique check-in: grid of past entries (reverse-chronological) and a
/// sheet to add a new one with front/side/back photos + bodyweight.
struct ProgressPhotosView: View {
    @Environment(AppState.self) private var state
    @State private var showNewEntry = false

    private var sortedEntries: [PhotoEntry] {
        state.photoEntries.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            AppColor.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    newEntryButton
                    if sortedEntries.isEmpty {
                        emptyState
                    } else {
                        photoGrid
                    }
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Progress Photos")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNewEntry) {
            NewPhotoEntryView(seasonColor: state.season.color) { entry in
                state.photoEntries.append(entry)
            }
        }
    }

    // MARK: - Subviews

    private var newEntryButton: some View {
        Button {
            showNewEntry = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("+ NEW ENTRY")
                    .font(.system(size: 13, weight: .heavy, design: .default))
                    .tracking(1)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(state.season.color)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(AppColor.textFaint)
            Text("No progress photos yet.")
                .font(.appSubhead)
                .foregroundColor(AppColor.textMuted)
            Text("Add your first check-in every two weeks to track visual progress.")
                .font(.appSmall)
                .foregroundColor(AppColor.textDimmed)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var photoGrid: some View {
        VStack(spacing: 12) {
            ForEach(sortedEntries) { entry in
                PhotoEntryCard(entry: entry)
            }
        }
    }
}

// MARK: - Photo Entry Card
private struct PhotoEntryCard: View {
    let entry: PhotoEntry
    @State private var fullScreenImage: UIImage? = nil

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                // Header: date + optional bodyweight
                HStack {
                    Text(entry.date)
                        .font(.appSubhead)
                        .foregroundColor(AppColor.textPrimary)
                    Spacer()
                    if let weight = entry.weightLbs {
                        Text(String(format: "%.1f lbs", weight))
                            .font(.monoSmall)
                            .foregroundColor(AppColor.textMuted)
                    }
                }

                // Three thumbnail slots
                HStack(spacing: 8) {
                    ForEach(["Front": entry.frontURL, "Side": entry.sideURL, "Back": entry.backURL].sorted(by: { $0.key < $1.key }), id: \.key) { label, path in
                        PhotoThumbnail(label: label, path: path) { image in
                            fullScreenImage = image
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $fullScreenImage) { image in
            FullScreenPhotoView(image: image)
        }
    }
}

// MARK: - Photo Thumbnail
private struct PhotoThumbnail: View {
    let label: String
    let path: String?
    let onTap: (UIImage) -> Void

    private var image: UIImage? {
        guard let path else { return nil }
        return PhotoManager.load(fromPath: path)
    }

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let img = image {
                    Button {
                        onTap(img)
                    } label: {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 90)
                            .clipped()
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Placeholder when no photo taken for this side
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColor.cardBackground2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 90)
                        .overlay(
                            Image(systemName: "camera")
                                .font(.system(size: 20))
                                .foregroundColor(AppColor.textFaint)
                        )
                }
            }

            Text(label)
                .font(.monoTiny)
                .foregroundColor(AppColor.textDimmed)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Full Screen Photo View
private struct FullScreenPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            // Clamp to prevent extreme zooms
                            if scale < 1 { scale = 1; lastScale = 1 }
                            if scale > 5 { scale = 5; lastScale = 5 }
                        }
                )

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(16)
            }
            .accessibilityLabel("Close photo")
        }
    }
}

// MARK: - UIImage Identifiable conformance
// Needed to use fullScreenCover(item:).
extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

// MARK: - New Photo Entry View
struct NewPhotoEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let seasonColor: Color
    let onSave: (PhotoEntry) -> Void

    @State private var weighLbsText = ""
    @State private var frontItem: PhotosPickerItem? = nil
    @State private var sideItem: PhotosPickerItem? = nil
    @State private var backItem: PhotosPickerItem? = nil
    @State private var frontImage: UIImage? = nil
    @State private var sideImage: UIImage? = nil
    @State private var backImage: UIImage? = nil
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        weighSection
                        photoPickerSection
                        if let err = errorMessage {
                            Text(err)
                                .font(.appSmall)
                                .foregroundColor(AppColor.fall)
                        }
                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(seasonColor)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Sections

    private var weighSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "Bodyweight (lbs)")
            TextField("e.g. 175.5", text: $weighLbsText)
                .font(.appBody)
                .foregroundColor(AppColor.textPrimary)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColor.cardBackground)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.border2, lineWidth: 1))
        }
    }

    private var photoPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Photos")
            Text("Select up to 3 angles. At least one photo is required to save.")
                .font(.appSmall)
                .foregroundColor(AppColor.textDimmed)

            HStack(spacing: 10) {
                photoPickerSlot(label: "Front", item: $frontItem, image: $frontImage)
                photoPickerSlot(label: "Side",  item: $sideItem,  image: $sideImage)
                photoPickerSlot(label: "Back",  item: $backItem,  image: $backImage)
            }
        }
    }

    @ViewBuilder
    private func photoPickerSlot(
        label: String,
        item: Binding<PhotosPickerItem?>,
        image: Binding<UIImage?>
    ) -> some View {
        VStack(spacing: 6) {
            PhotosPicker(
                selection: item,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ZStack {
                    if let img = image.wrappedValue {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColor.cardBackground2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppColor.textFaint)
                                    Text("CHOOSE")
                                        .font(.monoTiny)
                                        .foregroundColor(AppColor.textFaint)
                                }
                            )
                    }
                }
            }
            .onChange(of: item.wrappedValue) { _, newItem in
                Task { await loadImage(from: newItem, into: image) }
            }

            Text(label)
                .font(.monoTiny)
                .foregroundColor(AppColor.textDimmed)
        }
        .frame(maxWidth: .infinity)
    }

    private var saveButton: some View {
        let hasPhoto = frontImage != nil || sideImage != nil || backImage != nil
        return Button {
            Task { await save() }
        } label: {
            Group {
                if isSaving {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("SAVE ENTRY")
                        .font(.system(size: 13, weight: .heavy, design: .default))
                        .tracking(1)
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(hasPhoto ? seasonColor : AppColor.textFaint)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(!hasPhoto || isSaving)
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem?, into binding: Binding<UIImage?>) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            binding.wrappedValue = uiImage
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let date = Date()

        var frontPath: String?
        var sidePath: String?
        var backPath: String?

        do {
            if let img = frontImage {
                frontPath = try PhotoManager.saveProgressPhoto(img, side: .front, date: date)
            }
            if let img = sideImage {
                sidePath = try PhotoManager.saveProgressPhoto(img, side: .side, date: date)
            }
            if let img = backImage {
                backPath = try PhotoManager.saveProgressPhoto(img, side: .back, date: date)
            }
        } catch {
            errorMessage = "Failed to save photo: \(error.localizedDescription)"
            isSaving = false
            return
        }

        let dateStr = AppState.sharedDateString(from: date)
        let entry = PhotoEntry(
            date: dateStr,
            frontURL: frontPath,
            sideURL: sidePath,
            backURL: backPath,
            weightLbs: Double(weighLbsText)
        )
        onSave(entry)
        isSaving = false
        dismiss()
    }
}
