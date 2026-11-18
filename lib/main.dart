import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/repositories/tcg_card_repository_impl.dart';
import 'data/services/favorite_storage_service.dart';
import 'data/services/tcg_card_asset_service.dart';
import 'domain/repositories/tcg_card_repository.dart';
import 'ViewModels/vault_view_model.dart';
import 'Views/vault_view.dart';

void main() {
  final cardService = TcgCardAssetService();
  final repository = TcgCardRepositoryImpl(
    cardService: cardService,
    favoriteService: FavoriteStorageService(),
  );
  runApp(TcgVaultApp(repository: repository));
}

class TcgVaultApp extends StatelessWidget {
  const TcgVaultApp({required this.repository, super.key});

  final TcgCardRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCG Vault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF315C50),
          surface: const Color(0xFFF6F7F4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => VaultViewModel(repository)..loadCards(),
        child: const VaultView(),
      ),
    );
  }
}
