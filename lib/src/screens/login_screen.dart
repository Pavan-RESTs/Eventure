import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/functions/cloud_helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax/iconsax.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await ICloudHelperFunctions.loginWithEmail(
          _emailController.text.trim(), _passwordController.text.trim());
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = IDeviceUtils.getScreenWidth(context);
    final screenHeight = IDeviceUtils.getScreenHeight(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(children: [
          Opacity(
            opacity: _isLoading ? 0.3 : 1,
            child: SafeArea(
              child: Container(
                width: screenWidth,
                height: screenHeight * 0.9,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: screenWidth * 0.35,
                      height: screenWidth * 0.35,
                      decoration: BoxDecoration(
                        color: IColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.event,
                          size: screenWidth * 0.18,
                          color: IColors.primary,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Login Title
                    Text(
                      'Welcome to Eventure',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    Text(
                      'Login to your account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: IColors.darkGrey,
                          ),
                    ),

                    SizedBox(height: screenHeight * 0.06),

                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              } else if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: screenHeight * 0.025),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Iconsax.eye
                                      : Iconsax.eye_slash,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              } else if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          SizedBox(height: screenHeight * 0.035),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.065,
                            child: ElevatedButton(
                              onPressed: _login,
                              child: const Text('Login'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: SpinKitWaveSpinner(
                    size: 90,
                    waveColor: Colors.lightBlueAccent,
                    color: IColors.primary,
                    duration: Duration(seconds: 1),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
