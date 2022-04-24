import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'src/bloc.dart';
import 'src/home/view/home_screen.dart';
import 'firebase_options.dart';
import 'src/injector.dart' as di;
import 'src/router.dart' as router;
import 'src/theme.dart' as theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.blueGrey),
  );
  runApp(
    EasyLocalization(
      path: 'assets/translations',
      supportedLocales: const [Locale('en'), Locale('ar')],
      child: const RentallApp(),
    ),
  );
}

class RentallApp extends StatelessWidget {
  const RentallApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PublishBloc>(
          create: (context) => di.sl(),
          dispose: (context, bloc) {
            bloc.dispose();
          },
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RentalsBloc>(
            create: (context) => di.sl()..add(const GetRentals()),
          ),
        ],
        child: MaterialApp(
          title: 'Rentall',
          debugShowCheckedModeBanner: false,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates
            ..add(FormBuilderLocalizations.delegate),
          theme: theme.themeData,
          initialRoute: HomeScreen.routeName,
          onGenerateRoute: router.onGenerateRoute,
        ),
      ),
    );
  }
}
