import '../../domain/entities/tcg_card.dart';
import '../../domain/repositories/tcg_card_repository.dart';
import '../services/favorite_storage_service.dart';
import '../services/tcg_card_asset_service.dart';

class TcgCardRepositoryImpl implements TcgCardRepository {
  const TcgCardRepositoryImpl({
    required this.cardService,
    required this.favoriteService,
  });

  final TcgCardAssetService cardService;
  final FavoriteStorageService favoriteService;

  @override
  Future<List<TcgCard>> getCards() => cardService.loadCards();

  @override
  Future<Set<String>> getFavoriteNames() =>
      favoriteService.loadFavorites();

  @override
  Future<void> saveFavoriteNames(Set<String> names) =>
      favoriteService.saveFavorites(names);
}
