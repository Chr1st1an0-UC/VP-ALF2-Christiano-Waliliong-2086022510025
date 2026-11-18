import 'package:shared_preferences/shared_preferences.dart';

class FavoriteStorageService {
  static const _favoritesKey = 'tcg_vault_favorites';

  Future<Set<String>> loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_favoritesKey) ?? const []).toSet();
  }

  Future<void> saveFavorites(Set<String> names) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      _favoritesKey,
      names.toList()..sort(),
    );
    if (!saved) {
      throw StateError('Preferensi favorit tidak berhasil disimpan.');
    }
  }
}
