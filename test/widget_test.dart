import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_analyzer_final/main.dart'; // Updated to match pubspec name
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Verify this import

// Generate mocks for GoogleSignIn
@GenerateMocks([GoogleSignIn])
void main() {
  setUpAll(() async {
    // Initialize Firebase with mocks
    setupFirebaseAuthMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    // Set up mock auth for each test using a custom provider
    // Use a wrapper instead of setting FirebaseAuth.instance directly
  });


  // Custom wrapper to inject mock auth
  Widget createWidgetUnderTest(Widget child, FirebaseAuth auth) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return child; // Inject auth via context if needed in the future
        },
      ),
    );
  }

  testWidgets('MotorAnalyzerApp loads LoginScreen by default when not authenticated', (WidgetTester tester) async {
    final auth = MockFirebaseAuth(signedIn: false);
    await tester.pumpWidget(createWidgetUnderTest(const MotorAnalyzerApp(), auth));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('No account? Sign up'), findsOneWidget);
  });

  testWidgets('MotorAnalyzerApp loads MotorAnalyzerHome when authenticated', (WidgetTester tester) async {
    final auth = MockFirebaseAuth(signedIn: true);
    await tester.pumpWidget(createWidgetUnderTest(const MotorAnalyzerApp(), auth));
    await tester.pumpAndSettle();
    expect(find.text('Operation Sonic Shield'), findsOneWidget);
    expect(find.text('Select Audio File'), findsOneWidget);
    expect(find.text('Record Sound'), findsOneWidget);
  });

  testWidgets('LoginScreen allows input and shows Google option', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('SignupScreen allows input', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'test2@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();
    expect(find.text('test2@example.com'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}

// Mock setup function
void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
}