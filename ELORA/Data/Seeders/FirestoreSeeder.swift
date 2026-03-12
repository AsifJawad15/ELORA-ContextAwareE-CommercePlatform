import Foundation
import FirebaseFirestore

final class FirestoreSeeder {
    static let shared = FirestoreSeeder()
    private init() {}

    private let db = Firestore.firestore()
    private let seededKey = "didSeedProducts_v6"

    /// Seeds sample products, deals, and coupons on first launch.
    func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        let batch = db.batch()

        // MARK: - Products (expanded catalog with reliable image URLs)
        let products: [[String: Any]] = [
            // --- DRESSES ---
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
                "rating": 4.7,
                "reviewCount": 12,
                "isFeatured": true,
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
                "rating": 4.5,
                "reviewCount": 8,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Cocktail Mini Dress",
                "price": 165.00,
                "imageUrl": "https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400&q=80",
                "description": "Chic cocktail mini dress with sequin detailing. Stand out at any evening event.",
                "categoryId": "dress",
                "brand": "ELORA Couture",
                "sizes": ["XS", "S", "M", "L"],
                "colors": ["Black", "Gold", "Silver"],
                "stock": 18,
                "rating": 4.3,
                "reviewCount": 6,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Bohemian Wrap Dress",
                "price": 142.00,
                "imageUrl": "https://images.unsplash.com/photo-1612336307429-8a898d10e223?w=400&q=80",
                "description": "Free-spirited bohemian wrap dress with paisley print. Flattering V-neckline.",
                "categoryId": "dress",
                "brand": "ELORA Collection",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["Rust", "Sage", "Cream"],
                "stock": 28,
                "rating": 4.4,
                "reviewCount": 10,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],

