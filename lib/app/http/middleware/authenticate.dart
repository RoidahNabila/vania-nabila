import 'package:vania/vania.dart';
import '../../../utils/token_utils.dart';

class AuthMiddleware extends Middleware {
  @override
  Future<Response?> handle(Request req) async {
    final token = req.header('Authorization')?.replaceFirst('Bearer ', '');
    print("Token Received: $token");

    // Periksa apakah token ada
    if (token == null) {
      print("No token provided");
      return Response.json({'error': 'Unauthorized: No token provided'}, 401);
    }

    // Validasi token
    if (!validateToken(token)) {
      print("Invalid token");
      return Response.json({'error': 'Unauthorized: Invalid token'}, 401);
    }

    try {
      // Decode token dan ambil payload
      final payload = decodeToken(token);
      print("Decoded Payload: $payload");

      // Validasi cust_id
      final tokenCustId = payload['cust_id'];
      final requestCustId = req.query('cust_id');

      if (tokenCustId == null || tokenCustId != requestCustId) {
        print(
            "cust_id mismatch: tokenCustId=$tokenCustId, requestCustId=$requestCustId");
        return Response.json({'error': 'Unauthorized: cust_id mismatch'}, 401);
      }

      print("Token and cust_id validated successfully");
      return null; // Lanjutkan ke handler berikutnya
    } catch (e) {
      print("Error decoding token: $e");
      return Response.json(
          {'error': 'Unauthorized: Token decoding failed'}, 401);
    }
  }
}
