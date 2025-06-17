import 'dart:async';
import 'package:assignment_tripmate/firebase_options.dart';
import 'package:assignment_tripmate/screens/login.dart';
import 'package:assignment_tripmate/screens/tarvel_agent_sign_up.dart';
import 'package:assignment_tripmate/screens/user/carRentalDetails.dart';
import 'package:assignment_tripmate/screens/user/homepage.dart';
import 'package:assignment_tripmate/screens/user/localBuddyDetails.dart';
import 'package:assignment_tripmate/screens/user/viewAIItinerary.dart';
import 'package:assignment_tripmate/screens/user/viewTourDetails.dart';
import 'package:assignment_tripmate/screens/user_sign_up.dart';
import 'package:assignment_tripmate/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    router = GoRouter(
      initialLocation: '/',
      restorationScopeId: 'router_state',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/userRegister',
          builder: (context, state) => const UserSignUpScreen(),
        ),
        GoRoute(
          path: '/travelAgentRegister',
          builder: (context, state) => const TravelAgentSignUpScreen(),
        ),
        GoRoute(
          path: '/userHomepage/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return UserHomepageScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/viewTourDetails/:userId/:countryName/:cityName/:tourId/:fromAppLink',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final countryName = state.pathParameters['countryName']!;
            final cityName = state.pathParameters['cityName']!;
            final tourId = state.pathParameters['tourId']!;
            final fromAppLink = state.pathParameters['fromAppLink']!;

            return ViewTourDetailsScreen(
              userId: userId,
              countryName: countryName,
              cityName: cityName,
              tourID: tourId,
              fromAppLink: fromAppLink, // Pass the parsed value
            );
          },
        ),
        GoRoute(
          path: '/carRentalDetails/:userId/:carId/:fromAppLink',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final carId = state.pathParameters['carId']!;
            final fromAppLink = state.pathParameters['fromAppLink']!;

            return CarRentalDetailsScreen(
              userId: userId,
              carId: carId,
              fromAppLink: fromAppLink, // Pass the parsed value
            );
          },
        ),
        GoRoute(
          path: '/localBuddyDetails/:userId/:localBuddyId/:fromAppLink',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final localBuddyId = state.pathParameters['localBuddyId']!;
            final fromAppLink = state.pathParameters['fromAppLink']!;

            return LocalBuddyDetailsScreen(
              userId: userId,
              localBuddyId: localBuddyId,
              fromAppLink: fromAppLink, // Pass the parsed value
            );
          },
        ),
        GoRoute(
          path: '/viewAIItinerary/:userId/:itineraryID/:fromAppLink',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final itineraryID = state.pathParameters['itineraryID']!;
            final fromAppLink = state.pathParameters['fromAppLink']!;

            return ViewAIItineraryScreen(
              userId: userId,
              itineraryID: itineraryID,
              fromAppLink: fromAppLink, // Pass the parsed value
            );
          },
        ),
      ],
      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(child: Text('Error: ${state.error}')),
        );
      },
    );
  }

  Future<void> _initDeepLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('onAppLink: $uri');
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    print('Url: ${uri.toString()}');
    
    if (uri.pathSegments.isNotEmpty && uri.host == 'tripmate.com') {
      print('Host and path segments match');
      
      final path = uri.pathSegments[0];
      
      if (path == 'viewTourDetails') {
        print('Navigating to viewTourDetails');
        
        final userId = uri.pathSegments[1];
        final countryName = uri.pathSegments[2];
        final cityName = uri.pathSegments[3];
        final tourId = uri.pathSegments[4];
        final fromAppLink = uri.pathSegments[5];

        print('User ID: $userId, Country: $countryName, City: $cityName, Tour ID: $tourId, From App Link: $fromAppLink');

        context.go('/viewTourDetails/$userId/$countryName/$cityName/$tourId/$fromAppLink');

      } else if (path == 'carRentalDetails') {
        print('Navigating to carRentalDetails');
        
        final userId = uri.pathSegments[1];
        final carId = uri.pathSegments[2];
        final fromAppLink = uri.pathSegments[3];

        print('User ID: $userId, Car ID: $carId, From App Link: $fromAppLink');

        context.go('/carRentalDetails/$userId/$carId/$fromAppLink');

      } else if (path == 'localBuddyDetails') {
        print('Navigating to localBuddyDetails');
        
        final userId = uri.pathSegments[1];
        final localBuddyId = uri.pathSegments[2];
        final fromAppLink = uri.pathSegments[3];

        print('User ID: $userId, Local Buddy ID: $localBuddyId, From App Link: $fromAppLink');

        context.go('/localBuddyDetails/$userId/$localBuddyId/$fromAppLink');

      } else if (path == 'viewAIItinerary') {
        print('Navigating to viewAIItinerary');
        
        final userId = uri.pathSegments[1];
        final itineraryID = uri.pathSegments[2];
        final fromAppLink = uri.pathSegments[3];


        context.go('/viewAIItinerary/$userId/$itineraryID/$fromAppLink');

      }else {
        print('No matching path found: $path');
      }
    } else {
      print('URI host or pathSegments do not match');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // @override
  Widget build(BuildContext context) {

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      restorationScopeId: 'app_state',
    );
  }
}
