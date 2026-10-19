import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assets_app/core/utils/api_service.dart';
import 'package:assets_app/features/dashboard/presentation/screens/dashboard_screen.dart';

final loginLoadingProvider = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes for automatically opening the keyboard
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String? _errorMessage;

  // ============================================================
  // LOGIN
  // ============================================================
  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide keyboard while login request is running
    FocusScope.of(context).unfocus();

    ref.read(loginLoadingProvider.notifier).state = true;

    try {
      final apiService = ref.read(apiServiceProvider);

      final response = await apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final data = response.data;

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true &&
          await apiService.isLoggedIn()) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        ref.read(loginLoadingProvider.notifier).state = false;
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loginLoadingProvider);

    return Scaffold(
      // Allows the screen to resize when keyboard opens
      resizeToAvoidBottomInset: true,

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade500],
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            // Extra bottom padding when keyboard is displayed
            padding: const EdgeInsets.all(24.0),

            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

            child: Card(
              elevation: 8,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              child: Padding(
                padding: const EdgeInsets.all(24.0),

                child: Form(
                  key: _formKey,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      // ==================================================
                      // APP ICON
                      // ==================================================
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // TITLE
                      // ==================================================
                      Text(
                        'Asset Management',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                      ),

                      const SizedBox(height: 8),

                      const Text('Sign in to continue'),

                      const SizedBox(height: 32),

                      // ==================================================
                      // ERROR MESSAGE
                      // ==================================================
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.red.shade50,

                            borderRadius: BorderRadius.circular(8),

                            border: Border.all(color: Colors.red.shade200),
                          ),

                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 18,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  _errorMessage!,

                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],

                      // ==================================================
                      // EMAIL
                      // ==================================================
                      TextFormField(
                        controller: _emailController,

                        // Focus node
                        focusNode: _emailFocusNode,

                        // Email keyboard
                        keyboardType: TextInputType.emailAddress,

                        // Show Next button on keyboard
                        textInputAction: TextInputAction.next,

                        // Automatically focus when tapped
                        onTap: () {
                          _emailFocusNode.requestFocus();
                        },

                        // Move to password field
                        onFieldSubmitted: (_) {
                          _passwordFocusNode.requestFocus();
                        },

                        decoration: InputDecoration(
                          labelText: 'Email',

                          prefixIcon: const Icon(Icons.email_outlined),

                          border: const OutlineInputBorder(),

                          enabledBorder: _errorMessage != null
                              ? OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red.shade300,
                                  ),
                                )
                              : null,

                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }

                          return null;
                        },

                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // PASSWORD
                      // ==================================================
                      TextFormField(
                        controller: _passwordController,

                        // Focus node
                        focusNode: _passwordFocusNode,

                        // Password field
                        obscureText: true,

                        // Done button on keyboard
                        textInputAction: TextInputAction.done,

                        // Automatically focus when tapped
                        onTap: () {
                          _passwordFocusNode.requestFocus();
                        },

                        // Login when keyboard Done is pressed
                        onFieldSubmitted: (_) {
                          if (!isLoading) {
                            _handleLogin();
                          }
                        },

                        decoration: InputDecoration(
                          labelText: 'Password',

                          prefixIcon: const Icon(Icons.lock_outline),

                          border: const OutlineInputBorder(),

                          enabledBorder: _errorMessage != null
                              ? OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red.shade300,
                                  ),
                                )
                              : null,

                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }

                          return null;
                        },

                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 32),

                      // ==================================================
                      // LOGIN BUTTON
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 50,

                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,

                            foregroundColor: Colors.white,

                            disabledBackgroundColor: Colors.blue.shade300,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,

                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'LOGIN',

                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
