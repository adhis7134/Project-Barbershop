import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth_bloc.dart';
import 'core/api_client.dart';
import 'data/auth_repository.dart';
import 'data/cashier_repository.dart';
import 'data/customer_repository.dart';
import 'data/owner_repository.dart';
import 'screens/customer_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/owner_home_screen.dart';
import 'screens/queue_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(RodjaliApp(api: ApiClient()));
}

class RodjaliApp extends StatelessWidget {
  RodjaliApp({super.key, required this.api});

  final ApiClient api;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepository(api)),
        RepositoryProvider<CashierRepository>(create: (_) => CashierRepository(api)),
        RepositoryProvider<CustomerRepository>(create: (_) => CustomerRepository(api)),
        RepositoryProvider<OwnerRepository>(create: (_) => OwnerRepository(api)),
      ],
      child: BlocProvider(
        create: (ctx) {
          final bloc = AuthBloc(ctx.read<AuthRepository>());
          api.onUnauthorized = () => bloc.add(AuthSessionExpired());
          return bloc..add(AuthStarted());
        },
        child: MaterialApp(
          title: 'Rodjali Barbershop',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: BlocConsumer<AuthBloc, AuthState>(
            // Saat keluar/sesi habis, tutup layar yang sedang terbuka (mis. QRIS) agar kembali ke login.
            listenWhen: (p, c) => p is Authenticated && c is Unauthenticated,
            listener: (context, state) => _navigatorKey.currentState?.popUntil((r) => r.isFirst),
            builder: (context, state) {
              if (state is Authenticated) {
                if (state.user.isPelanggan) return CustomerHomeScreen(user: state.user);
                if (state.user.isPemilik) return OwnerHomeScreen(user: state.user);
                return QueueScreen(user: state.user);
              }
              if (state is AuthInitial) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
