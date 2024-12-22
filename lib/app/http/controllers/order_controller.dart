import 'package:vania/vania.dart';
import 'package:mysql1/mysql1.dart';
import '../../../database/database_connection.dart';
import '../../../utils/token_utils.dart'; // Import token_utils

class OrderController extends Controller {
  Future<bool> checkTokenValidity(Request req) async {
    final token = req.header('Authorization')?.replaceFirst('Bearer ', '');
    print("Token Received: $token");

    if (token == null || !validateToken(token)) {
      print("Invalid token");
      return false;
    }

    try {
      final payload = decodeToken(token); // decodeToken dari token_utils
      print("Decoded Payload: $payload");

      final tokenCustId =
          payload['cust_id']?.toLowerCase(); // Normalisasi ke huruf kecil
      final requestCustId =
          req.query('cust_id')?.toLowerCase(); // Normalisasi ke huruf kecil

      if (tokenCustId == null || tokenCustId != requestCustId) {
        print(
            "cust_id mismatch: tokenCustId=$tokenCustId, requestCustId=$requestCustId");
        return false;
      }

      return true;
    } catch (e) {
      print("Error decoding token: $e");
      return false;
    }
  }

  Future<Response> index(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final custId = req.query('cust_id');
    print("cust_id Received in Controller: $custId");

    if (custId == null || custId.isEmpty) {
      return Response.json({'error': 'cust_id is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      var results =
          await conn.query('SELECT * FROM orders WHERE cust_id = ?', [custId]);
      await conn.close();

      return Response.json({
        'data': results
            .map((row) => {
                  'order_num': row['order_num'],
                  'order_date': row['order_date'].toString(),
                  'cust_id': row['cust_id'],
                })
            .toList()
      });
    } catch (e) {
      return Response.json(
          {'error': 'Failed to fetch orders', 'message': e.toString()}, 500);
    }
  }

  Future<Response> store(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    final custId = req.query('cust_id');
    print("cust_id Received in Store: $custId");

    if (custId == null || custId.isEmpty) {
      return Response.json({'error': 'cust_id is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      var result = await conn.query(
          'INSERT INTO orders (order_num, order_date, cust_id) VALUES (?, ?, ?)',
          [body['order_num'], body['order_date'], custId]);
      await conn.close();

      if (result.insertId != null) {
        return Response.json({'message': 'Order added successfully!'}, 201);
      } else {
        return Response.json({'error': 'Failed to add order.'}, 500);
      }
    } catch (e) {
      return Response.json(
          {'error': 'Failed to add order', 'message': e.toString()}, 500);
    }
  }

  Future<Response> update(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    final custId = req.query('cust_id');
    print("cust_id Received in Update: $custId");

    if (custId == null || custId.isEmpty) {
      return Response.json({'error': 'cust_id is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      await conn.query(
          'UPDATE orders SET order_date = ? WHERE order_num = ? AND cust_id = ?',
          [body['order_date'], body['order_num'], custId]);
      await conn.close();

      return Response.json({'message': 'Order updated successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to update order', 'message': e.toString()}, 500);
    }
  }

  Future<Response> delete(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final orderNum = req.query('order_num');
    final custId = req.query('cust_id');
    print("cust_id Received in Delete: $custId");

    if (custId == null || custId.isEmpty || orderNum == null) {
      return Response.json(
          {'error': 'cust_id and order_num are required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      await conn.query('DELETE FROM orders WHERE order_num = ? AND cust_id = ?',
          [orderNum, custId]);
      await conn.close();

      return Response.json({'message': 'Order deleted successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to delete order', 'message': e.toString()}, 500);
    }
  }
}

final ordersController = OrderController();
