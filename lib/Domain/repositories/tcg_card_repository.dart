import '../entities/tcg_card.dart';

abstract interface class TcgCardRepository {
  Future<List<TcgCard>> getCards();

  Future<Set<String>> getFavoriteNames();

  Future<void> saveFavoriteNames(Set<String> names);
}
