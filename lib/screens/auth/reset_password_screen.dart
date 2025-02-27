
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _retypePasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureRetypePassword = true;

  // Future<void> _resetPassword() async {
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }
  //
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = '';
  //   });
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://shreelalchand.com/logistics/reset-password'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'username': _usernameController.text,
  //         'currentPassword': _currentPasswordController.text,
  //         'newPassword': _newPasswordController.text,
  //         'retypePassword': _retypePasswordController.text,
  //       }),
  //     );
  //
  //     final data = jsonDecode(response.body);
  //
  //     if (response.statusCode == 200) {
  //       // Password reset successful
  //       if (!mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(data['message']),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //       Navigator.pop(context); // Close the reset password screen
  //     } else {
  //       setState(() {
  //         _errorMessage = data['message'] ?? 'Failed to reset password';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'Network error occurred. Please try again.';
  //     });
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://shreelalchand.com/logistics/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
          'retypePassword': _retypePasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Password reset successful
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close the reset password screen
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to reset password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Add this function to validate password complexity
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for uppercase letters
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letters
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for numbers
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null; // Password is valid
  }

// Add this function to validate password matching
  String? validatePasswordMatch(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please retype your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null; // Passwords match
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  helperText: 'Must be at least 8 characters with uppercase, lowercase & numbers with symbol',
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }

                    // Single RegExp to check all conditions:
                    // - At least 8 characters
                    // - At least one uppercase letter
                    // - At least one lowercase letter
                    // - At least one number
                    // - At least one special character
                    final passwordRegex = RegExp(
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()+_\-=\[\]{}|;:"\\,.<>/?])' +
                            r'[A-Za-z\d!@#$%^&*()+_\-=\[\]{}|;:"\\,.<>/?]{8,}$');

                    if (!passwordRegex.hasMatch(value)) {
                      return 'Password must be at least 8 characters long and include at least one uppercase letter, one lowercase letter, one number, and one special character.';
                    }

                    return null; // Return null for valid input
                  }
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _retypePasswordController,
                obscureText: _obscureRetypePassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRetypePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureRetypePassword = !_obscureRetypePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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