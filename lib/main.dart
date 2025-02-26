// import 'package:flutter/material.dart';
// import 'package:logistics/screens/auth/auth_provider.dart';
// import 'package:logistics/screens/auth/business_screen.dart';
// import 'package:logistics/screens/auth/freight_master_screen.dart';
// import 'package:logistics/screens/auth/generate_bill_screen.dart';
// import 'package:logistics/screens/auth/home_screen.dart';
// import 'package:logistics/screens/auth/reports_screen.dart';
// import 'package:logistics/screens/auth/todays_list_screen.dart';
// import 'package:logistics/screens/auth/transaction_screen.dart';
// import 'package:logistics/screens/auth/vehicle_list_screen.dart';
// import 'package:logistics/screens/auth/vendor_screen.dart';
// import 'package:logistics/screens/auth/login_screen.dart';
// import 'package:logistics/screens/auth/signup_screen.dart';
// import 'package:logistics/screens/auth/reset_password_screen.dart';
// import 'package:provider/provider.dart';
// import 'config/services/auth_service.dart';
// import 'package:logistics/screens/auth/notification_page.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//       ],
//       child: MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   final _authService = AuthService();
//   final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
//   MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Logistics App',
//       navigatorKey: navigatorKey,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       initialRoute: '/login',
//       onGenerateRoute: (settings) {
//         // Add debug print to track navigation
//         print('Navigating to: ${settings.name} with arguments: ${settings.arguments}');
//
//         switch (settings.name) {
//           case '/':
//             return _buildPageRoute(LoginScreen());
//           case '/login':
//             return _buildPageRoute(LoginScreen());
//           case '/signup':
//             return _buildPageRoute(SignUpScreen());
//           case '/home':
//             final args = settings.arguments as Map<String, dynamic>;
//             return PageRouteBuilder(
//               pageBuilder: (context, animation, secondaryAnimation) =>
//                   // TruckDetailsScreen(username: settings.arguments as String?),
//               TruckDetailsScreen(
//                   username: args['username'] as String?,
//                   profile: args['profile'] as String?
//               ),
//               transitionsBuilder: (context, animation, secondaryAnimation, child) {
//                 const transitionDuration = Duration(milliseconds: 300);
//                 var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
//                     .chain(CurveTween(curve: Curves.easeInOut));
//                 var offsetAnimation = animation.drive(tween);
//                 return SlideTransition(position: offsetAnimation, child: child);
//               },
//             );
//
//           case '/todaylist':
//             return _buildPageRoute(TodaysListScreen());
//           case '/reset-password':
//             return _buildPageRoute(const ResetPasswordScreen());
//           case '/freight':
//             return _buildPageRoute(FreightScreen());
//           case '/vehicle':
//             return _buildPageRoute(VehicleScreen());
//           case '/vendor':
//             return _buildPageRoute(VendorScreen());
//           case '/reports':
//             return _buildPageRoute(const ReportsScreen());
//           case '/generate-bill':
//             return _buildPageRoute(GenerateBillScreen());
//           case '/transaction':
//             return _buildPageRoute(TransactionsScreen());
//           case '/business':
//           // Ensure BusinessScreen is properly instantiated
//             return _buildPageRoute(const BusinessScreen());
//           default:
//             return _buildPageRoute(const Scaffold(
//               body: Center(child: Text('Route not found')),
//             ));
//         }
//       },
//       home: FutureBuilder<bool>(
//         future: _authService.checkAuth(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }
//
//           if (snapshot.hasError) {
//             return Scaffold(
//               body: Center(child: Text('Error: ${snapshot.error}')),
//             );
//           }
//
//           if (snapshot.hasData && snapshot.data!) {
//             return  TruckDetailsScreen();
//           } else {
//             return LoginScreen();
//           }
//         },
//       ),
//     );
//   }
//
//   PageRouteBuilder _buildPageRoute(Widget page) {
//     return PageRouteBuilder(
//       pageBuilder: (context, animation, secondaryAnimation) => page,
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         const transitionDuration = Duration(milliseconds: 300);
//         var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
//             .chain(CurveTween(curve: Curves.easeInOut));
//         var offsetAnimation = animation.drive(tween);
//
//         return SlideTransition(position: offsetAnimation, child: child);
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:logistics/screens/auth/auth_provider.dart';
import 'package:logistics/screens/auth/business_screen.dart';
import 'package:logistics/screens/auth/freight_master_screen.dart';
import 'package:logistics/screens/auth/generate_bill_screen.dart';
import 'package:logistics/screens/auth/home_screen.dart';
import 'package:logistics/screens/auth/reports_screen.dart';
import 'package:logistics/screens/auth/todays_list_screen.dart';
import 'package:logistics/screens/auth/transaction_screen.dart';
import 'package:logistics/screens/auth/vehicle_list_screen.dart';
import 'package:logistics/screens/auth/vendor_screen.dart';
import 'package:logistics/screens/auth/login_screen.dart';
import 'package:logistics/screens/auth/signup_screen.dart';
import 'package:logistics/screens/auth/reset_password_screen.dart';
import 'package:provider/provider.dart';
import 'config/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final _authService = AuthService();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Centralize route restrictions
  static final Map<String, List<String>> profileRestrictions = {
    'loadingManager': ['/freight', '/vehicle', '/vendor', '/reports', '/generate-bill', '/business', '/transaction'],
    'unloadingManager': ['/business', '/freight', '/vehicle', '/vendor', '/transaction', '/generate-bill'],
  };

  MyApp({super.key});

  // Function to check if a route is restricted for a profile
  bool isRouteRestricted(String? profile, String route) {
    return profile != null &&
        profileRestrictions.containsKey(profile) &&
        profileRestrictions[profile]!.contains(route);
  }

  // Function to handle restricted route access
  void handleRestrictedAccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to access this page'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.of(context).pop(); // Go back to previous screen
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents back navigation
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Logistics App',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          print('Navigating to: ${settings.name} with arguments: ${settings.arguments}');
      
          // Extract profile from route arguments
          String? profile;
          String? username;
          if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            profile = args['profile'] as String?;
            username = args['username'] as String?;
          }
      
          // Check for restricted access
          if (settings.name != null &&
              settings.name != '/login' &&
              settings.name != '/signup' &&
              settings.name != '/reset-password') {
            if (isRouteRestricted(profile, settings.name!)) {
              return MaterialPageRoute(
                builder: (context) {
                  handleRestrictedAccess(context);
                  return TruckDetailsScreen(username: username, profile: profile);
                },
              );
            }
          }
      
          // Regular route handling
          switch (settings.name) {
            case '/':
            case '/login':
              return _buildPageRoute(LoginScreen());
            case '/signup':
              return _buildPageRoute(SignUpScreen());
            case '/home':
              return _buildPageRoute(TruckDetailsScreen(
                username: username,
                profile: profile,
              ));
            case '/todaylist':
              return _buildPageRoute(TodaysListScreen());
            case '/reset-password':
              return _buildPageRoute(const ResetPasswordScreen());
            case '/freight':
              return _buildPageRoute(FreightScreen());
            case '/vehicle':
              return _buildPageRoute(VehicleScreen());
            case '/vendor':
              return _buildPageRoute(VendorScreen());
            case '/reports':
              return _buildPageRoute(const ReportsScreen());
            case '/generate-bill':
              return _buildPageRoute(GenerateBillScreen());
            case '/transaction':
              return _buildPageRoute(TransactionsScreen());
            case '/business':
              return _buildPageRoute(const BusinessScreen());
            default:
              return _buildPageRoute(const Scaffold(
                body: Center(child: Text('Route not found')),
              ));
          }
        },
        home: FutureBuilder<bool>(
          future: _authService.checkAuth(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
      
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
      
            if (snapshot.hasData && snapshot.data!) {
              return TruckDetailsScreen();
            } else {
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }

  PageRouteBuilder _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const transitionDuration = Duration(milliseconds: 300);
        var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  // Add logout method to clear stack
  // void logout(BuildContext context) {
  //   // Clear all routes and go to the login screen
  //   Navigator.pushAndRemoveUntil(
  //     context,
  //     MaterialPageRoute(builder: (context) => LoginScreen()),
  //         (Route<dynamic> route) => false, // This removes all previous routes
  //   );
  // }
  void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false, // This removes all previous routes
    );
  }

}