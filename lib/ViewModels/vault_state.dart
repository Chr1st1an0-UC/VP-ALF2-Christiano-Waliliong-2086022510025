import 'package:equatable/equatable.dart';

import '../domain/entities/tcg_card.dart';

sealed class VaultState extends Equatable {
  const VaultState();
}

final class VaultLoading extends VaultState {
  const VaultLoading();

  @override
  List<Object?> get props => [];
}

final class VaultLoaded extends VaultState {
  VaultLoaded({
    required List<TcgCard> cards,
    required this.searchQuery,
    required this.favoritesOnly,
    required Set<String> favoriteNames,
    this.isSavingFavorites = false,
    this.notice,
  }) : cards = List.unmodifiable(cards),
       favoriteNames = Set.unmodifiable(favoriteNames);

  final List<TcgCard> cards;
  final String searchQuery;
  final bool favoritesOnly;
  final Set<String> favoriteNames;
  final bool isSavingFavorites;
  final String? notice;

  int get favoriteCount =>
      cards.where((card) => favoriteNames.contains(card.name)).length;

  List<TcgCard> get visibleCards {
    final query = searchQuery.trim().toLowerCase();
    return cards
        .where((card) {
          final matchesSearch =
              query.isEmpty ||
              card.name.toLowerCase().contains(query) ||
              card.owner.toLowerCase().contains(query);
          final matchesFavorites =
              !favoritesOnly || favoriteNames.contains(card.name);
          return matchesSearch && matchesFavorites;
        })
        .toList(growable: false);
  }

  bool isFavorite(TcgCard card) => favoriteNames.contains(card.name);

  VaultLoaded copyWith({
    String? searchQuery,
    bool? favoritesOnly,
    Set<String>? favoriteNames,
    bool? isSavingFavorites,
    String? notice,
    bool clearNotice = false,
  }) {
    return VaultLoaded(
      cards: cards,
      searchQuery: searchQuery ?? this.searchQuery,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      favoriteNames: favoriteNames ?? this.favoriteNames,
      isSavingFavorites: isSavingFavorites ?? this.isSavingFavorites,
      notice: clearNotice ? null : notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [
    cards,
    searchQuery,
    favoritesOnly,
    favoriteNames,
    isSavingFavorites,
    notice,
  ];
}

final class VaultFailure extends VaultState {
  const VaultFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
