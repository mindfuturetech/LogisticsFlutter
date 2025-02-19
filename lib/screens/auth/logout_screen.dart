import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'login_screen.dart';


class LogoutDialog extends StatefulWidget {
  @override
  _LogoutDialogState createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
          Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextButton(
            onPressed: _isLoading ? null : () => _handleLogout(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              disabledForegroundColor: Colors.white.withOpacity(0.5),
            ),
            child: _isLoading
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Text('Logging out...')
              ],
            )
                : Text('Yes, Logout'),
          ),
        ),
      ],
    );
  }

  // Future<void> _handleLogout(BuildContext context) async {
  //   try {
  //     setState(() => _isLoading = true);
  //     await context.read<AuthProvider>().logout();
  //     // Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login screen
  //
  //     // Clear navigation history and go to Login Screen
  //     Navigator.of(context).pushAndRemoveUntil(
  //       MaterialPageRoute(builder: (context) => LoginScreen()),
  //           (Route<dynamic> route) => false, // This removes all previous routes
  //     );
  //
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Logout failed: ${e.toString()}')),
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }

  Future<void> _handleLogout(BuildContext context) async {
    context.read<AuthProvider>().logout(context);
    }
  }

