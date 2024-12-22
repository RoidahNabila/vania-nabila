import 'package:vania/vania.dart';
import 'package:mysql1/mysql1.dart';
import '../../../database/database_connection.dart';
import '../../../utils/token_utils.dart';

class ProductNotesController extends Controller {
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

  // Tampilkan semua catatan untuk produk
  Future<Response> index(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final prodId = req.query('prod_id');
    if (prodId == null || prodId.isEmpty) {
      return Response.json({'error': 'prod_id is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      var results = await conn
          .query('SELECT * FROM product_notes WHERE prod_id = ?', [prodId]);
      await conn.close();

      return Response.json({
        'data': results
            .map((row) => {
                  'note_id': row['note_id'],
                  'prod_id': row['prod_id'],
                  'note_date': row['note_date'].toString(),
                  'note_text': row['note_text'],
                })
            .toList()
      });
    } catch (e) {
      return Response.json(
          {'error': 'Failed to fetch product notes', 'message': e.toString()},
          500);
    }
  }

  // Tambah catatan untuk produk
  Future<Response> store(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah prod_id ada di tabel products
      var productExists = await conn.query(
          'SELECT prod_id FROM products WHERE prod_id = ?', [body['prod_id']]);
      if (productExists.isEmpty) {
        return Response.json({'error': 'Product not found'}, 400);
      }

      // Tambahkan catatan untuk produk
      var result = await conn.query(
          'INSERT INTO product_notes (note_id, prod_id, note_date, note_text) VALUES (?, ?, ?, ?)',
          [
            body['note_id'],
            body['prod_id'],
            body['note_date'],
            body['note_text']
          ]);

      await conn.close();

      if (result.insertId != null) {
        return Response.json(
            {'message': 'Product note added successfully!'}, 201);
      } else {
        return Response.json({'error': 'Failed to add product note'}, 500);
      }
    } catch (e) {
      return Response.json(
          {'error': 'Failed to add product note', 'message': e.toString()},
          500);
    }
  }

  // Update catatan untuk produk
  Future<Response> update(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah note_id ada di tabel product_notes
      var noteExists = await conn.query(
          'SELECT * FROM product_notes WHERE note_id = ?', [body['note_id']]);
      if (noteExists.isEmpty) {
        return Response.json({'error': 'Product note not found'}, 404);
      }

      // Update catatan untuk produk
      await conn.query(
          'UPDATE product_notes SET prod_id = ?, note_date = ?, note_text = ? WHERE note_id = ?',
          [
            body['prod_id'],
            body['note_date'],
            body['note_text'],
            body['note_id']
          ]);

      await conn.close();
      return Response.json(
          {'message': 'Product note updated successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to update product note', 'message': e.toString()},
          500);
    }
  }

  // Hapus catatan untuk produk
  Future<Response> delete(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final noteId = req.query('note_id');
    if (noteId == null) {
      return Response.json({'error': 'note_id is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah note_id ada di tabel product_notes
      var noteExists = await conn
          .query('SELECT * FROM product_notes WHERE note_id = ?', [noteId]);
      if (noteExists.isEmpty) {
        return Response.json({'error': 'Product note not found'}, 404);
      }

      // Hapus catatan untuk produk
      await conn.query('DELETE FROM product_notes WHERE note_id = ?', [noteId]);

      await conn.close();
      return Response.json(
          {'message': 'Product note deleted successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to delete product note', 'message': e.toString()},
          500);
    }
  }
}

final productNotesController = ProductNotesController();
