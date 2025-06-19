import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for JSON handling
import 'package:permission_handler/permission_handler.dart'; // Added for permission management

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MotorAnalyzerApp());
}

class MotorAnalyzerApp extends StatelessWidget {
  const MotorAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Operation Sonic Shield',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E), // Dark blue from logo
        scaffoldBackgroundColor: const Color(0xFF0D1B2A), // Deep background
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFB0BEC5), // Metallic accent
          surface: const Color(0xFF263238), // Card background
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MotorAnalyzerHome(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return snapshot.hasData ? const MotorAnalyzerHome() : const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _logger = Logger();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Login failed');
      _logger.e('Email sign-in error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _errorMessage = 'Google Sign-In cancelled');
        return;
      }
      final googleAuth = await googleUser.authentication;
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );
    } catch (e) {
      _logger.e('Google Sign-In error: $e');
      setState(() => _errorMessage = 'Google Sign-In failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 100),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_errorMessage.isNotEmpty) Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(onPressed: _signInWithEmail, child: const Text('Login')),
                      ElevatedButton(onPressed: _signInWithGoogle, child: const Text('Sign in with Google')),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text('No account? Sign up'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _logger = Logger();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Signup failed');
      _logger.e('Signup error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 100),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_errorMessage.isNotEmpty) Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _signUp, child: const Text('Sign Up')),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class MotorAnalyzerHome extends StatefulWidget {
  const MotorAnalyzerHome({super.key});

  @override
  MotorAnalyzerHomeState createState() => MotorAnalyzerHomeState();
}

class MotorAnalyzerHomeState extends State<MotorAnalyzerHome> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final Logger _logger = Logger();
  bool _isRecording = false;
  String _filePath = '';
  String _classificationResult = 'No result yet';
  List<Map<String, dynamic>> _analysisHistory = [];
  tfl.Interpreter? _interpreter;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadModel();
    _loadLabels();
    _loadHistory();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    // Request permissions
    final status = await [
      Permission.microphone,
      Permission.storage,
    ].request();
    if (status[Permission.microphone]!.isDenied || status[Permission.storage]!.isDenied) {
      _logger.w('Permissions denied');
      setState(() => _classificationResult = 'Permissions denied');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      setState(() => _labels = labelsData.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList());
    } catch (e) {
      _logger.e('Error loading labels: $e');
      setState(() => _classificationResult = 'Error loading labels');
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset('final_model.tflite');
      setState(() => _classificationResult = 'Model loaded');
    } catch (e) {
      _logger.e('Error loading model: $e');
      setState(() => _classificationResult = 'Error loading model');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/analysis_history.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() => _analysisHistory = (jsonDecode(content) as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
      }
    } catch (e) {
      _logger.e('Error loading history: $e');
    }
  }

  Future<void> _saveHistory(String result) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/analysis_history.json');
      final entry = {
        'timestamp': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        'result': result,
      };
      _analysisHistory.insert(0, entry);
      await file.writeAsString(jsonEncode(_analysisHistory.take(10).toList())); // Limit to 10 entries
      setState(() {});
    } catch (e) {
      _logger.e('Error saving history: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _recorder.stopRecorder();
      setState(() => _isRecording = false);
      await _classifyAudio(_filePath);
    } else {
      final dir = await getTemporaryDirectory();
      _filePath = path.join(dir.path, 'recording.wav');
      await _recorder.startRecorder(toFile: _filePath, codec: Codec.pcm16WAV, sampleRate: 16000, numChannels: 1);
      setState(() {
        _isRecording = true;
        _classificationResult = 'Recording...';
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _filePath = result.files.single.path!;
      setState(() => _classificationResult = 'Analyzing...');
      await _classifyAudio(_filePath);
    } else {
      setState(() => _classificationResult = 'No file selected');
    }
  }

  Future<void> _classifyAudio(String audioPath) async {
    if (_interpreter == null || _labels.isEmpty) {
      setState(() => _classificationResult = 'Model or labels not loaded');
      return;
    }
    try {
      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();
      final audioData = audioBytes.buffer.asInt16List().map((e) => e / 32768.0).toList();
      final inputSize = _interpreter!.getInputTensor(0).shape.reduce((a, b) => a * b);
      final input = [audioData.sublist(0, inputSize > audioData.length ? audioData.length : inputSize)];
      final output = List.filled(1, List.filled(_labels.length, 0.0));
      _interpreter!.run(input, output);
      final maxScore = output[0].reduce((a, b) => a > b ? a : b);
      final predictedIndex = output[0].indexOf(maxScore);
      if (predictedIndex >= 0 && predictedIndex < _labels.length) {
        final result = 'Motor Status: ${_labels[predictedIndex].replaceAll('_', ' ').toUpperCase()}';
        setState(() => _classificationResult = result);
        await _saveHistory(result);
      } else {
        setState(() => _classificationResult = 'Invalid prediction');
      }
    } catch (e) {
      _logger.e('Classification error: $e');
      setState(() => _classificationResult = 'Error processing audio');
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      _logger.e('Sign-out error: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operation Sonic Shield'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Analysis History'),
                content: SizedBox(
                  height: 200,
                  width: 300,
                  child: ListView.builder(
                    itemCount: _analysisHistory.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_analysisHistory[index]['result']),
                      subtitle: Text(_analysisHistory[index]['timestamp']),
                    ),
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
              ),
            );
          }),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 150),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Select Audio File'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Record Sound'),
            ),
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_classificationResult, style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}