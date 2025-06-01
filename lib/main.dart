// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eventify2/firebase_options.dart';
import 'package:eventify2/pages/home_page.dart';

// Define the color palette
const Color burntOrange = Color(0xFFA34727);
const Color darkBrown = Color(0xFF5C2C1B);
const Color lightBeige = Color(0xFFF5F0EB);
const Color deepGray = Color(0xFF3B3B3B);
const Color softWhite = Color(0xFFFFFFFF); // Using pure white as per hex

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully!');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventify App', // Updated App Title
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Primary Colors
        primaryColor: burntOrange,
        colorScheme: ColorScheme.fromSeed(
          seedColor: burntOrange,
          primary: burntOrange,
          secondary: darkBrown, // Dark Brown as a secondary/accent
          background: lightBeige,
          surface: softWhite, // For cards, dialogs etc.
          onPrimary: softWhite, // Text on primary color (buttons, appbars)
          onSecondary: softWhite, // Text on secondary color
          onBackground: deepGray, // Main text color on background
          onSurface: deepGray, // Main text color on cards
          onError: softWhite,
          error: Colors.redAccent, // Standard error color
        ),
        scaffoldBackgroundColor: lightBeige,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: burntOrange, // Burnt Orange for AppBar background
          foregroundColor: softWhite, // Text and icons on AppBar
          elevation: 4.0,
          centerTitle: true, // Consistent centered titles
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: softWhite,
          ),
        ),

        // ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: burntOrange, // Button background
            foregroundColor: softWhite, // Button text color
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 18,
            ), // Made buttons bigger
            textStyle: const TextStyle(
              fontSize: 18, // Slightly larger button text
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),

        // OutlinedButton Theme (e.g., Delete button)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: burntOrange, // Text and icon color
            side: const BorderSide(color: burntOrange, width: 1.5),
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 18,
            ), // Made buttons bigger
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // TextButton Theme (e.g., dialog actions)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: burntOrange, // Text color
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Card Theme

        // Text Theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: deepGray, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(
            color: deepGray,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(color: deepGray, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(
            color: deepGray,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: deepGray,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            color: deepGray,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: deepGray,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ), // Used for card titles
          titleMedium: TextStyle(color: darkBrown, fontSize: 16),
          titleSmall: TextStyle(color: darkBrown, fontSize: 14),
          bodyLarge: TextStyle(
            color: deepGray,
            fontSize: 16,
          ), // Default body text
          bodyMedium: TextStyle(color: deepGray, fontSize: 14),
          bodySmall: TextStyle(
            color: deepGray,
            fontSize: 12,
          ), // For less important text
          labelLarge: TextStyle(
            color: softWhite,
            fontWeight: FontWeight.bold,
          ), // For button text via theme
        ),

        // Icon Theme
        iconTheme: const IconThemeData(
          color: darkBrown, // Default icon color
        ),
        primaryIconTheme: const IconThemeData(
          color: softWhite, // Icons on primary-colored surfaces (like AppBar)
        ),

        // Input Decoration Theme (for TextFormFields)
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: darkBrown),
          hintStyle: TextStyle(color: deepGray.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: darkBrown),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: darkBrown.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: burntOrange, width: 2.0),
          ),
          prefixIconColor: darkBrown,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}
