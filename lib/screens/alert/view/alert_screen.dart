import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rentall/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../bloc/alert_bloc.dart';

class AlertScreen extends StatefulWidget {
  final Alert? alert;
  static const routeName = '/alert';
  const AlertScreen({
    this.alert,
    Key? key,
  }) : super(key: key);

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final _controller = TextEditingController();
  late final _keywords = widget.alert?.keywords ?? ['Sample'];
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.alert == null;
    return Scaffold(
      body: BlocConsumer<AlertBloc, AlertState>(
        listener: (context, state) {
          if (state.status == AlertStatus.failed) {
            ScaffoldMessenger.of(context).showSnackBar(
              ErrorSnackbar(message: state.error!),
            );
          } else if (state.status == AlertStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Alert successfully ${isNew ? 'added' : 'updated'}.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state.status == AlertStatus.deleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rental was successfully deleted.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (c, i) => [
                  PostAppBar(
                    title: 'Create Alert',
                    onSave: () {
                      if (_formKey.currentState!.saveAndValidate()) {
                        final value = _formKey.currentState!.value;
                        BlocProvider.of<AlertBloc>(context).add(
                          isNew
                              ? AddAlert(
                                  alertMap: value,
                                  keywords: _keywords,
                                )
                              : UpdateAlert(
                                  id: widget.alert!.id!,
                                  alert: value,
                                  keywords: _keywords,
                                ),
                        );
                      }
                    },
                  )
                ],
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: isNew
                        ? {}
                        : widget.alert!.toJson().map(
                              (key, value) => (value is int?)
                                  ? MapEntry(key, '$value')
                                  : MapEntry(key, value),
                            ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Setup alerts to stay up-to-date and discover rentals matching your preference',
                            style: TextStyle(fontSize: 16.0),
                          ),
                          const SizedBox(height: 16.0),
                          const Text('Keywords'),
                          const SizedBox(height: 4.0),
                          Wrap(
                              spacing: 4.0,
                              children: _keywords
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => Chip(
                                      label: Text(e.value),
                                      onDeleted: () {
                                        setState(() {
                                          _keywords.removeAt(e.key);
                                        });
                                      },
                                    ),
                                  )
                                  .toList()),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _controller,
                                  onChanged: (value) {
                                    if (value.endsWith(' ') &&
                                        value.trim().isNotEmpty) {
                                      _addKeyword();
                                    }
                                  },
                                  minLines: 3,
                                  maxLines: 3,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              ElevatedButton(
                                onPressed: () {
                                  _addKeyword();
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          CustomValidator(
                            validator: (_) {
                              if (_keywords.isEmpty) {
                                return 'Keywords can\'t be empty';
                              }
                              if (_keywords.length > 15) {
                                return 'Maximum number of keywords is 15';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('Repeat every'),
                              const SizedBox(width: 10.0),
                              SizedBox(
                                width: 100.0,
                                child: FormBuilderTextField(
                                  name: 'repeat',
                                  keyboardType: TextInputType.number,
                                  valueTransformer: (String? value) {
                                    if (value != null) {
                                      return int.tryParse(value);
                                    }
                                  },
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(
                                      errorText: 'Required',
                                    ),
                                    FormBuilderValidators.notEqual(0),
                                    FormBuilderValidators.max(14),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              const Text('day'),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          if (widget.alert != null) ...[
                            const Spacer(),
                            Center(
                              child: TextButton.icon(
                                label: const Text('Delete'),
                                icon: const Icon(Icons.delete),
                                style:
                                    TextButton.styleFrom(primary: Colors.red),
                                onPressed: () => _showAlertDialog(
                                  context,
                                  title: const Text('Delete Alert'),
                                  content: const Text(
                                    'Are you sure you want to delete this alert?',
                                  ),
                                  onPositive: () {
                                    BlocProvider.of<AlertBloc>(context).add(
                                      DeleteAlert(id: widget.alert!.id!),
                                    );
                                  },
                                ),
                              ),
                            )
                          ],
                        ]),
                  ),
                ),
              ),
              if (state.status == AlertStatus.loading) const LoadingWidget(),
            ],
          );
        },
      ),
    );
  }

  void _addKeyword() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _keywords.add(_controller.text.trim());
        _controller.clear();
      });
    }
  }

  Future _showAlertDialog(
    BuildContext context, {
    Widget? title,
    Widget? content,
    required Function() onPositive,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        onPositive: onPositive,
      ),
    );
  }
}
