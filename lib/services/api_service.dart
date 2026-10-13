import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //Atur ip local
  static const String baseUrl = "https://votingmu.my.id/api";

  // GET KANDIDAT
  static Future<List<dynamic>> getKandidat() async {
    final response = await http.get(
      Uri.parse('$baseUrl/kandidats'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal mengambil data kandidat');
    }
  }
}