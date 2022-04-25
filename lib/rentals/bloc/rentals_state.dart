part of 'rentals_bloc.dart';

class RentalsState extends Equatable {
  final LoadStatus status;
  final List<Rental>? rentals;
  final String? error;
  final Governorate governorate;
  final PropertyType type;

  const RentalsState({
    this.status = LoadStatus.loading,
    this.rentals,
    this.error,
    this.governorate = Governorate.all,
    this.type = PropertyType.all,
  });

  RentalsState copyWith({
    LoadStatus? status,
    List<Rental>? rentals,
    String? error,
    Governorate? governorate,
    PropertyType? type,
  }) =>
      RentalsState(
        status: status ?? this.status,
        rentals: rentals ?? this.rentals,
        error: error,
        governorate: governorate ?? this.governorate,
        type: type ?? this.type,
      );

  Map<String, dynamic> get filters => {
        'governorate': governorate,
        'propertyType': type,
      };

  @override
  List<Object?> get props => [
        status,
        rentals,
        error,
        governorate,
        type,
      ];
}
