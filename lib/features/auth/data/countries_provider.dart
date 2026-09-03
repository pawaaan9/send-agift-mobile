import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';

/// A country a customer can register under.
class Country {
  const Country({required this.id, required this.name, required this.isoCode});

  final String id;
  final String name;
  final String isoCode;

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isoCode: json['iso_code'] as String? ?? '',
    );
  }
}

/// Public country list, used by the registration form. Registration is gated
/// per country on the backend, so the id has to come from this list.
final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.dio.get<dynamic>('/countries');
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Country.fromJson)
        .where((country) => country.id.isNotEmpty)
        .toList(growable: false);
  } on DioException catch (error) {
    throw client.mapError(error);
  }
});
