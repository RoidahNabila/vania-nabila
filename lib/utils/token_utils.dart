import 'dart:convert';
import 'package:crypto/crypto.dart';

const String secretKey = "your_secret_key";

String generateToken(String custId) {
  final payload = {
    'cust_id': custId, // Ubah user_id menjadi cust_id
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'exp': DateTime.now().add(Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
  };

  final header = {'alg': 'HS256', 'typ': 'JWT'};

  final base64Header = base64Url.encode(utf8.encode(json.encode(header)));
  final base64Payload = base64Url.encode(utf8.encode(json.encode(payload)));

  final signature = Hmac(sha256, utf8.encode(secretKey))
      .convert(utf8.encode('$base64Header.$base64Payload'))
      .toString();

  return '$base64Header.$base64Payload.$signature';
}

bool validateToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return false;

    final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
    final expiration = payload['exp'];

    if (DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiration) {
      print("Token expired");
      return false;
    }

    return true; // Token valid
  } catch (e) {
    print("Token validation error: $e");
    return false;
  }
}

Map<String, dynamic> decodeToken(String token) {
  final parts = token.split('.');
  final payload = utf8.decode(base64Url.decode(parts[1]));
  return json.decode(payload);
}
