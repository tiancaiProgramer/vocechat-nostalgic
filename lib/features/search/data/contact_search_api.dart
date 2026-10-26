import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../contacts/application/contacts_provider.dart';

final contactSearchApiProvider =
    Provider((ref) => ContactSearchApi(ref.watch(dioProvider)));

class ContactSearchApi {
  ContactSearchApi(this._dio);
  final Dio _dio;

  Future<ContactInfo?> search(String query, CancelToken cancelToken) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return null;
    final id = keyword.replaceFirst(RegExp(r'^#'), '');
    final type = RegExp(r'^\d+$').hasMatch(id)
        ? 'id'
        : keyword.contains('@')
            ? 'email'
            : 'name';
    try {
      final response = await _dio.post('/api/user/search',
          data: {'search_type': type, 'keyword': type == 'id' ? id : keyword},
          cancelToken: cancelToken);
      final data = response.data;
      return data is Map && data['uid'] is num
          ? ContactInfo.fromJson(Map<String, dynamic>.from(data))
          : null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
