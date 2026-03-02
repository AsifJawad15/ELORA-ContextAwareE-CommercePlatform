import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class FirestoreSeeder {
    static let shared = FirestoreSeeder()
    private init() {}

    private let db = Firestore.firestore()
    private let seededKey = "didSeedProducts_v5"

    /// Seeds sample products, deals, and coupons on first launch.
    func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        let batch = db.batch()

        // MARK: - Products (using picsum.photos for reliable images)
        let products: [[String: Any]] = [
            [
                "name": "Silk Evening Dress",
                "price": 289.00,
                "imageUrl": "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&q=80",
                "description": "Elegant silk evening dress with a flattering silhouette. Perfect for formal occasions and galas.",
                "categoryId": "dress",
                "brand": "ELORA Couture",
                "sizes": ["XS", "S", "M", "L", "XL"],
                "colors": ["Black", "Burgundy", "Navy"],
                "stock": 25,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Cashmere Wrap Coat",
                "price": 450.00,
                "imageUrl": "https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400&q=80",
                "description": "Luxurious cashmere wrap coat with belt. Incredibly soft and warm for the winter season.",
                "categoryId": "apparel",
                "brand": "ELORA Collection",
                "sizes": ["S", "M", "L"],
                "colors": ["Camel", "Grey", "Black"],
                "stock": 15,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Leather Crossbody Bag",
                "price": 185.00,
                "imageUrl": "https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&q=80",
                "description": "Handcrafted genuine leather crossbody bag with gold-tone hardware. Spacious interior with multiple compartments.",
                "categoryId": "bag",
                "brand": "ELORA Accessories",
                "colors": ["Tan", "Black", "Olive"],
                "stock": 40,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Classic White Tee",
                "price": 59.00,
                "imageUrl": "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&q=80",
                "description": "Premium organic cotton crew-neck t-shirt. Relaxed fit with a clean, minimal design.",
                "categoryId": "tshirt",
                "brand": "ELORA Basics",
                "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
                "colors": ["White", "Black", "Grey"],
                "stock": 100,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Stiletto Heels",
                "price": 320.00,
                "imageUrl": "https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400&q=80",
                "description": "Elegant pointed-toe stiletto heels crafted from Italian leather. 4-inch heel with cushioned insole.",
                "categoryId": "shoes",
                "brand": "ELORA Luxe",
                "sizes": ["36", "37", "38", "39", "40", "41"],
                "colors": ["Black", "Red", "Nude"],
                "stock": 20,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Pearl Drop Earrings",
                "price": 95.00,
                "imageUrl": "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400&q=80",
                "description": "Freshwater pearl drop earrings with sterling silver posts. Timeless elegance for everyday wear.",
                "categoryId": "accessories",
                "brand": "ELORA Jewels",
                "colors": ["Silver", "Gold"],
                "stock": 50,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Linen Blazer",
                "price": 210.00,
                "imageUrl": "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400&q=80",
                "description": "Unstructured linen blazer in a relaxed fit. Perfect for layering in warmer months.",
                "categoryId": "apparel",
                "brand": "ELORA Collection",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["Ecru", "Blue", "Sage"],
                "stock": 30,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Canvas Tote Bag",
                "price": 75.00,
                "imageUrl": "https://images.unsplash.com/photo-1544816155-12df9643f363?w=400&q=80",
                "description": "Durable canvas tote with leather straps. Roomy interior with inner zippered pocket.",
                "categoryId": "bag",
                "brand": "ELORA Accessories",
                "colors": ["Natural", "Black", "Navy"],
                "stock": 60,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Floral Maxi Dress",
                "price": 198.00,
                "imageUrl": "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&q=80",
                "description": "Flowing floral maxi dress with adjustable straps. Lightweight fabric ideal for summer events.",
                "categoryId": "dress",
                "brand": "ELORA Couture",
                "sizes": ["XS", "S", "M", "L"],
                "colors": ["Floral Blue", "Floral Pink"],
                "stock": 35,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Graphic Tee — Art Series",
                "price": 69.00,
                "imageUrl": "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&q=80",
                "description": "Limited edition graphic tee featuring exclusive artwork. Boxy fit, 100% organic cotton.",
                "categoryId": "tshirt",
                "brand": "ELORA Basics",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["White", "Black"],
                "stock": 45,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Suede Chelsea Boots",
                "price": 275.00,
                "imageUrl": "https://images.unsplash.com/photo-1638247025967-b4e38f787b76?w=400&q=80",
                "description": "Premium suede Chelsea boots with elastic side panels. Water-resistant treated finish.",
                "categoryId": "shoes",
                "brand": "ELORA Luxe",
                "sizes": ["38", "39", "40", "41", "42", "43"],
                "colors": ["Tan", "Black"],
                "stock": 22,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Gold Chain Necklace",
                "price": 145.00,
                "imageUrl": "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=400&q=80",
                "description": "18K gold-plated chain necklace. Adjustable length with lobster clasp closure.",
                "categoryId": "accessories",
                "brand": "ELORA Jewels",
                "colors": ["Gold"],
                "stock": 55,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ]
        ]

        for product in products {
            let docRef = db.collection("products").document()
            batch.setData(product, forDocument: docRef)
        }

        // MARK: - Deals
        let deals: [[String: Any]] = [
            [
                "title": "Summer Collection Sale",
                "subtitle": "Refresh your wardrobe with our latest picks",
                "discountPercentage": 30.0,
                "categoryId": "dress",
                "isActive": true,
                "startsAt": Timestamp(date: Date()),
                "endsAt": Timestamp(date: Date().addingTimeInterval(30 * 24 * 3600))
            ],
            [
                "title": "New Arrivals — Bags",
                "subtitle": "Explore our new leather collection",
                "discountPercentage": 15.0,
                "categoryId": "bag",
                "isActive": true,
                "startsAt": Timestamp(date: Date()),
                "endsAt": Timestamp(date: Date().addingTimeInterval(14 * 24 * 3600))
            ]
        ]

        for deal in deals {
            let docRef = db.collection("deals").document()
            batch.setData(deal, forDocument: docRef)
        }

        // MARK: - Coupons
        let coupons: [[String: Any]] = [
            [
                "code": "WELCOME10",
                "discountType": "percentage",
                "discountValue": 10.0,
                "minOrderAmount": 50.0,
                "maxDiscount": 25.0,
                "isActive": true,
                "expiresAt": Timestamp(date: Date().addingTimeInterval(90 * 24 * 3600))
            ],
            [
                "code": "ELORA20",
                "discountType": "percentage",
                "discountValue": 20.0,
                "minOrderAmount": 100.0,
                "maxDiscount": 50.0,
                "isActive": true,
                "expiresAt": Timestamp(date: Date().addingTimeInterval(60 * 24 * 3600))
            ],
            [
                "code": "FLAT15",
                "discountType": "fixed",
                "discountValue": 15.0,
                "minOrderAmount": 75.0,
                "isActive": true,
                "expiresAt": Timestamp(date: Date().addingTimeInterval(45 * 24 * 3600))
            ]
        ]

        for coupon in coupons {
            let docRef = db.collection("coupons").document()
            batch.setData(coupon, forDocument: docRef)
        }

        // Commit
        batch.commit { [weak self] error in
            if let error = error {
                print("Seeder error: \(error.localizedDescription)")
                return
            }
            UserDefaults.standard.set(true, forKey: self?.seededKey ?? "")
            print("✅ Seeded 12 products, 2 deals, 3 coupons")
        }
    }
}
