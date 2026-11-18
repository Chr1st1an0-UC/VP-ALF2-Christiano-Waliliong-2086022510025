import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/tcg_card.dart';
import '../domain/repositories/tcg_card_repository.dart';
import 'vault_state.dart';

class VaultViewModel extends Cubit<VaultState> {
  VaultViewModel(this._repository) : super(const VaultLoading());

  final TcgCardRepository _repository;

  Future<void> loadCards() async {
    emit(const VaultLoading());
    try {
      final cards = await _repository.getCards();
      if (isClosed) return;

      final favoriteNames = await _repository.getFavoriteNames();
      if (isClosed) return;

      emit(
        VaultLoaded(
          cards: cards,
          searchQuery: '',
          favoritesOnly: false,
          favoriteNames: favoriteNames,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const VaultFailure(
          'Kartu belum dapat dimuat. Periksa data lokal, lalu coba lagi.',
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    final current = state;
    if (current is VaultLoaded) {
      emit(current.copyWith(searchQuery: query, clearNotice: true));
    }
  }

  void setFavoritesOnly(bool value) {
    final current = state;
    if (current is VaultLoaded) {
      emit(current.copyWith(favoritesOnly: value, clearNotice: true));
    }
  }

  Future<void> toggleFavorite(TcgCard card) async {
    final current = state;
    if (current is! VaultLoaded || current.isSavingFavorites) return;

    final previousNames = current.favoriteNames;
    final updatedNames = Set<String>.of(previousNames);
    if (!updatedNames.add(card.name)) {
      updatedNames.remove(card.name);
    }

    emit(
      current.copyWith(
        favoriteNames: updatedNames,
        isSavingFavorites: true,
        clearNotice: true,
      ),
    );

    try {
      await _repository.saveFavoriteNames(updatedNames);
      if (isClosed) return;

      final latest = state;
      if (latest is VaultLoaded) {
        emit(latest.copyWith(isSavingFavorites: false));
      }
    } catch (_) {
      if (isClosed) return;

      final latest = state;
      if (latest is VaultLoaded) {
        emit(
          latest.copyWith(
            favoriteNames: previousNames,
            isSavingFavorites: false,
            notice:
                'Favorit belum tersimpan. Periksa penyimpanan, lalu coba lagi.',
          ),
        );
      }
    }
  }
}
