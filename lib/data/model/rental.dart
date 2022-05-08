import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rentall/data/model/converters.dart';
import 'governorate.dart';
import 'property_type.dart';

part 'rental.g.dart';

enum RentType { daily, monthly, weekly, custom }

enum PublishStatus { pending, reviewing, approved, rejected }

@JsonSerializable()
class Rental extends Equatable {
  @JsonKey(includeIfNull: false)
  final String? id;
  final String title;
  final List<String> images;
  @JsonKey(includeIfNull: false)
  final String? description;
  final String address;
  @JsonKey(includeIfNull: false)
  @GeoPointConverter()
  final GeoPoint? location;
  @JsonKey(includeIfNull: false)
  final int? floorNumber;
  @JsonKey(includeIfNull: false)
  final int? numberOfRooms;
  @JsonKey(includeIfNull: false)
  final int? numberOfBathrooms;
  @JsonKey(includeIfNull: false)
  final bool? furnished;
  final int area;
  final Governorate governorate;
  @JsonKey(includeIfNull: false)
  final int? regionId;
  final int rentPrice;
  final String hostPhoneNumber;
  @TimestampConverter()
  final Timestamp? createdAt;
  @JsonKey(includeIfNull: false)
  final RentType? rentType;
  @JsonKey(includeIfNull: false)
  final PropertyType? propertyType;
  @JsonKey(includeIfNull: false)
  final PublishStatus? publishStatus;

  const Rental({
    this.id,
    required this.title,
    this.images = const [],
    this.description,
    required this.address,
    this.location,
    this.floorNumber,
    this.numberOfRooms,
    this.numberOfBathrooms,
    this.furnished,
    required this.area,
    required this.governorate,
    this.regionId,
    required this.rentPrice,
    required this.hostPhoneNumber,
    this.createdAt,
    this.rentType = RentType.monthly,
    required this.propertyType,
    this.publishStatus,
  });

  factory Rental.fromJson(Map<String, dynamic> json) => _$RentalFromJson(json);
  Map<String, dynamic> toJson() => _$RentalToJson(this);

  // factory Rental.fromMap(Map<String, dynamic> map) => Rental(
  //       id: map['id'] as String?,
  //       title: map['title'] as String,
  //       images: List.from(map['images'] ?? []),
  //       description: map['description'] as String?,
  //       address: map['address'] as String,
  //       location: map['location'] as GeoPoint?,
  //       floorNumber: map['floorNumber'] as int?,
  //       numberOfRooms: map['numberOfRooms'] as int?,
  //       numberOfBathrooms: map['numberOfBathrooms'] as int?,
  //       furnished: map['furnished'] as bool?,
  //       area: map['area'] as int,
  //       governorate: Governorate.values[map['governorateId'] as int],
  //       regionId: map['regionId'] as int?,
  //       rentPrice: map['rentPrice'] as int,
  //       hostPhoneNumber: map['hostPhoneNumber'] as String,
  //       createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
  //       rentType: (map['rentType'] as int?) != null
  //           ? RentType.values[map['rentType'] as int]
  //           : RentType.monthly,
  //       propertyType: (map['propertyType'] as int?) != null
  //           ? PropertyType.values[map['rentType'] as int]
  //           : PropertyType.apartment,
  //       publishStatus: map['publishStatus'] != null
  //           ? PublishStatus.values[map['publishStatus']]
  //           : null,
  //     );

  // static Map<String, dynamic> toMap(Rental r) {
  //   final map = <String, dynamic>{};

  //   void writeNotNull(String key, dynamic value) {
  //     if (value != null) {
  //       map[key] = value;
  //     }
  //   }

  //   void writeNotNullToString(String key, int? value) {
  //     if (value != null) {
  //       map[key] = '$value';
  //     }
  //   }

  //   writeNotNull('id', r.id);
  //   map['title'] = r.title;
  //   map['images'] = r.images;
  //   writeNotNull('description', r.description);
  //   map['address'] = r.address;
  //   writeNotNull('location', r.location);
  //   writeNotNullToString('floorNumber', r.floorNumber);
  //   writeNotNullToString('numberOfRooms', r.numberOfRooms);
  //   writeNotNullToString('numberOfBathrooms', r.numberOfBathrooms);
  //   writeNotNull('furnished', r.furnished);
  //   writeNotNullToString('area', r.area);
  //   map['governorateId'] = r.governorate.index;
  //   writeNotNullToString('regionId', r.regionId);
  //   writeNotNullToString('rentPrice', r.rentPrice);
  //   map['hostPhoneNumber'] = r.hostPhoneNumber;
  //   map['createdAt'] = r.createdAt;
  //   writeNotNull('rentType', r.rentType?.index);
  //   map['propertyType'] = r.propertyType?.index;
  //   map['publishStatus'] = r.publishStatus?.index;
  //   return map;

  //   // map['id'] r.id,
  //   // 'title': r.title,
  //   // 'images': r.images,
  //   // 'description': r.description,
  //   // 'address': r.address,
  //   // 'location': r.location,
  //   // 'floorNumber': r.floorNumber,
  //   // 'numberOfRooms': r.numberOfRooms,
  //   // 'numberOfBathrooms': r.numberOfBathrooms,
  //   // 'area': r.area,
  //   // 'furnished': r.furnished,
  //   // 'governorateId': r.governorate.index,
  //   // 'regionId': r.regionId,
  //   // 'rentPrice': r.rentPrice,
  //   // 'hostPhoneNumber': r.hostPhoneNumber,
  //   // 'createdAt': r.createdAt ?? Timestamp.now(),
  //   // 'rentType': r.rentType?.index,
  //   // 'propertyType': r.propertyType?.index,
  // }

  @override
  List<Object?> get props => [
        id,
        title,
        images,
        description,
        address,
        floorNumber,
        numberOfRooms,
        numberOfBathrooms,
        governorate,
        furnished,
        area,
        regionId,
        rentPrice,
        hostPhoneNumber,
        createdAt,
        rentType,
        propertyType,
      ];
}
