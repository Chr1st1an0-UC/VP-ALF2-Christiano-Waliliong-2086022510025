import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ViewModels/vault_state.dart';
import '../ViewModels/vault_view_model.dart';
import 'widgets/tcg_card_tile.dart';

class VaultView extends StatelessWidget {
  const VaultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TCG Vault',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: context.read<VaultViewModel>().setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Cari kartu atau pemilik',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<VaultViewModel, VaultState>(
                  builder: (context, state) => switch (state) {
                    VaultLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    VaultLoaded() => _LoadedVault(state: state),
                    VaultFailure() => _LoadFailure(message: state.message),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedVault extends StatelessWidget {
  const _LoadedVault({required this.state});

  final VaultLoaded state;

  @override
  Widget build(BuildContext context) {
    final cards = state.visibleCards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterChip(
          label: Text('Favorit (${state.favoriteCount})'),
          avatar: const Icon(Icons.star, size: 18),
          selected: state.favoritesOnly,
          onSelected: context.read<VaultViewModel>().setFavoritesOnly,
        ),
        if (state.notice case final notice?) ...[
          const SizedBox(height: 8),
          _Notice(message: notice),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: cards.isEmpty
              ? Center(
                  child: Text(
                    state.favoritesOnly
                        ? 'Belum ada kartu favorit.'
                        : 'Kartu tidak ditemukan.',
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        mainAxisExtent: 300,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return TcgCardTile(
                      card: card,
                      isFavorite: state.isFavorite(card),
                      isSavingFavorites: state.isSavingFavorites,
                      onFavoritePressed: () => context
                          .read<VaultViewModel>()
                          .toggleFavorite(card),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(
            onPressed: context.read<VaultViewModel>().loadCards,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message),
      ),
    );
  }
}
