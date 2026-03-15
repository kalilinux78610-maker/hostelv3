import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_screen.dart';
import 'services/push_notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  final bool _isPasswordVisible = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
    _loadUserCredentials();
  }

  Future<void> _loadUserCredentials() async {
    // Intentionally left empty to remove 'Remember Me'
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter your enrollment email to reset password',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() => _emailError = 'Enrollment is required');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save/Clear Credentials based on Remember Me
      // "Remember Me" logic removed based on user request

      // Save FCM Token
      try {
        final token = await PushNotificationService().getFcmToken();
        if (token != null && userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint("Error saving FCM token: $e");
      }

      // navigation handled by AuthWrapper
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'user-not-found' || e.code == 'invalid-email') {
            _emailError = 'Invalid enrollment ID';
          } else if (e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            _passwordError = 'Incorrect password';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_getErrorMessage(e)),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final String email = userCredential.user?.email?.toLowerCase() ?? "";

      // Check for user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Auto-claim if in imports
        final importDoc = await FirebaseFirestore.instance
            .collection('student_imports')
            .doc(email)
            .get();

        if (importDoc.exists) {
          final data = importDoc.data()!;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'uid': userCredential.user!.uid,
                'email': email,
                'name': data['name'],
                'role': 'student',
                'assignedHostel': data['assignedHostel'],
                'hostel': data['hostel'],
                'room': data['room'],
                'branch': data['branch'],
                'year': data['year'],
                'createdAt': FieldValue.serverTimestamp(),
                'isVerified': true,
              });
        } else {
          // Access Denied
          await _auth.signOut();
          await googleSignIn.signOut();
          if (mounted) {
            _showErrorDialog(
              "Access Denied",
              "You are not registered in any Hostel. Please contact your Rector.",
            );
          }
          return;
        }
      }

      // Save FCM Token
      try {
        final token = await PushNotificationService().getFcmToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({'fcmToken': token});
        }
      } catch (e) {
        debugPrint("Error saving FCM token: $e");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Google Sign-In failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'Login failed. ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Top Section with Header & Logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipPath(
                          clipper: HeaderClipper(),
                          child: Container(
                            height: 220, // Reduced height
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/building.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Logo moved to top
                        Positioned(
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.school,
                                      size: 40,
                                      color: Color(0xFF002244),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Main Content
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF002244),
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Sign in to continue",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Card(
                                elevation: 4,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          hintText: 'Enter Enrollment',
                                          prefixIcon: const Icon(
                                            Icons.badge_outlined,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 14,
                                                horizontal: 16,
                                              ),
                                          errorText: _emailError,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        decoration: InputDecoration(
                                          hintText: 'Enter Password',
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 14,
                                                horizontal: 16,
                                              ),
                                          errorText: _passwordError,
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _resetPassword,
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          child: const Text(
                                            "Forgot Password?",
                                            style: TextStyle(
                                              color: Color(0xFF002244),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // "Remember Me" feature removed from here
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: _isLoading
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : ElevatedButton(
                                                onPressed: _login,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF002244,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: const Text(
                                                  'Login',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Google Sign-In Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: OutlinedButton.icon(
                                          onPressed: _isLoading
                                              ? null
                                              : _signInWithGoogle,
                                          icon: Image.network(
                                            'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                                            height: 20,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Icon(Icons.account_circle),
                                          ),
                                          label: const Text(
                                            "Sign in with Gmail",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            side: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Footer Section
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "New Student? ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Verify Enrollment",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002244),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "v1.0.0 • RNGPIT Hostel",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var controlPoint = Offset(size.width / 2, size.height);
    var endPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
