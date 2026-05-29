const mysql = require('mysql2/promise');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrate() {
  const connection = await mysql.createConnection(process.env.MYSQL_CONNECTION_STRING);
  console.log('Connected to MySQL.');

  try {
    // 1. Migrate Malls
    console.log('Migrating Malls...');
    const [malls] = await connection.execute('SELECT * FROM malls');
    for (const mall of malls) {
      await db.collection('malls').doc(mall.mall_id).set({
        mallId: mall.mall_id,
        name: mall.name,
        address: mall.address,
        city: mall.city,
        isActive: mall.is_active === 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
      // 2. Migrate Products for this Mall
      console.log(`  Migrating Products for Mall: ${mall.mall_id}`);
      const [products] = await connection.execute('SELECT * FROM products WHERE mall_id = ?', [mall.mall_id]);
      for (const product of products) {
        await db.collection('malls').doc(mall.mall_id).collection('products').doc(product.product_id).set({
          name: product.name,
          description: product.description,
          price: product.price,
          barcode: product.barcode,
          category: product.category,
          imageUrl: product.image_url,
          stockQuantity: product.stock_quantity
        });

        // Also migrate barcode lookup index
        if (product.barcode) {
          await db.collection('malls').doc(mall.mall_id).collection('barcodes').doc(product.barcode).set({
            productId: product.product_id,
            barcode: product.barcode
          });
        }
      }
    }

    // 2b. Migrate Mall Managers
    console.log('Migrating Mall Managers...');
    const [mgrs] = await connection.execute('SELECT * FROM mall_managers');
    for (const mgr of mgrs) {
      await db.collection('malls').doc(mgr.mall_id).collection('managers').doc(mgr.manager_id).set({
        managerId: mgr.manager_id,
        mallId: mgr.mall_id,
        assignedUid: mgr.assigned_uid,
        assignedEmail: mgr.assigned_email,
        isActive: mgr.is_active === 1,
        fullName: mgr.full_name || '',
        phoneNumber: mgr.phone_number || '',
        createdAt: mgr.created_at,
        updatedAt: mgr.updated_at,
        lastLoginAt: mgr.last_login_at,
        passwordHash: mgr.password_hash // Note: Logic handles this via manager portal login
      }, { merge: true });
    }

    // 3. Migrate User Profiles
    console.log('Migrating User Profiles...');
    const [users] = await connection.execute('SELECT * FROM users');
    for (const user of users) {
      await db.collection('users').doc(user.uid).set({
        uid: user.uid,
        email: user.email,
        username: user.username,
        fullName: user.full_name,
        displayName: user.full_name,
        phone: user.phone,
        photoUrl: user.photo_url,
        provider: user.provider || 'password',
        emailVerified: true
      }, { merge: true });
    }

    // 4. Migrate Admin Accounts
    console.log('Migrating Admins...');
    const [admins] = await connection.execute('SELECT * FROM admins');
    for (const adminAcct of admins) {
      await db.collection('admins').doc(adminAcct.email).set({
        adminId: adminAcct.admin_id,
        email: adminAcct.email,
        name: adminAcct.name,
        role: adminAcct.role,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // 5. Migrate Announcements
    console.log('Migrating Announcements...');
    const [announcements] = await connection.execute('SELECT * FROM announcements');
    for (const ann of announcements) {
      await db.collection('announcements').doc(ann.id).set({
        title: ann.title,
        message: ann.message,
        audience: ann.audience,
        createdBy: ann.created_by,
        createdAt: ann.created_at || admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // 6. Migrate Support Requests
    console.log('Migrating Support Requests...');
    const [support] = await connection.execute('SELECT * FROM support_requests');
    for (const req of support) {
      await db.collection('support_requests').doc(req.id).set({
        type: req.type,
        name: req.name,
        email: req.email,
        message: req.message,
        status: req.status,
        createdAt: req.created_at || admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: req.updated_at || admin.firestore.FieldValue.serverTimestamp()
      });
    }

    console.log('Migration complete successfully.');
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await connection.end();
  }
}

if (!process.env.MYSQL_CONNECTION_STRING) {
  console.error('Please set the MYSQL_CONNECTION_STRING environment variable.');
  process.exit(1);
}

migrate();