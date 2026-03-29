// ===============================
// Firestore Seeder Script
// Creates:
// - 2 Malls
// - 15 Products in each
// - Barcode index for each product
// ===============================

const admin = require("firebase-admin");

// Load your service account key
const serviceAccount = require("./serviceAccountKey.json");

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function seedDatabase() {
  console.log("Starting database seeding...");

  // ----------------------------
  // MALL 1
  // ----------------------------
  const mall1Id = "11000103CP19";

  await db.collection("malls").doc(mall1Id).set({
    mallId: mall1Id,
    name: "City Plaza Mall",
    active: true,
    areaCode: "110001",
    mallNumber: 3,
    mallCode: "CP",
    estYear: 2019,
  });

  await addProducts(mall1Id, "890");

  // ----------------------------
  // MALL 2
  // ----------------------------
  const mall2Id = "56000101MG18";

  await db.collection("malls").doc(mall2Id).set({
    mallId: mall2Id,
    name: "Metro Galleria Mall",
    active: true,
    areaCode: "560001",
    mallNumber: 1,
    mallCode: "MG",
    estYear: 2018,
  });

  await addProducts(mall2Id, "891");

  console.log("Database seeding completed ✅");
  process.exit();
}

// ---------------------------------------
// Function to add 15 products to a mall
// prefix = barcode prefix (so both malls have different barcodes)
// ---------------------------------------
async function addProducts(mallId, prefix) {
  const products = [
    { id: "p1", name: "Milk 1L", price: 56 },
    { id: "p2", name: "Curd 400g", price: 45 },
    { id: "p3", name: "Bread 400g", price: 45 },
    { id: "p4", name: "Eggs 6 Pack", price: 42 },
    { id: "p5", name: "Rice 5kg", price: 549 },
    { id: "p6", name: "Wheat Atta 5kg", price: 269 },
    { id: "p7", name: "Sugar 1kg", price: 48 },
    { id: "p8", name: "Salt 1kg", price: 28 },
    { id: "p9", name: "Sunflower Oil 1L", price: 149 },
    { id: "p10", name: "Maggi 70g", price: 14 },
    { id: "p11", name: "Biscuits 250g", price: 35 },
    { id: "p12", name: "Chips 60g", price: 20 },
    { id: "p13", name: "Coke 750ml", price: 40 },
    { id: "p14", name: "Water 1L", price: 20 },
    { id: "p15", name: "Soap 125g", price: 35 },
  ];

  for (let i = 0; i < products.length; i++) {
    const product = products[i];

    // Generate unique barcode
    const barcode = prefix + (1000000000 + i);

    // Add product document
    await db
      .collection("malls")
      .doc(mallId)
      .collection("products")
      .doc(product.id)
      .set({
        productId: product.id,
        name: product.name,
        barcode: barcode,
        price: product.price,
        unit: "1 pc",
        brand: "SwiftCart",
        category: "General",
        inStock: true,
      });

    // Add barcode mapping document
    await db
      .collection("malls")
      .doc(mallId)
      .collection("barcodes")
      .doc(barcode)
      .set({
        productId: product.id,
        price: product.price,
        inStock: true,
      });

    console.log(`Added ${product.name} to ${mallId}`);
  }
}

// Run the script
seedDatabase();