            // --- APPAREL ---
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
                "rating": 4.8,
                "reviewCount": 15,
                "isFeatured": true,
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
                "rating": 4.6,
                "reviewCount": 9,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Wool Overcoat",
                "price": 385.00,
                "imageUrl": "https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=400&q=80",
                "description": "Classic double-breasted wool overcoat. Timeless silhouette with satin-lined interior.",
                "categoryId": "apparel",
                "brand": "ELORA Collection",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["Charcoal", "Navy", "Camel"],
                "stock": 12,
                "rating": 4.9,
                "reviewCount": 22,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Denim Jacket",
                "price": 128.00,
                "imageUrl": "https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=400&q=80",
                "description": "Classic denim jacket with brass buttons. Medium wash with slight distressing.",
                "categoryId": "apparel",
                "brand": "ELORA Basics",
                "sizes": ["XS", "S", "M", "L", "XL"],
                "colors": ["Blue", "Black", "Light Wash"],
                "stock": 42,
                "rating": 4.3,
                "reviewCount": 18,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Puffer Vest",
                "price": 175.00,
                "imageUrl": "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400&q=80",
                "description": "Lightweight puffer vest with premium down fill. Water-resistant outer shell.",
                "categoryId": "apparel",
                "brand": "ELORA Collection",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["Black", "Olive", "Navy"],
                "stock": 20,
                "rating": 4.2,
                "reviewCount": 7,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],

            // --- T-SHIRTS ---
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
                "rating": 4.5,
                "reviewCount": 45,
                "isFeatured": false,
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
                "rating": 4.1,
                "reviewCount": 12,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Striped Polo Shirt",
                "price": 78.00,
                "imageUrl": "https://images.unsplash.com/photo-1625910513413-5fc421e0fd9e?w=400&q=80",
                "description": "Cotton pique polo shirt with contrast stripes. Button-down collar for a refined look.",
                "categoryId": "tshirt",
                "brand": "ELORA Basics",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["Navy/White", "Black/Red", "Green/White"],
                "stock": 55,
                "rating": 4.2,
                "reviewCount": 14,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Oversized Vintage Tee",
                "price": 55.00,
                "imageUrl": "https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=400&q=80",
                "description": "Oversized vintage-inspired tee with faded wash. Ultra-soft pre-shrunk cotton.",
                "categoryId": "tshirt",
                "brand": "ELORA Basics",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["Washed Black", "Washed Grey", "Washed Blue"],
                "stock": 65,
                "rating": 4.0,
                "reviewCount": 8,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "V-Neck Fitted Tee",
                "price": 49.00,
                "imageUrl": "https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=400&q=80",
                "description": "Slim fit V-neck tee in soft jersey cotton. Ideal for layering or wearing solo.",
                "categoryId": "tshirt",
                "brand": "ELORA Basics",
                "sizes": ["XS", "S", "M", "L", "XL"],
                "colors": ["White", "Black", "Navy", "Olive"],
                "stock": 80,
                "rating": 4.3,
                "reviewCount": 20,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],

            // --- BAGS ---
            [
                "name": "Leather Crossbody Bag",
                "price": 185.00,
                "imageUrl": "https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&q=80",
                "description": "Handcrafted genuine leather crossbody bag with gold-tone hardware. Spacious interior with multiple compartments.",
                "categoryId": "bag",
                "brand": "ELORA Accessories",
                "colors": ["Tan", "Black", "Olive"],
                "stock": 40,
                "rating": 4.7,
                "reviewCount": 16,
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
                "rating": 4.2,
                "reviewCount": 22,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Mini Clutch Purse",
                "price": 95.00,
                "imageUrl": "https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d?w=400&q=80",
                "description": "Elegant mini clutch with detachable chain strap. Perfect for evening occasions.",
                "categoryId": "bag",
                "brand": "ELORA Accessories",
                "colors": ["Gold", "Silver", "Black"],
                "stock": 30,
                "rating": 4.4,
                "reviewCount": 11,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Backpack — Urban",
                "price": 135.00,
                "imageUrl": "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&q=80",
                "description": "Sleek urban backpack with padded laptop compartment. Water-resistant nylon shell.",
                "categoryId": "bag",
                "brand": "ELORA Accessories",
                "colors": ["Black", "Grey", "Olive"],
                "stock": 25,
                "rating": 4.5,
                "reviewCount": 19,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Woven Straw Bag",
                "price": 68.00,
                "imageUrl": "https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=400&q=80",
                "description": "Hand-woven straw tote bag. Perfect lightweight companion for beach days and brunches.",
                "categoryId": "bag",
                "brand": "ELORA Accessories",
                "colors": ["Natural", "Brown"],
                "stock": 35,
                "rating": 4.1,
                "reviewCount": 6,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],

            // --- SHOES ---
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
                "rating": 4.6,
                "reviewCount": 14,
                "isFeatured": true,
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
                "rating": 4.5,
                "reviewCount": 10,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "White Leather Sneakers",
                "price": 155.00,
                "imageUrl": "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&q=80",
                "description": "Minimalist white leather sneakers with cushioned sole. Versatile everyday footwear.",
                "categoryId": "shoes",
                "brand": "ELORA Luxe",
                "sizes": ["36", "37", "38", "39", "40", "41", "42", "43"],
                "colors": ["White", "White/Beige"],
                "stock": 50,
                "rating": 4.7,
                "reviewCount": 32,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Strappy Block Heels",
                "price": 195.00,
                "imageUrl": "https://images.unsplash.com/photo-1596703263926-eb0762ee17e4?w=400&q=80",
                "description": "Elegant strappy block heels with 3-inch heel. Comfortable enough for all-day wear.",
                "categoryId": "shoes",
                "brand": "ELORA Luxe",
                "sizes": ["36", "37", "38", "39", "40"],
                "colors": ["Black", "Nude", "Blush"],
                "stock": 18,
                "rating": 4.4,
                "reviewCount": 8,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Loafer Mules",
                "price": 168.00,
                "imageUrl": "https://images.unsplash.com/photo-1560343090-f0409e92791a?w=400&q=80",
                "description": "Slip-on loafer mules in polished leather. Gold horsebit detail for a luxe touch.",
                "categoryId": "shoes",
                "brand": "ELORA Luxe",
                "sizes": ["36", "37", "38", "39", "40", "41"],
                "colors": ["Black", "Brown", "Cream"],
                "stock": 24,
                "rating": 4.3,
                "reviewCount": 11,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Running Sneakers",
                "price": 120.00,
                "imageUrl": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80",
                "description": "Lightweight running sneakers with responsive foam midsole. Breathable knit upper.",
                "categoryId": "shoes",
                "brand": "ELORA Active",
                "sizes": ["37", "38", "39", "40", "41", "42", "43", "44"],
                "colors": ["Red/White", "Black/Grey", "Blue/White"],
                "stock": 60,
                "rating": 4.6,
                "reviewCount": 28,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],

            // --- ACCESSORIES ---
            [
                "name": "Pearl Drop Earrings",
                "price": 95.00,
                "imageUrl": "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400&q=80",
                "description": "Freshwater pearl drop earrings with sterling silver posts. Timeless elegance for everyday wear.",
                "categoryId": "accessories",
                "brand": "ELORA Jewels",
                "colors": ["Silver", "Gold"],
                "stock": 50,
                "rating": 4.6,
                "reviewCount": 20,
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
                "rating": 4.8,
                "reviewCount": 25,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Silk Scarf — Botanical",
                "price": 89.00,
                "imageUrl": "https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400&q=80",
                "description": "Luxurious silk scarf with hand-painted botanical print. Versatile styling accessory.",
                "categoryId": "accessories",
                "brand": "ELORA Accessories",
                "colors": ["Multi-Color", "Blue Tones", "Pink Tones"],
                "stock": 40,
                "rating": 4.3,
                "reviewCount": 9,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Leather Watch — Classic",
                "price": 225.00,
                "imageUrl": "https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400&q=80",
                "description": "Minimalist analog watch with genuine leather strap. Japanese quartz movement.",
                "categoryId": "accessories",
                "brand": "ELORA Time",
                "colors": ["Brown/Gold", "Black/Silver", "Tan/Rose Gold"],
                "stock": 15,
                "rating": 4.7,
                "reviewCount": 18,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Aviator Sunglasses",
                "price": 165.00,
                "imageUrl": "https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=400&q=80",
                "description": "Classic aviator sunglasses with polarized lenses. UV400 protection with metal frame.",
                "categoryId": "accessories",
                "brand": "ELORA Eyewear",
                "colors": ["Gold/Green", "Silver/Blue", "Black/Grey"],
                "stock": 35,
                "rating": 4.5,
                "reviewCount": 15,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Statement Ring Set",
                "price": 78.00,
                "imageUrl": "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=400&q=80",
                "description": "Set of 5 stackable statement rings. Mix of gold and silver-plated designs.",
                "categoryId": "accessories",
                "brand": "ELORA Jewels",
                "colors": ["Gold Set", "Silver Set", "Mixed"],
                "stock": 45,
                "rating": 4.2,
                "reviewCount": 13,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Leather Belt — Premium",
                "price": 110.00,
                "imageUrl": "https://images.unsplash.com/photo-1553062407-98eeb64c6a3e?w=400&q=80",
                "description": "Full-grain leather belt with brushed metal buckle. 35mm width with beveled edges.",
                "categoryId": "accessories",
                "brand": "ELORA Accessories",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["Brown", "Black", "Tan"],
                "stock": 30,
                "rating": 4.4,
                "reviewCount": 11,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Cashmere Beanie",
                "price": 65.00,
                "imageUrl": "https://images.unsplash.com/photo-1576871337632-b9aef4c17ab9?w=400&q=80",
                "description": "Ultra-soft cashmere beanie in a ribbed knit. Lightweight warmth for chilly days.",
                "categoryId": "accessories",
                "brand": "ELORA Collection",
                "colors": ["Charcoal", "Cream", "Camel", "Navy"],
                "stock": 50,
                "rating": 4.3,
                "reviewCount": 7,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Charm Bracelet",
                "price": 88.00,
                "imageUrl": "https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=400&q=80",
                "description": "Delicate charm bracelet with cubic zirconia stones. 14K gold-plated finish.",
                "categoryId": "accessories",
                "brand": "ELORA Jewels",
                "colors": ["Gold", "Rose Gold", "Silver"],
                "stock": 38,
                "rating": 4.5,
                "reviewCount": 16,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Knit Cardigan",
                "price": 159.00,
                "imageUrl": "https://images.unsplash.com/photo-1434389677669-e08b4cda3a00?w=400&q=80",
                "description": "Cozy knit cardigan with oversized fit. Soft wool blend with button-front closure.",
                "categoryId": "apparel",
                "brand": "ELORA Collection",
                "sizes": ["S", "M", "L", "XL"],
                "colors": ["Cream", "Grey", "Dusty Pink"],
                "stock": 28,
                "rating": 4.4,
                "reviewCount": 13,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Pleated Midi Skirt",
                "price": 112.00,
                "imageUrl": "https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=400&q=80",
                "description": "Elegant pleated midi skirt with satin finish. Elastic waistband for comfortable fit.",
                "categoryId": "apparel",
                "brand": "ELORA Couture",
                "sizes": ["XS", "S", "M", "L"],
                "colors": ["Champagne", "Black", "Emerald"],
                "stock": 22,
                "rating": 4.3,
                "reviewCount": 9,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Cropped Hoodie",
                "price": 72.00,
                "imageUrl": "https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&q=80",
                "description": "Trendy cropped hoodie in soft fleece. Drawstring hood and kangaroo pocket.",
                "categoryId": "apparel",
                "brand": "ELORA Basics",
                "sizes": ["XS", "S", "M", "L"],
                "colors": ["Heather Grey", "Black", "Sage", "Lavender"],
                "stock": 55,
                "rating": 4.1,
                "reviewCount": 21,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "High-Waist Trousers",
                "price": 138.00,
                "imageUrl": "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&q=80",
                "description": "Tailored high-waist trousers with wide leg. Crease detail for polished finish.",
                "categoryId": "apparel",
                "brand": "ELORA Collection",
                "sizes": ["XS", "S", "M", "L", "XL"],
                "colors": ["Black", "Khaki", "Navy"],
                "stock": 32,
                "rating": 4.5,
                "reviewCount": 17,
                "isFeatured": true,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Satin Slip Dress",
                "price": 178.00,
                "imageUrl": "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&q=80",
                "description": "Luxurious satin slip dress with cowl neckline. Adjustable spaghetti straps.",
                "categoryId": "dress",
                "brand": "ELORA Couture",
                "sizes": ["XS", "S", "M", "L"],
                "colors": ["Champagne", "Black", "Burgundy", "Emerald"],
                "stock": 20,
                "rating": 4.6,
                "reviewCount": 14,
                "isFeatured": false,
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Platform Espadrilles",
                "price": 145.00,
                "imageUrl": "https://images.unsplash.com/photo-1560343090-f0409e92791a?w=400&q=80",
                "description": "Summer platform espadrilles with canvas upper and jute sole. 2.5-inch lift.",
                "categoryId": "shoes",
                "brand": "ELORA Luxe",
                "sizes": ["36", "37", "38", "39", "40"],
                "colors": ["Natural", "Black", "Navy"],
                "stock": 26,
                "rating": 4.2,
                "reviewCount": 10,
                "isFeatured": false,
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
            ],
            [
                "title": "Sneaker Fest",
                "subtitle": "Step into style with exclusive sneaker deals",
                "discountPercentage": 25.0,
                "categoryId": "shoes",
                "isActive": true,
                "startsAt": Timestamp(date: Date()),
                "endsAt": Timestamp(date: Date().addingTimeInterval(21 * 24 * 3600))
            ],
            [
                "title": "Accessory Bonanza",
                "subtitle": "Elevate your look with jewels & accessories",
                "discountPercentage": 20.0,
                "categoryId": "accessories",
                "isActive": true,
                "startsAt": Timestamp(date: Date()),
                "endsAt": Timestamp(date: Date().addingTimeInterval(10 * 24 * 3600))
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
            print("✅ Seeded 38 products, 4 deals, 3 coupons")
        }
    }
}
