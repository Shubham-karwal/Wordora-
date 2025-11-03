import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// ---------- HELPER WIDGET FOR LOCK/UNLOCK ----------
Widget buildSetTile(
  BuildContext context,
  String title,
  bool unlocked,
  VoidCallback onTap,
) {
  return Opacity(
    opacity: unlocked ? 1.0 : 0.5,
    child: Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: unlocked
              ? onTap
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please log in to unlock")),
                  );
                },
          child: Container(
            height: 100,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (!unlocked) const Icon(Icons.lock, color: Colors.white70, size: 40),
      ],
    ),
  );
}

// --- MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => QuizProvider()),
        Provider<AuthService>(
          create: (_) => AuthService(FirebaseAuth.instance),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: const WordQuizApp(),
    ),
  );
}

// --- DATA: WORD LISTS BY DIFFICULTY ---
enum Difficulty { easy, medium, hard }

final Map<Difficulty, List<List<String>>> wordSets = {
  Difficulty.easy: [
    // Set 1
    [
      'happy',
      'run',
      'sun',
      'water',
      'book',
      'friend',
      'smile',
      'laugh',
      'tree',
      'house',
      'eat',
      'sleep',
      'play',
      'cat',
      'dog',
      'big',
      'small',
      'love',
      'kind',
      'fast',
    ],
    // Set 2
    [
      'blue',
      'red',
      'jump',
      'walk',
      'baby',
      'food',
      'car',
      'ball',
      'sky',
      'moon',
      'star',
      'hand',
      'foot',
      'talk',
      'sing',
      'read',
      'write',
      'cold',
      'hot',
      'dark',
    ],
    // Set 3
    [
      'light',
      'day',
      'night',
      'good',
      'bad',
      'sad',
      'cry',
      'work',
      'rest',
      'city',
      'town',
      'road',
      'ship',
      'boat',
      'rain',
      'snow',
      'wind',
      'fire',
      'earth',
      'air',
    ],
    // Set 4
    [
      'bird',
      'fish',
      'song',
      'music',
      'art',
      'draw',
      'color',
      'door',
      'key',
      'lock',
      'open',
      'close',
      'give',
      'take',
      'help',
      'ask',
      'tell',
      'show',
      'see',
      'hear',
    ],
    // Set 5
    [
      'feel',
      'think',
      'know',
      'learn',
      'teach',
      'grow',
      'build',
      'break',
      'fix',
      'clean',
      'wash',
      'cook',
      'bake',
      'buy',
      'sell',
      'money',
      'time',
      'year',
      'month',
      'week',
    ],
  ],
  Difficulty.medium: [
    // Set 1
    [
      'benevolent',
      'ambiguous',
      'elaborate',
      'resilient',
      'nostalgia',
      'pragmatic',
      'ubiquitous',
      'eloquent',
      'diligent',
      'ephemeral',
      'gregarious',
      'meticulous',
      'paradox',
      'serene',
      'vibrant',
      'zealous',
      'candid',
      'empathy',
      'frugal',
      'legacy',
    ],
    // Set 2
    [
      'innovate',
      'mitigate',
      'prudent',
      'tenacious',
      'verbose',
      'abstract',
      'coherent',
      'diverse',
      'feasible',
      'implicit',
      'explicit',
      'justify',
      'leverage',
      'nuance',
      'perceive',
      'refute',
      'speculate',
      'sustain',
      'validate',
      'catalyst',
    ],
    // Set 3
    [
      'deduce',
      'empirical',
      'hypothesize',
      'infer',
      'precedent',
      'rationale',
      'relevant',
      'robust',
      'significant',
      'theory',
      'variable',
      'anomaly',
      'correlate',
      'deviate',
      'fluctuate',
      'paradigm',
      'phenomenon',
      'postulate',
      'simulate',
      'synthesis',
    ],
    // Set 4
    [
      'component',
      'constitute',
      'context',
      'criterion',
      'domain',
      'framework',
      'hierarchy',
      'integrate',
      'interact',
      'mechanism',
      'network',
      'parameter',
      'protocol',
      'sequence',
      'structure',
      'system',
      'taxonomy',
      'topology',
      'trajectory',
      'vector',
    ],
    // Set 5
    [
      'advocate',
      'alleviate',
      'articulate',
      'augment',
      'bolster',
      'concede',
      'consensus',
      'discourse',
      'disseminate',
      'endorse',
      'enhance',
      'expedite',
      'facilitate',
      'implement',
      'incentivize',
      'negotiate',
      'persuade',
      'proponent',
      'stipulate',
      'substantiate',
    ],
  ],
  Difficulty.hard: [
    // Set 1
    [
      'pulchritudinous',
      'sesquipedalian',
      'egregious',
      'obfuscate',
      'sycophant',
      'vicissitude',
      'cacophony',
      'epistemology',
      'idiosyncratic',
      'juxtaposition',
      'loquacious',
      'magnanimous',
      'onomatopoeia',
      'penultimate',
      'quixotic',
      'recalcitrant',
      'solipsism',
      'truculent',
      'verisimilitude',
      'zeitgeist',
    ],
    // Set 2
    [
      'abnegation',
      'anachronistic',
      'bellicose',
      'circumlocution',
      'deleterious',
      'exacerbate',
      'fastidious',
      'grandiloquent',
      'hegemony',
      'ignominious',
      'kowtow',
      'laconic',
      'maudlin',
      'nefarious',
      'ostracism',
      'panacea',
      'querulous',
      'raconteur',
      'sanctimonious',
      'turpitude',
    ],
    // Set 3
    [
      'abjure',
      'acerbic',
      'blandishment',
      'cognizant',
      'diaphanous',
      'ebullient',
      'fatuous',
      'garrulous',
      'harangue',
      'iconoclast',
      'jejune',
      'ken',
      'limpid',
      'mellifluous',
      'nadir',
      'obsequious',
      'paucity',
      'quagmire',
      'redoubtable',
      'salient',
    ],
    // Set 4
    [
      'taciturn',
      'umbrage',
      'vituperate',
      'winsome',
      'xenophobia',
      'yoke',
      'zephyr',
      'antediluvian',
      'bombastic',
      'capricious',
      'denigrate',
      'efficacious',
      'forbearance',
      'guile',
      'histrionic',
      'impecunious',
      'licentious',
      'myriad',
      'nascent',
      'opprobrium',
    ],
    // Set 5
    [
      'paragon',
      'phlegmatic',
      'proclivity',
      'reprobate',
      'scurrilous',
      'sobriquet',
      'trenchant',
      'unctuous',
      'vacillate',
      'wanton',
      'acumen',
      'bilk',
      'chicanery',
      'demagogue',
      'execrable',
      'fortuitous',
      'gourmand',
      'inchoate',
      'mendacious',
      'pejorative',
    ],
  ],
};

