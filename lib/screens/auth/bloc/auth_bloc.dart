import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repository/user_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitital()) {
    on<SignInPressed>(_onSignInPressed);
    on<SignUpPressed>(_onSignUpPressed);
    on<ForgotPassword>(_onForgotPassword);
    on<SignInByGoogle>(_onSignInByGoogle);
  }

  FutureOr<void> _onSignInPressed(SignInPressed event, emit) async {
    emit(AuthLoading());
    try {
      final user =
          await repository.signInEmailAndPassword(event.email, event.password);

      if (user != null) {
        emit(SignInSuccess(user: user));
      } else {
        emit(const AuthFailed(message: 'Invalid credentials'));
      }
    } on Exception catch (err) {
      emit(AuthFailed(message: (err as dynamic).message));
    }
  }

  FutureOr<void> _onSignInByGoogle(SignInByGoogle event, emit) async {
    emit(AuthLoading());
    try {
      // User? theUser = (await userrepo.signInWithGoogle()) as User?;
      // yield LoginSuccessState(user: theUser!);
    } catch (e) {
      emit(AuthFailed(message: e.toString()));
    }
  }

  FutureOr<void> _onSignUpPressed(SignUpPressed event, emit) async {
    emit(AuthLoading());
    try {
      final user = await repository.signUpWithEmailAndPassword(
        event.email,
        event.password,
      );

      if (user != null) {
        emit(SignUpSuccess(user: user));
      } else {
        emit(const AuthFailed(message: 'Sign up failed.'));
      }
    } on Exception catch (err) {
      emit(AuthFailed(message: (err as dynamic).message));
    }
  }

  FutureOr<void> _onForgotPassword(ForgotPassword event, emit) async {
    emit(AuthLoading());
    try {
      await repository.sendForgotPasswordEmail(event.email);
      emit(EmailSent(email: event.email));
    } on Exception catch (err) {
      emit(AuthFailed(message: (err as dynamic).message));
    }
  }
}
