import 'package:vania/vania.dart';
import 'package:mysql1/mysql1.dart';
import '../../../database/database_connection.dart';
import '../../../utils/token_utils.dart';

class ProductsController extends Controller {
  // Validasi token
  Future<bool> checkTokenValidity(Request req) async {
    final token = req.header('Authorization')?.replaceFirst('Bearer ', '');
    print("Token Received: $token");

    if (token == null || !validateToken(token)) {
      print("Invalid token");
      return false;
    }
    print("Token is valid");
    return true;
  }

  // Tampilkan semua produk
  Future<Response> index(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      var results = await conn.query('SELECT * FROM products');
      await conn.close();

      return Response.json({
        'data': results
            .map((row) => {
                  'prod_id': row['prod_id'],
                  'vend_id': row['vend_id'],
                  'prod_name': row['prod_name'],
                  'prod_price': row['prod_price'],
                  'prod_desc': row['prod_desc'],
                })
            .toList()
      });
    } catch (e) {
      return Response.json(
          {'error': 'Failed to fetch products', 'message': e.toString()}, 500);
    }
  }

  // Tambah produk baru
  Future<Response> store(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah vend_id ada di tabel vendors
      var vendorExists = await conn.query(
          'SELECT vend_id FROM vendors WHERE vend_id = ?', [body['vend_id']]);
      if (vendorExists.isEmpty) {
        return Response.json({'error': 'Vendor not found'}, 400);
      }

      // Tambahkan produk baru
      var result = await conn.query(
          'INSERT INTO products (prod_id, vend_id, prod_name, prod_price, prod_desc) VALUES (?, ?, ?, ?, ?)',
          [
            body['prod_id'],
            body['vend_id'],
            body['prod_name'],
            body['prod_price'],
            body['prod_desc'],
          ]);

      await conn.close();

      if (result.insertId != null) {
        return Response.json({'message': 'Product added successfully!'}, 201);
      } else {
        return Response.json({'error': 'Failed to add product'}, 500);
      }
    } catch (e) {
      return Response.json(
          {'error': 'Failed to add product', 'message': e.toString()}, 500);
    }
  }

  // Update produk
  Future<Response> update(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah produk ada
      var productExists = await conn
          .query('SELECT * FROM products WHERE prod_id = ?', [body['prod_id']]);
      if (productExists.isEmpty) {
        return Response.json({'error': 'Product not found'}, 404);
      }

      // Update produk
      await conn.query(
          'UPDATE products SET vend_id = ?, prod_name = ?, prod_price = ?, prod_desc = ? WHERE prod_id = ?',
          [
            body['vend_id'],
            body['prod_name'],
            body['prod_price'],
            body['prod_desc'],
            body['prod_id'],
          ]);

      await conn.close();
      return Response.json({'message': 'Product updated successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to update product', 'message': e.toString()}, 500);
    }
  }

  // Hapus produk
  Future<Response> delete(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final prodId = req.query('prod_id');
    if (prodId == null) {
      return Response.json({'error': 'prod_id is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah produk ada
      var productExists = await conn
          .query('SELECT * FROM products WHERE prod_id = ?', [prodId]);
      if (productExists.isEmpty) {
        return Response.json({'error': 'Product not found'}, 404);
      }

      // Hapus produk
      await conn.query('DELETE FROM products WHERE prod_id = ?', [prodId]);

      await conn.close();
      return Response.json({'message': 'Product deleted successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to delete product', 'message': e.toString()}, 500);
    }
  }
}

final productsController = ProductsController();
