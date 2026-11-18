import 'package:equatable/equatable.dart';

class TcgCard extends Equatable {
  const TcgCard({
    required this.name,
    required this.image,
    required this.owner,
  });

  final String name;
  final String image;
  final String owner;

  @override
  List<Object?> get props => [name, image, owner];
}
