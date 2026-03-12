import Foundation

@MainActor
final class ShopViewModel: ObservableObject {

    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var categories: [Category] = Category.defaultCategories
    @Published var selectedCategory: String = "all"
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productRepo: ProductRepository

    init(productRepo: ProductRepository = FirebaseProductRepository()) {
        self.productRepo = productRepo
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await productRepo.fetchProducts()
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectCategory(_ categoryId: String) {
        selectedCategory = categoryId
        applyFilters()
    }

    func search(_ query: String) {
        searchQuery = query
        applyFilters()
    }

    private func applyFilters() {
        var result = products

        // Category filter
        if selectedCategory != "all" {
            result = result.filter {
                $0.categoryId?.lowercased() == selectedCategory.lowercased()
            }
        }

        // Search filter
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                ($0.description?.lowercased().contains(q) ?? false) ||
                ($0.brand?.lowercased().contains(q) ?? false)
            }
        }

        filteredProducts = result
    }
}
