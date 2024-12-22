import 'package:vania/vania.dart';
import 'package:mysql1/mysql1.dart';
import '../../../database/database_connection.dart';
import '../../../utils/token_utils.dart';

class OrderItemsController extends Controller {
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

  // Tampilkan semua item di order
  Future<Response> index(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final orderNum = req.query('order_num');
    if (orderNum == null || orderNum.isEmpty) {
      return Response.json({'error': 'order_num is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      var results = await conn
          .query('SELECT * FROM order_items WHERE order_num = ?', [orderNum]);
      await conn.close();

      return Response.json({
        'data': results
            .map((row) => {
                  'order_item': row['order_item'],
                  'order_num': row['order_num'],
                  'prod_id': row['prod_id'],
                  'quantity': row['quantity'],
                  'size': row['size'],
                })
            .toList()
      });
    } catch (e) {
      return Response.json(
          {'error': 'Failed to fetch order items', 'message': e.toString()},
          500);
    }
  }

  // Tambah item ke order
  Future<Response> store(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah order_num ada di tabel orders
      var orderExists = await conn.query(
          'SELECT order_num FROM orders WHERE order_num = ?',
          [body['order_num']]);
      if (orderExists.isEmpty) {
        return Response.json({'error': 'Order not found'}, 400);
      }

      // Validasi apakah prod_id ada di tabel products
      var productExists = await conn.query(
          'SELECT prod_id FROM products WHERE prod_id = ?', [body['prod_id']]);
      if (productExists.isEmpty) {
        return Response.json({'error': 'Product not found'}, 400);
      }

      // Tambahkan item ke order
      var result = await conn.query(
          'INSERT INTO order_items (order_item, order_num, prod_id, quantity, size) VALUES (?, ?, ?, ?, ?)',
          [
            body['order_item'],
            body['order_num'],
            body['prod_id'],
            body['quantity'],
            body['size']
          ]);

      await conn.close();

      if (result.insertId != null) {
        return Response.json(
            {'message': 'Order item added successfully!'}, 201);
      } else {
        return Response.json({'error': 'Failed to add order item'}, 500);
      }
    } catch (e) {
      return Response.json(
          {'error': 'Failed to add order item', 'message': e.toString()}, 500);
    }
  }

  // Update item di order
  Future<Response> update(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah item ada di order
      var itemExists = await conn.query(
          'SELECT * FROM order_items WHERE order_item = ?',
          [body['order_item']]);
      if (itemExists.isEmpty) {
        return Response.json({'error': 'Order item not found'}, 404);
      }

      // Update item di order
      await conn.query(
          'UPDATE order_items SET order_num = ?, prod_id = ?, quantity = ?, size = ? WHERE order_item = ?',
          [
            body['order_num'],
            body['prod_id'],
            body['quantity'],
            body['size'],
            body['order_item']
          ]);

      await conn.close();
      return Response.json(
          {'message': 'Order item updated successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to update order item', 'message': e.toString()},
          500);
    }
  }

  // Hapus item dari order
  Future<Response> delete(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final orderItem = req.query('order_item');
    if (orderItem == null) {
      return Response.json({'error': 'order_item is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();

      // Validasi apakah item ada di order
      var itemExists = await conn
          .query('SELECT * FROM order_items WHERE order_item = ?', [orderItem]);
      if (itemExists.isEmpty) {
        return Response.json({'error': 'Order item not found'}, 404);
      }

      // Hapus item dari order
      await conn
          .query('DELETE FROM order_items WHERE order_item = ?', [orderItem]);

      await conn.close();
      return Response.json(
          {'message': 'Order item deleted successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to delete order item', 'message': e.toString()},
          500);
    }
  }
}

final orderItemsController = OrderItemsController();