// --- APP THEME AND SETUP ---
class WordQuizApp extends StatelessWidget {
  const WordQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1D1E2C),
        primaryColor: const Color(0xFF6A4DE8),
        fontFamily: 'Nunito',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      home: const LandingScreen(),
    );
  }
}

// --- AUTHENTICATION & DATABASE SERVICES ---
class AuthService {
  final FirebaseAuth _firebaseAuth;
  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Signed In";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An unknown error occurred.";
    }
  }

  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Signed Up";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An unknown error occurred.";
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserProgress(User user, Difficulty unlockedLevel) async {
    await _db.collection('users').doc(user.uid).set({
      'unlockedLevel': unlockedLevel.index,
    }, SetOptions(merge: true));
  }

  Future<Difficulty> getUserProgress(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return Difficulty.values[data['unlockedLevel'] ?? 0];
    }
    return Difficulty.easy;
  }
}

// --- UI: LOGIN & REGISTER SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;

  void _submit() async {
    final authService = context.read<AuthService>();
    String result;

    if (_isLogin) {
      result = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      result = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (mounted && (result == "Signed In" || result == "Signed Up")) {
      Navigator.of(context).pop(); // Go back to the previous screen on success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF1D1E2C)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A4DE8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(_isLogin ? 'Login' : 'Register'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'Need an account? Register'
                        : 'Have an account? Login',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- UI: LANDING SCREEN ---
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: AuthActionButton(),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Word Quiz',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 15, color: Colors.black38),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Challenge your vocabulary.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const SizedBox(height: 60),
                        ElevatedButton(
                          onPressed: () =>
                              _navigateTo(context, const DifficultyScreen()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A4DE8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Play Quiz'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- UI: DIFFICULTY SCREEN ---
class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  void _onDifficultySelected(BuildContext context, Difficulty difficulty) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SetSelectionScreen(difficulty: difficulty),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select Difficulty'),
          actions: const [AuthActionButton()],
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DifficultyButton(
                    text: 'Easy',
                    color: Colors.green,
                    onTap: () =>
                        _onDifficultySelected(context, Difficulty.easy),
                  ),
                  const SizedBox(height: 20),
                  DifficultyButton(
                    text: 'Medium',
                    color: Colors.orange,
                    onTap: () =>
                        _onDifficultySelected(context, Difficulty.medium),
                  ),
                  const SizedBox(height: 20),
                  DifficultyButton(
                    text: 'Hard',
                    color: Colors.red,
                    onTap: () =>
                        _onDifficultySelected(context, Difficulty.hard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- UI: SET SELECTION SCREEN ---
class SetSelectionScreen extends StatelessWidget {
  final Difficulty difficulty;
  const SetSelectionScreen({super.key, required this.difficulty});

  void _onSetSelected(BuildContext context, int setIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuizScreen(difficulty: difficulty, setIndex: setIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sets = wordSets[difficulty]!;
    final user = context.watch<User?>();
    final bool isGuest = user == null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select a Set'),
          actions: const [AuthActionButton()],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1,
          ),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final bool isSetLocked = isGuest && index >= 2;

            return buildSetTile(context, 'Set ${index + 1}', !isSetLocked, () {
              if (isSetLocked) {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              } else {
                _onSetSelected(context, index);
              }
            });
          },
        ),
      ),
    );
  }
}

/*class SetSelectionScreen extends StatelessWidget {
  final Difficulty difficulty;
  const SetSelectionScreen({super.key, required this.difficulty});

  void _onSetSelected(BuildContext context, int setIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuizScreen(difficulty: difficulty, setIndex: setIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sets = wordSets[difficulty]!;
    final user = context.watch<User?>();
    final bool isGuest = user == null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select a Set'),
          actions: const [AuthActionButton()],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1,
          ),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final bool isSetLocked =
                isGuest && index >= 2; // Sets 3, 4, 5 are locked for guests
            return Card(
              color: isSetLocked
                  ? const Color(0xFF2C2D4A).withOpacity(0.5)
                  : const Color(0xFF2C2D4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () {
                  if (isSetLocked) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } else {
                    _onSetSelected(context, index);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSetLocked)
                        const Icon(Icons.lock, color: Colors.white54, size: 40),
                      if (isSetLocked) const SizedBox(height: 8),
                      Text(
                        'Set ${index + 1}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isSetLocked ? Colors.white54 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}*/

// --- DATA MODELS & API ---
class QuizQuestion {
  final String word;
  final String correctDefinition;
  final List<String> options;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? audioUrl;

  QuizQuestion({
    required this.word,
    required this.correctDefinition,
    required this.options,
    required this.synonyms,
    required this.antonyms,
    this.audioUrl,
  });
}

class ApiService {
  Future<Map<String, dynamic>> fetchWordDetails(String word) async {
    final response = await http.get(
      Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body)[0];
      final meaning = data['meanings'][0];
      final definition =
          meaning['definitions'][0]['definition'] ?? 'No definition found.';
      final synonyms = List<String>.from(meaning['synonyms'] ?? []);
      final antonyms = List<String>.from(meaning['antonyms'] ?? []);

      String? audioUrl;
      if (data['phonetics'] != null) {
        for (var phonetic in data['phonetics']) {
          if (phonetic['audio'] != null && phonetic['audio'].isNotEmpty) {
            audioUrl = phonetic['audio'];
            break;
          }
        }
      }

      if (definition == 'No definition found.')
        throw Exception('No definition');
      return {
        'definition': definition,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'audioUrl': audioUrl,
      };
    }
    throw Exception('No definition for this word');
  }
}

// --- STATE MANAGEMENT ---
enum QuizState { loading, question, answered, finished }

class QuizProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late List<String> _currentWordSet;
  int _currentIndex = 0;
  QuizState _state = QuizState.loading;
  QuizQuestion? _currentQuestion;
  String? _selectedAnswer;
  String? _error;
  int _score = 0;

  QuizState get state => _state;
  QuizQuestion? get currentQuestion => _currentQuestion;
  String? get selectedAnswer => _selectedAnswer;
  bool get isCorrect => _selectedAnswer == _currentQuestion?.correctDefinition;
  String? get error => _error;
  int get score => _score;
  int get currentIndex => _currentIndex;

  void startQuiz(Difficulty difficulty, int setIndex) {
    _currentWordSet = List.from(wordSets[difficulty]![setIndex])
      ..shuffle(_random);
    _currentIndex = 0;
    _score = 0;
    _error = null;
    loadNewQuestion();
  }

  Future<void> loadNewQuestion() async {
    if (_currentIndex >= _currentWordSet.length) {
      _state = QuizState.finished;
      notifyListeners();
      return;
    }

    _state = QuizState.loading;
    _selectedAnswer = null;
    notifyListeners();

    try {
      final correctWord = _currentWordSet[_currentIndex];
      final wordDetails = await _apiService.fetchWordDetails(correctWord);
      final correctDefinition = wordDetails['definition'];

      List<String> distractorWords = List.from(_currentWordSet)
        ..remove(correctWord);
      distractorWords.shuffle(_random);
      List<String> options = [correctDefinition];

      for (int i = 0; i < 3 && i < distractorWords.length; i++) {
        try {
          final distractorDetails = await _apiService.fetchWordDetails(
            distractorWords[i],
          );
          options.add(distractorDetails['definition']);
        } catch (e) {
          print("Failed to fetch distractor definition, skipping.");
        }
      }

      options.shuffle(_random);

      _currentQuestion = QuizQuestion(
        word: correctWord,
        correctDefinition: correctDefinition,
        options: options,
        synonyms: wordDetails['synonyms'],
        antonyms: wordDetails['antonyms'],
        audioUrl: wordDetails['audioUrl'],
      );
      _state = QuizState.question;
    } catch (e) {
      _error = "Could not load question. Check connection.";
      _state = QuizState.question;
    }
    notifyListeners();
  }

  void submitAnswer(String answer) {
    if (_state == QuizState.question) {
      _selectedAnswer = answer;
      if (isCorrect) _score++;
      _state = QuizState.answered;
      notifyListeners();
    }
  }

  void nextQuestion() {
    _currentIndex++;
    loadNewQuestion();
  }

  Future<void> playPronunciation(String? url) async {
    if (url != null && url.isNotEmpty) {
      await _audioPlayer.play(UrlSource(url));
    }
  }
}

// --- UI: QUIZ SCREEN ---
class QuizScreen extends StatefulWidget {
  final Difficulty difficulty;
  final int setIndex;
  const QuizScreen({
    super.key,
    required this.difficulty,
    required this.setIndex,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().startQuiz(
        widget.difficulty,
        widget.setIndex,
      );
    });

    context.read<QuizProvider>().addListener(_onProviderStateChanged);
  }

  void _onProviderStateChanged() {
    if (!mounted) return;

    final provider = context.read<QuizProvider>();
    if (provider.state == QuizState.question) {
      _isNavigating = false;
      _animationController.forward(from: 0.0);
    } else if (provider.state == QuizState.finished && !_isNavigating) {
      _isNavigating = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            difficulty: widget.difficulty,
            score: provider.score,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    context.read<QuizProvider>().removeListener(_onProviderStateChanged);
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2D4A),
        title: const Text(
          'Are you sure?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to quit the quiz? Your progress will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Quit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final totalQuestions = wordSets[widget.difficulty]![widget.setIndex].length;
    final progress = provider.state == QuizState.loading
        ? provider.currentIndex / totalQuestions
        : (provider.currentIndex + 1) / totalQuestions;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Question ${provider.currentIndex + 1}/$totalQuestions',
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                tween: Tween<double>(
                  begin: 0,
                  end: progress.isNaN ? 0 : progress,
                ),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: const Color(0xFF6A4DE8).withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            actions: [
              const AuthActionButton(),
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Center(
                  child: Text(
                    'Score: ${provider.score}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildContent(context, provider),
    );
  }

  Widget _buildContent(BuildContext context, QuizProvider provider) {
    if (provider.state == QuizState.loading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (provider.error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => provider.loadNewQuestion(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    final question = provider.currentQuestion;
    if (question == null) {
      return const Center(
        key: ValueKey('empty'),
        child: Text("Starting quiz...", style: TextStyle(color: Colors.white)),
      );
    }

    return SingleChildScrollView(
      key: ValueKey(question.word),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Animated Question Card
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final angle = (_animationController.value * pi);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: _animationController.value <= 0.5
                    ? Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2D4A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF6A4DE8).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "What is the meaning of...",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: Card(
                          color: Colors.white,
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  question.word,
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D1E2C),
                                  ),
                                ),
                                if (question.audioUrl != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.volume_up,
                                      color: Color(0xFF1D1E2C),
                                    ),
                                    onPressed: () => provider.playPronunciation(
                                      question.audioUrl,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 20),
          ...List.generate(question.options.length, (index) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.5 + (0.1 * index),
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.5 + (0.1 * index), 1.0),
                ),
                child: OptionButton(
                  text: question.options[index],
                  onTap: () => provider.submitAnswer(question.options[index]),
                  isCorrect:
                      question.options[index] == question.correctDefinition,
                  isSelected:
                      question.options[index] == provider.selectedAnswer,
                  showResult: provider.state == QuizState.answered,
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          if (provider.state == QuizState.answered)
            FadeTransition(
              opacity: const AlwaysStoppedAnimation(1),
              child: Column(
                children: [
                  if (!provider.isCorrect) ExplanationCard(question: question),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => provider.nextQuestion(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 50,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Next Question'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- UI: RESULTS SCREEN ---
class ResultsScreen extends StatefulWidget {
  final Difficulty difficulty;
  final int score;
  const ResultsScreen({
    super.key,
    required this.difficulty,
    required this.score,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _scoreAnimation = IntTween(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _checkAndUnlockLevel();
    _controller.forward();
  }

  Future<void> _checkAndUnlockLevel() async {
    final user = context.read<User?>();
    if (user == null) return; // Don't save progress for guests

    const totalQuestions = 20; // Each set has 20 questions
    if (widget.score >= totalQuestions * 0.75) {
      final nextLevelIndex = widget.difficulty.index + 1;
      if (nextLevelIndex < Difficulty.values.length) {
        final nextLevel = Difficulty.values[nextLevelIndex];
        await DatabaseService().saveUserProgress(user, nextLevel);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const total = 20; // Each set has 20 questions
    final percentage = (widget.score / total * 100).toStringAsFixed(0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.amber[300],
                  size: 120,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quiz Complete!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Score',
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, child) {
                  return Text(
                    '${_scoreAnimation.value} / $total',
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              Text(
                '($percentage%)',
                style: TextStyle(fontSize: 24, color: Colors.amber[300]),
              ),
              const SizedBox(height: 50),
              DifficultyButton(
                text: 'Play Another Set',
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const DifficultyScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              DifficultyButton(
                text: 'Main Menu',
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- UI WIDGETS ---
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({super.key, required this.question});
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2C2D4A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Correct Answer: ${question.word}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                if (question.audioUrl != null)
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white70),
                    onPressed: () => context
                        .read<QuizProvider>()
                        .playPronunciation(question.audioUrl),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"${question.correctDefinition}"',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            if (question.synonyms.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWordChipList('Synonyms', question.synonyms, Colors.green),
            ],
            if (question.antonyms.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWordChipList('Antonyms', question.antonyms, Colors.red),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWordChipList(String title, List<String> words, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue.shade300,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: words
              .map(
                (word) => Chip(
                  label: Text(word),
                  backgroundColor: color.withOpacity(0.2),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class OptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSelected, isCorrect, showResult;

  const OptionButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
  });

  Color _getBackgroundColor(BuildContext context) {
    if (!showResult) return Theme.of(context).primaryColor.withOpacity(0.2);
    if (isCorrect) return Colors.green.withOpacity(0.4);
    if (isSelected && !isCorrect) return Colors.red.withOpacity(0.4);
    return Theme.of(context).primaryColor.withOpacity(0.2);
  }

  Color _getBorderColor(BuildContext context) {
    if (!showResult) return Theme.of(context).primaryColor;
    if (isCorrect) return Colors.green;
    if (isSelected && !isCorrect) return Colors.red;
    return Theme.of(context).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: _getBorderColor(context), width: 2),
      ),
      child: InkWell(
        onTap: showResult ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              if (showResult)
                isCorrect
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : (isSelected
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class DifficultyButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  final bool isLocked;

  const DifficultyButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLocked ? null : onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isLocked ? Colors.grey.shade600 : color,
        disabledBackgroundColor: Colors.grey.shade600,
        minimumSize: const Size(double.infinity, 60),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLocked) const Icon(Icons.lock, size: 24),
          if (isLocked) const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: firebaseUser != null
          ? IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => context.read<AuthService>().signOut(),
            )
          : IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Login / Register',
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// --- MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => QuizProvider()),
        Provider<AuthService>(
          create: (_) => AuthService(FirebaseAuth.instance),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: const WordQuizApp(),
    ),
  );
}

// --- DATA: WORD LISTS BY DIFFICULTY ---
enum Difficulty { easy, medium, hard }

final Map<Difficulty, List<List<String>>> wordSets = {
  Difficulty.easy: [
    // Set 1
    [
      'happy',
      'run',
      'sun',
      'water',
      'book',
      'friend',
      'smile',
      'laugh',
      'tree',
      'house',
      'eat',
      'sleep',
      'play',
      'cat',
      'dog',
      'big',
      'small',
      'love',
      'kind',
      'fast',
    ],
    // Set 2
    [
      'blue',
      'red',
      'jump',
      'walk',
      'baby',
      'food',
      'car',
      'ball',
      'sky',
      'moon',
      'star',
      'hand',
      'foot',
      'talk',
      'sing',
      'read',
      'write',
      'cold',
      'hot',
      'dark',
    ],
    // Set 3
    [
      'light',
      'day',
      'night',
      'good',
      'bad',
      'sad',
      'cry',
      'work',
      'rest',
      'city',
      'town',
      'road',
      'ship',
      'boat',
      'rain',
      'snow',
      'wind',
      'fire',
      'earth',
      'air',
    ],
    // Set 4
    [
      'bird',
      'fish',
      'song',
      'music',
      'art',
      'draw',
      'color',
      'door',
      'key',
      'lock',
      'open',
      'close',
      'give',
      'take',
      'help',
      'ask',
      'tell',
      'show',
      'see',
      'hear',
    ],
    // Set 5
    [
      'feel',
      'think',
      'know',
      'learn',
      'teach',
      'grow',
      'build',
      'break',
      'fix',
      'clean',
      'wash',
      'cook',
      'bake',
      'buy',
      'sell',
      'money',
      'time',
      'year',
      'month',
      'week',
    ],
  ],
  Difficulty.medium: [
    // Set 1
    [
      'benevolent',
      'ambiguous',
      'elaborate',
      'resilient',
      'nostalgia',
      'pragmatic',
      'ubiquitous',
      'eloquent',
      'diligent',
      'ephemeral',
      'gregarious',
      'meticulous',
      'paradox',
      'serene',
      'vibrant',
      'zealous',
      'candid',
      'empathy',
      'frugal',
      'legacy',
    ],
    // Set 2
    [
      'innovate',
      'mitigate',
      'prudent',
      'tenacious',
      'verbose',
      'abstract',
      'coherent',
      'diverse',
      'feasible',
      'implicit',
      'explicit',
      'justify',
      'leverage',
      'nuance',
      'perceive',
      'refute',
      'speculate',
      'sustain',
      'validate',
      'catalyst',
    ],
    // Set 3
    [
      'deduce',
      'empirical',
      'hypothesize',
      'infer',
      'precedent',
      'rationale',
      'relevant',
      'robust',
      'significant',
      'theory',
      'variable',
      'anomaly',
      'correlate',
      'deviate',
      'fluctuate',
      'paradigm',
      'phenomenon',
      'postulate',
      'simulate',
      'synthesis',
    ],
    // Set 4
    [
      'component',
      'constitute',
      'context',
      'criterion',
      'domain',
      'framework',
      'hierarchy',
      'integrate',
      'interact',
      'mechanism',
      'network',
      'parameter',
      'protocol',
      'sequence',
      'structure',
      'system',
      'taxonomy',
      'topology',
      'trajectory',
      'vector',
    ],
    // Set 5
    [
      'advocate',
      'alleviate',
      'articulate',
      'augment',
      'bolster',
      'concede',
      'consensus',
      'discourse',
      'disseminate',
      'endorse',
      'enhance',
      'expedite',
      'facilitate',
      'implement',
      'incentivize',
      'negotiate',
      'persuade',
      'proponent',
      'stipulate',
      'substantiate',
    ],
  ],
  Difficulty.hard: [
    // Set 1
    [
      'pulchritudinous',
      'sesquipedalian',
      'egregious',
      'obfuscate',
      'sycophant',
      'vicissitude',
      'cacophony',
      'epistemology',
      'idiosyncratic',
      'juxtaposition',
      'loquacious',
      'magnanimous',
      'onomatopoeia',
      'penultimate',
      'quixotic',
      'recalcitrant',
      'solipsism',
      'truculent',
      'verisimilitude',
      'zeitgeist',
    ],
    // Set 2
    [
      'abnegation',
      'anachronistic',
      'bellicose',
      'circumlocution',
      'deleterious',
      'exacerbate',
      'fastidious',
      'grandiloquent',
      'hegemony',
      'ignominious',
      'kowtow',
      'laconic',
      'maudlin',
      'nefarious',
      'ostracism',
      'panacea',
      'querulous',
      'raconteur',
      'sanctimonious',
      'turpitude',
    ],
    // Set 3
    [
      'abjure',
      'acerbic',
      'blandishment',
      'cognizant',
      'diaphanous',
      'ebullient',
      'fatuous',
      'garrulous',
      'harangue',
      'iconoclast',
      'jejune',
      'ken',
      'limpid',
      'mellifluous',
      'nadir',
      'obsequious',
      'paucity',
      'quagmire',
      'redoubtable',
      'salient',
    ],
    // Set 4
    [
      'taciturn',
      'umbrage',
      'vituperate',
      'winsome',
      'xenophobia',
      'yoke',
      'zephyr',
      'antediluvian',
      'bombastic',
      'capricious',
      'denigrate',
      'efficacious',
      'forbearance',
      'guile',
      'histrionic',
      'impecunious',
      'licentious',
      'myriad',
      'nascent',
      'opprobrium',
    ],
    // Set 5
    [
      'paragon',
      'phlegmatic',
      'proclivity',
      'reprobate',
      'scurrilous',
      'sobriquet',
      'trenchant',
      'unctuous',
      'vacillate',
      'wanton',
      'acumen',
      'bilk',
      'chicanery',
      'demagogue',
      'execrable',
      'fortuitous',
      'gourmand',
      'inchoate',
      'mendacious',
      'pejorative',
    ],
  ],
};

// --- APP THEME AND SETUP ---
class WordQuizApp extends StatelessWidget {
  const WordQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1D1E2C),
        primaryColor: const Color(0xFF6A4DE8),
        fontFamily: 'Nunito',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      home: const LandingScreen(),
    );
  }
}

// --- AUTHENTICATION & DATABASE SERVICES ---
class AuthService {
  final FirebaseAuth _firebaseAuth;
  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Signed In";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An unknown error occurred.";
    }
  }

  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Signed Up";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An unknown error occurred.";
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserProgress(User user, Difficulty unlockedLevel) async {
    await _db.collection('users').doc(user.uid).set({
      'unlockedLevel': unlockedLevel.index,
    }, SetOptions(merge: true));
  }

  Future<Difficulty> getUserProgress(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return Difficulty.values[data['unlockedLevel'] ?? 0];
    }
    return Difficulty.easy;
  }
}

// --- UI: LOGIN & REGISTER SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;

  void _submit() async {
    final authService = context.read<AuthService>();
    String result;

    if (_isLogin) {
      result = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      result = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (mounted && (result == "Signed In" || result == "Signed Up")) {
      Navigator.of(context).pop(); // Go back to the previous screen on success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF1D1E2C)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A4DE8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(_isLogin ? 'Login' : 'Register'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'Need an account? Register'
                        : 'Have an account? Login',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- UI: LANDING SCREEN ---
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: AuthActionButton(),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Word Quiz',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 15, color: Colors.black38),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Challenge your vocabulary.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const SizedBox(height: 60),
                        ElevatedButton(
                          onPressed: () =>
                              _navigateTo(context, const DifficultyScreen()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A4DE8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Play Quiz'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- UI: DIFFICULTY SCREEN ---
class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  void _onDifficultySelected(BuildContext context, Difficulty difficulty) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SetSelectionScreen(difficulty: difficulty),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select Difficulty'),
          actions: const [AuthActionButton()],
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DifficultyButton(
                    text: 'Easy',
                    color: Colors.green,
                    onTap: () =>
                        _onDifficultySelected(context, Difficulty.easy),
                  ),
                  const SizedBox(height: 20),
                  DifficultyButton(
                    text: 'Medium',
                    color: Colors.orange,
                    onTap: () =>
                        _onDifficultySelected(context, Difficulty.medium),
                  ),
                  const SizedBox(height: 20),
                  DifficultyButton(
                    text: 'Hard',
                    color: Colors.red,
                    onTap: () =>
                        _onDifficultySelected(context, Difficulty.hard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- UI: SET SELECTION SCREEN ---
class SetSelectionScreen extends StatelessWidget {
  final Difficulty difficulty;
  const SetSelectionScreen({super.key, required this.difficulty});

  void _onSetSelected(BuildContext context, int setIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuizScreen(difficulty: difficulty, setIndex: setIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sets = wordSets[difficulty]!;
    final user = context.watch<User?>();
    final bool isGuest = user == null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select a Set'),
          actions: const [AuthActionButton()],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1,
          ),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final bool isSetLocked =
                isGuest && index >= 2; // Sets 3, 4, 5 are locked for guests
            return Card(
              color: isSetLocked
                  ? const Color(0xFF2C2D4A).withOpacity(0.5)
                  : const Color(0xFF2C2D4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () {
                  if (isSetLocked) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } else {
                    _onSetSelected(context, index);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSetLocked)
                        const Icon(Icons.lock, color: Colors.white54, size: 40),
                      if (isSetLocked) const SizedBox(height: 8),
                      Text(
                        'Set ${index + 1}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isSetLocked ? Colors.white54 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- DATA MODELS & API ---
class QuizQuestion {
  final String word;
  final String correctDefinition;
  final List<String> options;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? audioUrl;

  QuizQuestion({
    required this.word,
    required this.correctDefinition,
    required this.options,
    required this.synonyms,
    required this.antonyms,
    this.audioUrl,
  });
}

class ApiService {
  Future<Map<String, dynamic>> fetchWordDetails(String word) async {
    final response = await http.get(
      Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body)[0];
      final meaning = data['meanings'][0];
      final definition =
          meaning['definitions'][0]['definition'] ?? 'No definition found.';
      final synonyms = List<String>.from(meaning['synonyms'] ?? []);
      final antonyms = List<String>.from(meaning['antonyms'] ?? []);

      String? audioUrl;
      if (data['phonetics'] != null) {
        for (var phonetic in data['phonetics']) {
          if (phonetic['audio'] != null && phonetic['audio'].isNotEmpty) {
            audioUrl = phonetic['audio'];
            break;
          }
        }
      }

      if (definition == 'No definition found.')
        throw Exception('No definition');
      return {
        'definition': definition,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'audioUrl': audioUrl,
      };
    }
    throw Exception('No definition for this word');
  }
}

// --- STATE MANAGEMENT ---
enum QuizState { loading, question, answered, finished }

class QuizProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late List<String> _currentWordSet;
  int _currentIndex = 0;
  QuizState _state = QuizState.loading;
  QuizQuestion? _currentQuestion;
  String? _selectedAnswer;
  String? _error;
  int _score = 0;

  QuizState get state => _state;
  QuizQuestion? get currentQuestion => _currentQuestion;
  String? get selectedAnswer => _selectedAnswer;
  bool get isCorrect => _selectedAnswer == _currentQuestion?.correctDefinition;
  String? get error => _error;
  int get score => _score;
  int get currentIndex => _currentIndex;

  void startQuiz(Difficulty difficulty, int setIndex) {
    _currentWordSet = List.from(wordSets[difficulty]![setIndex])
      ..shuffle(_random);
    _currentIndex = 0;
    _score = 0;
    _error = null;
    loadNewQuestion();
  }

  Future<void> loadNewQuestion() async {
    if (_currentIndex >= _currentWordSet.length) {
      _state = QuizState.finished;
      notifyListeners();
      return;
    }

    _state = QuizState.loading;
    _selectedAnswer = null;
    notifyListeners();

    try {
      final correctWord = _currentWordSet[_currentIndex];
      final wordDetails = await _apiService.fetchWordDetails(correctWord);
      final correctDefinition = wordDetails['definition'];

      List<String> distractorWords = List.from(_currentWordSet)
        ..remove(correctWord);
      distractorWords.shuffle(_random);
      List<String> options = [correctDefinition];

      for (int i = 0; i < 3 && i < distractorWords.length; i++) {
        try {
          final distractorDetails = await _apiService.fetchWordDetails(
            distractorWords[i],
          );
          options.add(distractorDetails['definition']);
        } catch (e) {
          print("Failed to fetch distractor definition, skipping.");
        }
      }

      options.shuffle(_random);

      _currentQuestion = QuizQuestion(
        word: correctWord,
        correctDefinition: correctDefinition,
        options: options,
        synonyms: wordDetails['synonyms'],
        antonyms: wordDetails['antonyms'],
        audioUrl: wordDetails['audioUrl'],
      );
      _state = QuizState.question;
    } catch (e) {
      _error = "Could not load question. Check connection.";
      _state = QuizState.question;
    }
    notifyListeners();
  }

  void submitAnswer(String answer) {
    if (_state == QuizState.question) {
      _selectedAnswer = answer;
      if (isCorrect) _score++;
      _state = QuizState.answered;
      notifyListeners();
    }
  }

  void nextQuestion() {
    _currentIndex++;
    loadNewQuestion();
  }

  Future<void> playPronunciation(String? url) async {
    if (url != null && url.isNotEmpty) {
      await _audioPlayer.play(UrlSource(url));
    }
  }
}

// --- UI: QUIZ SCREEN ---
class QuizScreen extends StatefulWidget {
  final Difficulty difficulty;
  final int setIndex;
  const QuizScreen({
    super.key,
    required this.difficulty,
    required this.setIndex,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().startQuiz(
        widget.difficulty,
        widget.setIndex,
      );
    });

    context.read<QuizProvider>().addListener(_onProviderStateChanged);
  }

  void _onProviderStateChanged() {
    if (!mounted) return;

    final provider = context.read<QuizProvider>();
    if (provider.state == QuizState.question) {
      _isNavigating = false;
      _animationController.forward(from: 0.0);
    } else if (provider.state == QuizState.finished && !_isNavigating) {
      _isNavigating = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            difficulty: widget.difficulty,
            score: provider.score,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    context.read<QuizProvider>().removeListener(_onProviderStateChanged);
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2D4A),
        title: const Text(
          'Are you sure?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to quit the quiz? Your progress will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Quit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final totalQuestions = wordSets[widget.difficulty]![widget.setIndex].length;
    final progress = provider.state == QuizState.loading
        ? provider.currentIndex / totalQuestions
        : (provider.currentIndex + 1) / totalQuestions;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Question ${provider.currentIndex + 1}/$totalQuestions',
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                tween: Tween<double>(
                  begin: 0,
                  end: progress.isNaN ? 0 : progress,
                ),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: const Color(0xFF6A4DE8).withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            actions: [
              const AuthActionButton(),
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Center(
                  child: Text(
                    'Score: ${provider.score}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildContent(context, provider),
    );
  }

  Widget _buildContent(BuildContext context, QuizProvider provider) {
    if (provider.state == QuizState.loading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (provider.error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => provider.loadNewQuestion(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    final question = provider.currentQuestion;
    if (question == null) {
      return const Center(
        key: ValueKey('empty'),
        child: Text("Starting quiz...", style: TextStyle(color: Colors.white)),
      );
    }

    return SingleChildScrollView(
      key: ValueKey(question.word),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Animated Question Card
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final angle = (_animationController.value * pi);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: _animationController.value <= 0.5
                    ? Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2D4A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF6A4DE8).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "What is the meaning of...",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: Card(
                          color: Colors.white,
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  question.word,
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D1E2C),
                                  ),
                                ),
                                if (question.audioUrl != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.volume_up,
                                      color: Color(0xFF1D1E2C),
                                    ),
                                    onPressed: () => provider.playPronunciation(
                                      question.audioUrl,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 20),
          ...List.generate(question.options.length, (index) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.5 + (0.1 * index),
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.5 + (0.1 * index), 1.0),
                ),
                child: OptionButton(
                  text: question.options[index],
                  onTap: () => provider.submitAnswer(question.options[index]),
                  isCorrect:
                      question.options[index] == question.correctDefinition,
                  isSelected:
                      question.options[index] == provider.selectedAnswer,
                  showResult: provider.state == QuizState.answered,
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          if (provider.state == QuizState.answered)
            FadeTransition(
              opacity: const AlwaysStoppedAnimation(1),
              child: Column(
                children: [
                  if (!provider.isCorrect) ExplanationCard(question: question),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => provider.nextQuestion(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 50,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Next Question'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- UI: RESULTS SCREEN ---
class ResultsScreen extends StatefulWidget {
  final Difficulty difficulty;
  final int score;
  const ResultsScreen({
    super.key,
    required this.difficulty,
    required this.score,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _scoreAnimation = IntTween(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _checkAndUnlockLevel();
    _controller.forward();
  }

  Future<void> _checkAndUnlockLevel() async {
    final user = context.read<User?>();
    if (user == null) return; // Don't save progress for guests

    const totalQuestions = 20; // Each set has 20 questions
    if (widget.score >= totalQuestions * 0.75) {
      final nextLevelIndex = widget.difficulty.index + 1;
      if (nextLevelIndex < Difficulty.values.length) {
        final nextLevel = Difficulty.values[nextLevelIndex];
        await DatabaseService().saveUserProgress(user, nextLevel);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const total = 20; // Each set has 20 questions
    final percentage = (widget.score / total * 100).toStringAsFixed(0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E2C), Color(0xFF2C2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.amber[300],
                  size: 120,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quiz Complete!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Score',
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, child) {
                  return Text(
                    '${_scoreAnimation.value} / $total',
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              Text(
                '($percentage%)',
                style: TextStyle(fontSize: 24, color: Colors.amber[300]),
              ),
              const SizedBox(height: 50),
              DifficultyButton(
                text: 'Play Another Set',
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const DifficultyScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              DifficultyButton(
                text: 'Main Menu',
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- UI WIDGETS ---
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({super.key, required this.question});
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2C2D4A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Correct Answer: ${question.word}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                if (question.audioUrl != null)
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white70),
                    onPressed: () => context
                        .read<QuizProvider>()
                        .playPronunciation(question.audioUrl),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"${question.correctDefinition}"',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            if (question.synonyms.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWordChipList('Synonyms', question.synonyms, Colors.green),
            ],
            if (question.antonyms.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWordChipList('Antonyms', question.antonyms, Colors.red),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWordChipList(String title, List<String> words, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue.shade300,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: words
              .map(
                (word) => Chip(
                  label: Text(word),
                  backgroundColor: color.withOpacity(0.2),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class OptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSelected, isCorrect, showResult;

  const OptionButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
  });

  Color _getBackgroundColor(BuildContext context) {
    if (!showResult) return Theme.of(context).primaryColor.withOpacity(0.2);
    if (isCorrect) return Colors.green.withOpacity(0.4);
    if (isSelected && !isCorrect) return Colors.red.withOpacity(0.4);
    return Theme.of(context).primaryColor.withOpacity(0.2);
  }

  Color _getBorderColor(BuildContext context) {
    if (!showResult) return Theme.of(context).primaryColor;
    if (isCorrect) return Colors.green;
    if (isSelected && !isCorrect) return Colors.red;
    return Theme.of(context).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: _getBorderColor(context), width: 2),
      ),
      child: InkWell(
        onTap: showResult ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              if (showResult)
                isCorrect
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : (isSelected
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class DifficultyButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  final bool isLocked;

  const DifficultyButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLocked ? null : onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isLocked ? Colors.grey.shade600 : color,
        disabledBackgroundColor: Colors.grey.shade600,
        minimumSize: const Size(double.infinity, 60),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLocked) const Icon(Icons.lock, size: 24),
          if (isLocked) const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: firebaseUser != null
          ? IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => context.read<AuthService>().signOut(),
            )
          : IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Login / Register',
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
    );
  }
}
*/
