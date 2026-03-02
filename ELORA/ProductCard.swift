import SwiftUI

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading) {

            ZStack {
                AsyncImage(url: URL(string: product.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure(_):
                        fallbackView

                    case .empty:
                        ProgressView()

                    @unknown default:
                        fallbackView
                    }
                }
            }
            .frame(height: 140)
            .clipped()
            .cornerRadius(8)

            Text(product.name)
                .font(.headline)
                .lineLimit(1)

            Text("$\(product.price, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    // MARK: - Fallback (Alt Text Equivalent)

    private var fallbackView: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.gray)

            Text(product.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.15))
    }
}
