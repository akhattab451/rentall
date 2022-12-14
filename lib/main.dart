import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'firebase_options.dart';
import 'injector.dart' as di;
import 'router.dart' as router;
import 'screens/blocs.dart';
import 'screens/screens.dart';
import 'theme.dart' as theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await di.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.blueGrey,
    ),
  );
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }

  runApp(
    Phoenix(
      child: EasyLocalization(
        path: 'assets/translations',
        supportedLocales: const [Locale('en'), Locale('ar')],
        child: const RentallApp(),
      ),
    ),
  );
}

class RentallApp extends StatelessWidget {
  const RentallApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RentalsBloc>(
          create: (context) => di.sl()..add(const GetRentals()),
        ),
        BlocProvider<PublishBloc>(create: (context) => di.sl()),
        BlocProvider<AuthBloc>(create: (context) => di.sl()),
        BlocProvider<UpdateEmailBloc>(create: (context) => di.sl()),
        BlocProvider<UpdatePasswordBloc>(create: (context) => di.sl()),
        BlocProvider<UserBloc>(create: (context) => di.sl()),
        BlocProvider<HomeBloc>(create: (context) => di.sl()),
        BlocProvider<SearchBloc>(create: (context) => di.sl()),
        BlocProvider<DetailsBloc>(create: (context) => di.sl()),
        BlocProvider<HostBloc>(create: (context) => di.sl()),
        BlocProvider<ListBloc>(create: (context) => di.sl()),
        BlocProvider<VerifyEmailCubit>(create: (context) => di.sl()),
        BlocProvider<OwnerCubit>(create: (context) => di.sl()),
      ],
      child: MaterialApp(
        title: 'Rentall',
        debugShowCheckedModeBanner: false,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates
          ..add(
            FormBuilderLocalizations.delegate,
          ),
        theme: theme.themeData,
        themeMode: ThemeMode.light,
        darkTheme: theme.darkThemeData,
        initialRoute: HomeScreen.routeName,
        onGenerateRoute: router.onGenerateRoute,
      ),
    );
  }
}
