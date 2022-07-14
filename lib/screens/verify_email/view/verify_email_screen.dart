import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentall/screens/home/home.dart';
import 'package:rentall/screens/verify_email/cubit/verify_email_cubit.dart';

class VerifyEmailScreen extends StatelessWidget {
  final bool first;
  static const routeName = '/verify_email';
  const VerifyEmailScreen({
    this.first = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: BlocBuilder<VerifyEmailCubit, VerifyEmailState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  first
                      ? 'Sign up successful, please check your email for verification'
                      : 'Please verify your email before posting new rentals',
                  style: const TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: ElevatedButton.styleFrom(
                        primary: state is ResendLoading ? Colors.grey : null,
                      ),
                      child: const Text('Resend Email'),
                      onPressed: () async {
                        if (state is! ResendLoading) {
                          await BlocProvider.of<VerifyEmailCubit>(context)
                              .sendVerificationEmail();
                        }
                      },
                    ),
                    const SizedBox(width: 16.0),
                    ElevatedButton(
                      child: const Text('Proceed'),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          HomeScreen.routeName,
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
                if (state is ResendLoading) ...[
                  const SizedBox(height: 24.0),
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 3.0),
                  )
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
