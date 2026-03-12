import SwiftUI

struct AdminDealsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showAddForm = false
    @State private var editingDeal: Deal?

    var body: some View {
        VStack(spacing: 0) {
            // Stats
            HStack(spacing: 12) {
                dealStat("Total", "\(viewModel.deals.count)", AppColors.accent)
                dealStat("Live", "\(viewModel.deals.filter { $0.isLive }.count)", AppColors.success)
                dealStat("Inactive", "\(viewModel.deals.filter { !$0.isActive }.count)", AppColors.muted)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)

            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.deals.isEmpty {
                EmptyStateView(
                    icon: "flame",
                    title: "No Deals",
                    subtitle: "Add a deal to get started"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.deals) { deal in
                            AdminDealCard(
                                deal: deal,
                                onEdit: { editingDeal = deal },
                                onDelete: {
                                    if let id = deal.id {
                                        Task { await viewModel.deleteDeal(id: id) }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, 40)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showAddForm = true }) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(AppColors.accent)
                    .clipShape(Circle())
                    .shadow(radius: 6)
            }
            .padding(AppSpacing.lg)
        }
        .sheet(isPresented: $showAddForm) {
            AdminDealFormView(viewModel: viewModel, deal: nil)
        }
        .sheet(item: $editingDeal) { deal in
            AdminDealFormView(viewModel: viewModel, deal: deal)
        }
    }

    private func dealStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.sm)
    }
}

// MARK: - Deal Card

struct AdminDealCard: View {
    let deal: Deal
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Deal image
            if let url = deal.imageUrl, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    AppColors.surface
                }
                .frame(width: 60, height: 60)
                .cornerRadius(AppRadius.sm)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(AppColors.surface)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "flame")
                            .foregroundColor(AppColors.muted)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(deal.title)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text)
                        .lineLimit(1)

                    Circle()
                        .fill(deal.isLive ? AppColors.success : AppColors.error)
                        .frame(width: 8, height: 8)
                }

                if let subtitle = deal.subtitle {
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if let pct = deal.discountPercentage {
                        Text("\(Int(pct))% OFF")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.accent)
                    }
                    if let cat = deal.categoryId {
                        Text(cat)
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.muted)
                    }
                }

                if let start = deal.startsAt, let end = deal.endsAt {
                    Text("\(start, style: .date) – \(end, style: .date)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.muted)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.accent)
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.error)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }
}

// MARK: - Deal Form

struct AdminDealFormView: View {
    @ObservedObject var viewModel: AdminViewModel
    let deal: Deal?
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var subtitle = ""
    @State private var imageUrl = ""
    @State private var discountPercentage = ""
    @State private var categoryId = ""
    @State private var startsAt = Date()
    @State private var endsAt = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var isActive = true

    private let categories = ["dress", "apparel", "tshirt", "bag", "shoes", "accessories"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    dealFormField("Title") {
                        TextField("e.g. Summer Sale", text: $title)
                            .dealFormStyle()
                    }

                    dealFormField("Subtitle (optional)") {
                        TextField("e.g. Up to 40% off", text: $subtitle)
                            .dealFormStyle()
                    }

                    dealFormField("Image URL (optional)") {
                        TextField("https://...", text: $imageUrl)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .dealFormStyle()
                    }

                    if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 120)
                        .cornerRadius(AppRadius.md)
                        .clipped()
                    }

                    dealFormField("Discount Percentage") {
                        TextField("e.g. 30", text: $discountPercentage)
                            .keyboardType(.decimalPad)
                            .dealFormStyle()
                    }

                    dealFormField("Category") {
                        Picker("Category", selection: $categoryId) {
                            Text("None").tag("")
                            ForEach(categories, id: \.self) { cat in
                                Text(cat.capitalized).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.accent)
                    }

                    DatePicker("Starts At", selection: $startsAt, displayedComponents: .date)
                        .foregroundColor(AppColors.text)
                        .tint(AppColors.accent)

                    DatePicker("Ends At", selection: $endsAt, displayedComponents: .date)
                        .foregroundColor(AppColors.text)
                        .tint(AppColors.accent)

                    Toggle("Active", isOn: $isActive)
                        .foregroundColor(AppColors.text)
                        .tint(AppColors.accent)

                    Button(action: save) {
                        Text(deal == nil ? "Add Deal" : "Update Deal")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(EloraPrimaryButton())
                    .disabled(title.isEmpty)
                    .padding(.top, AppSpacing.md)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(deal == nil ? "New Deal" : "Edit Deal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .onAppear { loadExisting() }
    }

    private func loadExisting() {
        guard let d = deal else { return }
        title = d.title
        subtitle = d.subtitle ?? ""
        imageUrl = d.imageUrl ?? ""
        if let pct = d.discountPercentage { discountPercentage = "\(pct)" }
        categoryId = d.categoryId ?? ""
        if let s = d.startsAt { startsAt = s }
        if let e = d.endsAt { endsAt = e }
        isActive = d.isActive
    }

    private func save() {
        var d = deal ?? Deal(title: "", isActive: true)
        d.title = title
        d.subtitle = subtitle.isEmpty ? nil : subtitle
        d.imageUrl = imageUrl.isEmpty ? nil : imageUrl
        d.discountPercentage = Double(discountPercentage)
        d.categoryId = categoryId.isEmpty ? nil : categoryId
        d.startsAt = startsAt
        d.endsAt = endsAt
        d.isActive = isActive

        Task {
            if deal?.id != nil {
                await viewModel.updateDeal(d)
            } else {
                await viewModel.addDeal(d)
            }
            dismiss()
        }
    }

    private func dealFormField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)
            content()
        }
    }
}

// MARK: - Deal Form TextField Style

private extension View {
    func dealFormStyle() -> some View {
        self
            .font(AppFonts.body)
            .foregroundColor(AppColors.text)
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(AppColors.line, lineWidth: 1)
            )
    }
}
