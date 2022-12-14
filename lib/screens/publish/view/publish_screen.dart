import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/widgets.dart';

import '../../../data/models/models.dart';
import '../../screens.dart';
import '../bloc/publish_bloc.dart';
import 'widgets/widgets.dart';

class PublishScreen extends StatefulWidget {
  static const routeName = '/publish_screen';

  final Rental? rental;
  const PublishScreen({
    this.rental,
    Key? key,
  }) : super(key: key);

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  late final updating = widget.rental != null;
  late final _images = <dynamic>[...?widget.rental?.images];
  late final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    BlocProvider.of<PublishBloc>(context).add(const LoadPhoneNumber());
  }

  var _currentPage = 0;
  GeoPoint? _location;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: NestedScrollView(
          headerSliverBuilder: (c, i) => [
            PostAppBar(
              title: tr(!updating ? 'new_rental' : 'update_rental'),
              onSave: () async {
                if (_formKey.currentState!.saveAndValidate()) {
                  BlocProvider.of<PublishBloc>(context).add(
                    !updating
                        ? PublishRental(
                            rentalMap: {
                              ..._formKey.currentState!.value,
                              'location': _location
                            },
                            images: _images.whereType<XFile>().toList(),
                          )
                        : UpdateRental(
                            id: widget.rental!.id!,
                            rental: {
                              ..._formKey.currentState!.value,
                              'location': _location,
                              'images': _images.whereType<String>().toList(),
                            },
                            images: _images.whereType<XFile>().toList(),
                          ),
                  );
                }
              },
            )
          ],
          body: BlocConsumer<PublishBloc, PublishState>(
            listener: (context, state) {
              if (state.status == PublishLoadStatus.failed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  ErrorSnackbar(message: state.error!),
                );
              } else if (state.status == PublishLoadStatus.published) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      updating ? 'rental_added' : 'rental_updated',
                    ).tr(),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  DetailsScreen.routeName,
                  ModalRoute.withName(HomeScreen.routeName),
                  arguments: state.rental,
                );
              } else if (state.status == PublishLoadStatus.archived ||
                  state.status == PublishLoadStatus.unachived ||
                  state.status == PublishLoadStatus.deleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.status == PublishLoadStatus.archived
                          ? 'rental_archived'
                          : state.status == PublishLoadStatus.deleted
                              ? 'rental_deleted'
                              : 'rental_unarchived',
                    ).tr(),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  HomeScreen.routeName,
                  (route) => false,
                );
              }
            },
            builder: (context, state) {
              _phoneController.text = state.phoneNumber ?? '';
              return Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        width: double.infinity,
                        child: CarouselSlider.builder(
                          itemCount: 1 + _images.length,
                          itemBuilder: (context, index, _) {
                            if (index == _images.length) {
                              return Center(
                                child: FloatingActionButton(
                                  heroTag: 'add_photo',
                                  child: const Icon(Icons.add_a_photo),
                                  onPressed: () {
                                    _showBottomSheet(context);
                                  },
                                ),
                              );
                            } else {
                              return Stack(
                                alignment: Alignment.center,
                                fit: StackFit.expand,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0),
                                      ),
                                      child: (_images[index] is String)
                                          ? CachedNetworkImage(
                                              imageUrl: _images[index],
                                              fit: BoxFit.cover,
                                            )
                                          : ImageBuilder(
                                              path: _images[index].path,
                                              aspectRatio: 16 / 9,
                                            ),
                                    ),
                                  ),
                                  if (index == _currentPage)
                                    Positioned(
                                      top: 0.0,
                                      right: 0.0,
                                      child: InkWell(
                                        onTap: () async {
                                          await _showRemoveImageDialog(
                                              context, index);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2.0),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                offset: Offset(0.0, 1.0),
                                                blurRadius: 1.0,
                                              )
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.blueGrey,
                                            size: 20.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }
                          },
                          options: CarouselOptions(
                            enableInfiniteScroll: false,
                            aspectRatio: 16 / 9,
                            onPageChanged: (i, _) => setState(
                              () => _currentPage = i,
                            ),
                          ),
                        ),
                      ),
                      FormBuilder(
                        key: _formKey,
                        initialValue: updating
                            ? widget.rental!.toJson().map((key, value) =>
                                (value is int?)
                                    ? MapEntry(key, '$value')
                                    : MapEntry(key, value))
                            : {},
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          children: [
                            CustomValidator(
                              validator: (_) {
                                if (_images.length < 3) {
                                  return tr('required_images');
                                }
                                if (_images.length > 10) {
                                  return tr('max10');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8.0),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 3.0),
                              child: const Text('title').tr(),
                            ),
                            FormBuilderTextField(
                              name: 'title',
                              textInputAction: TextInputAction.next,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                    errorText: tr('required')),
                              ]),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 3.0),
                              child: const Text('property_type').tr(),
                            ),
                            FormBuilderDropdown(
                              name: 'propertyType',
                              initialValue: updating
                                  ? widget.rental!.propertyType ??
                                      PropertyType.apartment
                                  : PropertyType.apartment,
                              valueTransformer: (PropertyType? value) {
                                if (value != null) {
                                  return value.name;
                                }
                              },
                              items: List.generate(
                                PropertyType.values.length - 1,
                                (index) => DropdownMenuItem(
                                  value: PropertyType.values[index + 1],
                                  child: Text(
                                    'propertyType.${index + 1}',
                                  ).tr(),
                                ),
                              ),
                              validator: FormBuilderValidators.required(
                                errorText: tr('required'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 3.0,
                              ),
                              child: const Text('address').tr(),
                            ),
                            FormBuilderTextField(
                              name: 'address',
                              minLines: 3,
                              maxLines: 3,
                              textInputAction: TextInputAction.next,
                              validator: FormBuilderValidators.required(
                                errorText: tr('required'),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 3.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: const Text('governorate').tr(),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: const Text('region').tr(),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: const Text('period').tr(),
                                  )
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: FormBuilderDropdown(
                                    name: 'governorate',
                                    initialValue: updating
                                        ? widget.rental!.governorate
                                        : Governorate.cairo,
                                    valueTransformer: (Governorate? value) {
                                      if (value != null) {
                                        return value.name;
                                      }
                                    },
                                    items: List.generate(
                                      27,
                                      (index) => DropdownMenuItem(
                                        value: Governorate.values[index + 1],
                                        child: Text(
                                          'governorates.${index + 1}',
                                          overflow: TextOverflow.ellipsis,
                                        ).tr(),
                                      ),
                                    ),
                                    validator: FormBuilderValidators.required(
                                      errorText: tr('required'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Flexible(
                                    child: FormBuilderTextField(
                                        name: 'region',
                                        textInputAction: TextInputAction.next,
                                        validator:
                                            FormBuilderValidators.maxLength(15,
                                                errorText: 'max15'))),
                                const SizedBox(width: 8.0),
                                Flexible(
                                  child: FormBuilderDropdown(
                                    name: 'rentPeriod',
                                    initialValue: updating
                                        ? widget.rental!.rentPeriod ??
                                            RentPeriod.day
                                        : RentPeriod.day,
                                    valueTransformer: (RentPeriod? value) {
                                      if (value != null) {
                                        return value.name;
                                      }
                                    },
                                    items: List.generate(
                                      RentPeriod.values.length - 1,
                                      (index) => DropdownMenuItem(
                                        value: RentPeriod.values[index + 1],
                                        child: Text(
                                          'rentPeriod.${index + 1}',
                                          overflow: TextOverflow.ellipsis,
                                        ).tr(),
                                      ),
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(
                                          errorText: tr('required')),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 3.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(child: const Text('area').tr()),
                                  const SizedBox(width: 8.0),
                                  Expanded(child: const Text('price').tr()),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'area',
                                    valueTransformer: (String? value) {
                                      if (value != null) {
                                        return int.tryParse(value);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      suffix: RichText(
                                        text: TextSpan(
                                          text: 'm\u00b3',
                                          style: TextStyle(
                                            color: Colors.black.withAlpha(175),
                                          ),
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(
                                        errorText: tr('required'),
                                      ),
                                      FormBuilderValidators.numeric(),
                                    ]),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'price',
                                    valueTransformer: (String? value) {
                                      if (value != null) {
                                        return int.tryParse(value);
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      suffix: Text('EGP'),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(
                                        errorText: tr('required'),
                                      ),
                                      FormBuilderValidators.numeric(),
                                    ]),
                                  ),
                                )
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 3.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(child: const Text('floor').tr()),
                                  const SizedBox(width: 8.0),
                                  Expanded(child: const Text('rooms').tr()),
                                  const SizedBox(width: 8.0),
                                  Expanded(child: const Text('bathrooms').tr()),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: FormBuilderTextField(
                                    name: 'floorNumber',
                                    valueTransformer: (String? value) {
                                      if (value != null) {
                                        return int.tryParse(value);
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Flexible(
                                  child: FormBuilderTextField(
                                    name: 'rooms',
                                    valueTransformer: (String? value) {
                                      if (value != null) {
                                        return int.tryParse(value);
                                      }
                                    },
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Flexible(
                                  child: FormBuilderTextField(
                                    name: 'bathrooms',
                                    valueTransformer: (String? value) {
                                      if (value != null) {
                                        return int.tryParse(value);
                                      }
                                    },
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 3.0,
                              ),
                              child: const Text('phone_number').tr(),
                            ),
                            FormBuilderTextField(
                              name: 'hostPhone',
                              controller: _phoneController,
                              focusNode: DisabledFocusNode(),
                              readOnly: true,
                              decoration: InputDecoration(
                                fillColor: Colors.grey.shade300,
                                prefix: const Text('+20  '),
                                suffixIcon: TextButton(
                                  child: const Text('change').tr(),
                                  onPressed: () async {
                                    await Navigator.of(context).pushNamed(
                                      HostScreen.routeName,
                                    );
                                    BlocProvider.of<PublishBloc>(context).add(
                                      const LoadPhoneNumber(),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 3.0,
                              ),
                              child: const Text('description').tr(),
                            ),
                            FormBuilderTextField(
                              name: 'description',
                              minLines: 3,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: tr('details_hint'),
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 16.0),
                            AddMapButton(
                              initialPosition: widget.rental?.location,
                              onLocationChanged: (location) {
                                if (location != null) {
                                  setState(() {
                                    _location = GeoPoint(
                                      location.latitude,
                                      location.longitude,
                                    );
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 10.0),
                            if (updating)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ArchiveButton(
                                    isArchived: widget.rental!.publishStatus ==
                                        PublishStatus.archived,
                                    onPressed: (isArchived) async =>
                                        await _showAlertDialog(
                                      context,
                                      title: tr(
                                          isArchived ? 'unarchive' : 'archive'),
                                      onPositive: () {
                                        context.read<PublishBloc>().add(
                                              ArchiveRental(
                                                rental: widget.rental!,
                                              ),
                                            );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete),
                                    label: const Text('delete').tr(),
                                    style: TextButton.styleFrom(
                                      primary: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await _showAlertDialog(
                                        context,
                                        title: tr('delete'),
                                        onPositive: () {
                                          context.read<PublishBloc>().add(
                                                DeleteRental(
                                                  rental: widget.rental!,
                                                ),
                                              );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 10.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (state.status == PublishLoadStatus.loading)
                    const LoadingWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<dynamic> _showRemoveImageDialog(BuildContext context, int index) {
    return showDialog(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: const Text(
            'remove_image',
          ).tr(),
          onPositive: () {
            setState(() {
              _images.removeAt(index);
            });
          },
        );
      },
    );
  }

  Future _showAlertDialog(
    BuildContext context, {
    required String title,
    required Function() onPositive,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: Text('$title ${tr('rental')}'),
        content: const Text('archive_content').tr(args: [title.toLowerCase()]),
        onPositive: onPositive,
      ),
    );
  }

  Future<void> _showBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => ImagePickerBottomSheet(
        onImagesPicked: (images) => setState(
          () => _images.addAll(images),
        ),
      ),
    );
  }
}

class DisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
