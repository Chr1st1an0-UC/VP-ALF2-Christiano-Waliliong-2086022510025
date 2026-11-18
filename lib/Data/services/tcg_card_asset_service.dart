import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/tcg_card.dart';

class TcgCardAssetService {
  Future<List<TcgCard>> loadCards() async {
    final jsonString = await rootBundle.loadString('lib/data/cards.json');
    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException('Data kartu harus berupa daftar.');
    }

    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Format data kartu tidak valid.');
      }

      final name = item['name'];
      final image = item['image'];
      final owner = item['owner'];
      if (name is! String || image is! String || owner is! String) {
        throw const FormatException('Informasi kartu tidak lengkap.');
      }

      return TcgCard(name: name, image: image, owner: owner);
    }).toList(growable: false);
  }
}
