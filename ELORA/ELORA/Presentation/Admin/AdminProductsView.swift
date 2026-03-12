import SwiftUI

// MARK: - Admin Products List

struct AdminProductsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showAddSheet = false
    @State private var editingProduct: Product?
    @State private var searchText = ""

    private var filteredProducts: [Product] {
        if searchText.isEmpty { return viewModel.products }
        let q = searchText.lowercased()
        return viewModel.products.filter {
            $0.name.lowercased().contains(q) ||
            ($0.brand?.lowercased().contains(q) ?? false) ||
            ($0.categoryId?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search + Add
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.muted)
                    TextField("Search products...", text: $searchText)
                        .foregroundColor(AppColors.text)
                        .font(AppFonts.subheadline)
                }
                .padding(10)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)

            // Stats
            HStack(spacing: 16) {
                statBadge(label: "Total", value: "\(viewModel.products.count)")
                statBadge(label: "Featured", value: "\(viewModel.products.filter { $0.isFeatured == true }.count)")
                statBadge(label: "Low Stock", value: "\(viewModel.products.filter { ($0.stock ?? 0) < 10 }.count)")
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)

            if viewModel.isLoading {
                LoadingView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredProducts) { product in
                            AdminProductRow(
                                product: product,
                                onEdit: { editingProduct = product },
                                onDelete: {
                                    if let id = product.id {
                                        Task { await viewModel.deleteProduct(id: id) }
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
        .sheet(isPresented: $showAddSheet) {
            AdminProductFormView(viewModel: viewModel, product: nil)
        }
        .sheet(item: $editingProduct) { product in
            AdminProductFormView(viewModel: viewModel, product: product)
        }
    }

    private func statBadge(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.accent)
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

// MARK: - Product Row

struct AdminProductRow: View {
    let product: Product
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    AppColors.surface.overlay(
                        Image(systemName: "photo").foregroundColor(AppColors.muted)
                    )
                }
            }
            .frame(width: 55, height: 55)
            .clipped()
            .cornerRadius(AppRadius.sm)

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.accent)

                    if let cat = product.categoryId {
                        Text(cat)
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.muted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.card)
                            .cornerRadius(4)
                    }

                    if product.isFeatured == true {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.warning)
                    }
                }

                Text("Stock: \(product.stock ?? 0)")
                    .font(AppFonts.caption2)
                    .foregroundColor(
                        (product.stock ?? 0) < 10 ? AppColors.error : AppColors.muted
                    )
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.accent)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.error)
                }
            }
        }
        .padding(10)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }
}

// MARK: - Product Form (Add / Edit)

struct AdminProductFormView: View {
    @ObservedObject var viewModel: AdminViewModel
    let product: Product?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var price = ""
    @State private var imageUrl = ""
    @State private var description = ""
    @State private var categoryId = "apparel"
    @State private var brand = ""
    @State private var sizesText = ""
    @State private var colorsText = ""
    @State private var stock = ""
    @State private var isFeatured = false

    private let categories = ["apparel", "dress", "tshirt", "bag", "shoes", "accessories"]

    var isEditing: Bool { product != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        Group {
                            formField("Product Name", text: $name)
                            formField("Price (USD)", text: $price)
                                .keyboardType(.decimalPad)
                            formField("Image URL", text: $imageUrl)
                            formField("Brand", text: $brand)
                            formField("Stock", text: $stock)
                                .keyboardType(.numberPad)
                        }

                        // Category Picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CATEGORY")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.muted)
                            Picker("Category", selection: $categoryId) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat.capitalized).tag(cat)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(AppColors.accent)
                        }

                        formField("Sizes (comma-separated)", text: $sizesText)
                        formField("Colors (comma-separated)", text: $colorsText)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("DESCRIPTION")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.muted)
                            TextEditor(text: $description)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(AppColors.surface)
                                .cornerRadius(AppRadius.sm)
                                .foregroundColor(AppColors.text)
                                .scrollContentBackground(.hidden)
                        }

                        Toggle(isOn: $isFeatured) {
                            Text("Featured Product")
                                .font(AppFonts.subheadline)
                                .foregroundColor(AppColors.text)
                        }
                        .tint(AppColors.accent)

                        // Image Preview
                        if !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(AppRadius.md)
                                default:
                                    EmptyView()
                                }
                            }
                        }

                        Button(action: saveProduct) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isEditing ? "UPDATE PRODUCT" : "ADD PRODUCT")
                            }
                        }
                        .buttonStyle(EloraPrimaryButton(fullWidth: true))
                        .disabled(viewModel.isLoading || name.isEmpty || price.isEmpty)
                        .padding(.top, AppSpacing.sm)
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle(isEditing ? "Edit Product" : "Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .onAppear { populateFields() }
    }

    private func populateFields() {
        guard let p = product else { return }
        name = p.name
        price = String(format: "%.2f", p.price)
        imageUrl = p.imageUrl
        description = p.description ?? ""
        categoryId = p.categoryId ?? "apparel"
        brand = p.brand ?? ""
        sizesText = p.sizes?.joined(separator: ", ") ?? ""
        colorsText = p.colors?.joined(separator: ", ") ?? ""
        stock = "\(p.stock ?? 0)"
        isFeatured = p.isFeatured ?? false
    }

    private func saveProduct() {
        let parsedPrice = Double(price) ?? 0
        let parsedStock = Int(stock) ?? 0
        let sizes = sizesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let colors = colorsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        Task {
            if let id = product?.id {
                await viewModel.updateProduct(
                    id: id, name: name, price: parsedPrice, imageUrl: imageUrl,
                    description: description, categoryId: categoryId, brand: brand,
                    sizes: sizes, colors: colors, stock: parsedStock, isFeatured: isFeatured
                )
            } else {
                await viewModel.addProduct(
                    name: name, price: parsedPrice, imageUrl: imageUrl,
                    description: description, categoryId: categoryId, brand: brand,
                    sizes: sizes, colors: colors, stock: parsedStock, isFeatured: isFeatured
                )
            }
            dismiss()
        }
    }

    private func formField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.muted)
            TextField(label, text: text)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.text)
                .padding(10)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.sm)
        }
    }
}
