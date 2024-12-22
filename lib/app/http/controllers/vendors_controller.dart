import 'package:vania/vania.dart';
import 'package:mysql1/mysql1.dart';
import '../../../database/database_connection.dart';
import '../../../utils/token_utils.dart'; // Import token_utils

class VendorsController extends Controller {
  Future<bool> checkTokenValidity(Request req) async {
    final token = req.header('Authorization')?.replaceFirst('Bearer ', '');
    print("Token Received: $token");

    if (token == null || !validateToken(token)) {
      print("Invalid token");
      return false;
    }

    try {
      final payload = decodeToken(token); // Decode token
      print("Decoded Payload: $payload");

      // Tidak ada validasi cust_id, hanya memvalidasi token
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

    try {
      MySqlConnection conn = await connectToDatabase();
      var results = await conn.query('SELECT * FROM vendors');
      await conn.close();

      return Response.json({
        'data': results
            .map((row) => {
                  'vend_id': row['vend_id'],
                  'vend_name': row['vend_name'],
                  'vend_address': row['vend_address'],
                  'vend_kota': row['vend_kota'],
                  'vend_state': row['vend_state'],
                  'vend_zip': row['vend_zip'],
                  'vend_country': row['vend_country'],
                })
            .toList()
      });
    } catch (e) {
      return Response.json(
          {'error': 'Failed to fetch vendors', 'message': e.toString()}, 500);
    }
  }

  Future<Response> store(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    try {
      MySqlConnection conn = await connectToDatabase();
      var result = await conn.query(
          'INSERT INTO vendors (vend_id, vend_name, vend_address, vend_kota, vend_state, vend_zip, vend_country) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            body['vend_id'],
            body['vend_name'],
            body['vend_address'],
            body['vend_kota'],
            body['vend_state'],
            body['vend_zip'],
            body['vend_country']
          ]);
      await conn.close();

      if (result.insertId != null) {
        return Response.json({'message': 'Vendor added successfully!'}, 201);
      } else {
        return Response.json({'error': 'Failed to add vendor.'}, 500);
      }
    } catch (e) {
      return Response.json(
          {'error': 'Failed to add vendor', 'message': e.toString()}, 500);
    }
  }

  Future<Response> update(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final body = req.input();
    final vendId = body['vend_id'];
    if (vendId == null || vendId.isEmpty) {
      return Response.json({'error': 'vend_id is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      await conn.query(
          'UPDATE vendors SET vend_name = ?, vend_address = ?, vend_kota = ?, vend_state = ?, vend_zip = ?, vend_country = ? WHERE vend_id = ?',
          [
            body['vend_name'],
            body['vend_address'],
            body['vend_kota'],
            body['vend_state'],
            body['vend_zip'],
            body['vend_country'],
            vendId
          ]);
      await conn.close();

      return Response.json({'message': 'Vendor updated successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to update vendor', 'message': e.toString()}, 500);
    }
  }

  Future<Response> delete(Request req) async {
    if (!(await checkTokenValidity(req))) {
      return Response.json({'error': 'Unauthorized'}, 401);
    }

    final vendId = req.query('vend_id');
    if (vendId == null || vendId.isEmpty) {
      return Response.json({'error': 'vend_id is required'}, 400);
    }

    try {
      MySqlConnection conn = await connectToDatabase();
      await conn.query('DELETE FROM vendors WHERE vend_id = ?', [vendId]);
      await conn.close();

      return Response.json({'message': 'Vendor deleted successfully!'}, 200);
    } catch (e) {
      return Response.json(
          {'error': 'Failed to delete vendor', 'message': e.toString()}, 500);
    }
  }
}

final vendorsController = VendorsController();
