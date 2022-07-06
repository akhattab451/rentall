import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../widgets/widgets.dart';
import '../../home/view/home_screen.dart';
import '../bloc/update_password_bloc.dart';

class UpdatePasswordScreen extends StatefulWidget {
  static const routeName = '/update_password';
  const UpdatePasswordScreen({Key? key}) : super(key: key);

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: NestedScrollView(
        headerSliverBuilder: (c, _) => [
          PostAppBar(
            title: 'Update Password',
            onSave: () {
              if (_formKey.currentState!.saveAndValidate()) {
                final value = _formKey.currentState!.value;
                BlocProvider.of<UpdatePasswordBloc>(context).add(
                  SavePressed(
                    newPassword: value['new'],
                    currentPassword: value['current'],
                  ),
                );
              }
            },
          )
        ],
        body: BlocConsumer<UpdatePasswordBloc, UpdatePasswordState>(
          listener: (context, state) {
            if (state.status == UpdatePasswordStatus.failed) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(ErrorSnackbar(message: state.message!));
            }
            if (state.status == UpdatePasswordStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
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
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FormBuilder(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Password'),
                          const SizedBox(height: 6.0),
                          FormBuilderTextField(
                            name: 'current',
                          ),
                          const SizedBox(height: 16.0),
                          const Text('New Password'),
                          const SizedBox(height: 6.0),
                          FormBuilderTextField(
                            name: 'new',
                            obscureText: true,
                            validator: FormBuilderValidators.required(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.status == UpdatePasswordStatus.loading)
                  const LoadingWidget()
              ],
            );
          },
        ),
      ),
    );
  }
}
