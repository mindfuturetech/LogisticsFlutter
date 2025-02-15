import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logistics/config/model/truck_details_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/auth/notification_page.dart';
import '../../config/services/notification_service.dart';
import '../config/services/auth_service.dart';
import '../config/services/search_service.dart';

// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;
//
//   const CustomAppBar({super.key, required this.scaffoldKey});
//
//   @override
//   Size get preferredSize => Size.fromHeight(100);
//
//   // @override
//   // Widget build(BuildContext context) {
//   //   return PreferredSize(
//   //     preferredSize: Size.fromHeight(60),
//   //     child: Container(
//   //       color: Colors.black,
//   //       child: SafeArea(
//   //         child: Padding(
//   //           padding: EdgeInsets.symmetric(horizontal: 16),
//   //           child: Row(
//   //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //             children: [
//   //               IconButton(
//   //                 icon: Icon(Icons.menu, color: Colors.white),
//   //                 onPressed: () => scaffoldKey.currentState?.openDrawer(),
//   //               ),
//   //               // Padding(
//   //               //   padding: EdgeInsets.only(right: 16),
//   //               //   child: Image.asset(
//   //               //     'assets/logo.png',
//   //               //     height: 40,
//   //               //   ),
//   //               // ),
//   //               IconButton(
//   //                   onPressed: (){},
//   //                   icon: Icon(
//   //                       Icons.notifications,
//   //                     size: 250,
//   //                     color: Colors.yellow,
//   //                   )
//   //               )
//   //             ],
//   //           ),
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }
//
//   // new code
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black,
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // Toggle Button
//               IconButton(
//                 icon: const Icon(Icons.menu, color: Colors.white, size: 30),
//                 onPressed: () {
//                   scaffoldKey.currentState?.openDrawer();
//                 },
//               ),
//
//               // Search Bar
//               Expanded(
//                 child: Container(
//                   height: 40,
//                   width: 50,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: 'Truck Id',
//                       hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
//                       border: InputBorder.none,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       isDense: true,
//                       prefixIcon: Icon(
//                         Icons.search,
//                         color: Colors.grey[600],
//                         size: 30,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Notification Button
//               IconButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const NotificationPage(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(
//                   Icons.notifications_active,
//                   size: 30,
//                   color: Colors.yellow,
//                 ),
//               ),
//
//               // Logout Button
//               IconButton(
//                 onPressed: () {
//                   // Handle logout logic
//                 },
//                 icon: const Icon(
//                   Icons.logout,
//                   size: 30,
//                   color: Colors.red,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//

//api call
// class ApiSearchService {
//
//   Future<TripDetails?> searchUserById(String id) async {
//     print("Searching for Trip ID: $id");
//     try {
//       final response = await http.get(
//         Uri.parse('http://10.0.2.2:5000/logistics/api/trip/$id'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       print("Response status code: ${response.statusCode}");
//       print("Response body: ${response.body}");
//
//       if (response.statusCode == 200 && response.body.isNotEmpty) {
//         final Map<String, dynamic> decodedData = json.decode(response.body);
//         final Map<String, dynamic> tripData = decodedData["TripData"];
//         return TripDetails.fromJson(tripData);
//       }
//       return null;
//     } catch (e) {
//       throw Exception('Failed to search user: $e');
//     }
//   }
// }

class CustomAppBar extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Function(TripDetails?) onTruckFound;
  final String? profile;  // Add profile parameter

  const CustomAppBar({
    super.key,
    required this.scaffoldKey,
    required this.onTruckFound,
    this.profile,  // Add to constructor
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final TextEditingController _searchController = TextEditingController();
  final apiService = ApiSearchService();
  bool _isLoading = false;
  String? profile;  // Add profile variable

  @override
  void initState() {
    super.initState();
    // Initialize profile from widget
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profile = prefs.getString('profile');
    });
  }

  Future<void> _searchTrip(String id) async {
    if (id.isEmpty) return;

    setState(() => _isLoading = true);
    try {

      final TripDetails? truck = await apiService.searchUserById(id);
      widget.onTruckFound(truck);
      if (truck == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Truck not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching truck: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('CustomAppBar - Received profile: $profile');
    print('CustomAppBar - Is profile accountant?: ${profile?.toLowerCase() == 'accountant'}');
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Toggle Button
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                onPressed: () {
                  widget.scaffoldKey.currentState?.openDrawer();
                },
              ),

              // Search Bar
              // Expanded(
              //   child: Container(
              //     height: 40,
              //     width: 50,
              //     decoration: BoxDecoration(
              //       color: Colors.grey[100],
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //     child: TextField(
              //       controller: _searchController,
              //       onSubmitted: _searchTrip,
              //       decoration: InputDecoration(
              //         hintText: 'Trip Id',
              //         hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              //         border: InputBorder.none,
              //         contentPadding: const EdgeInsets.symmetric(
              //           horizontal: 16,
              //           vertical: 8,
              //         ),
              //         isDense: true,
              //         prefixIcon: _isLoading
              //             ? SizedBox(
              //           width: 20,
              //           height: 20,
              //           child: Padding(
              //             padding: const EdgeInsets.all(8.0),
              //             child: CircularProgressIndicator(
              //               strokeWidth: 2,
              //               color: Colors.grey[600],
              //             ),
              //           ),
              //         )
              //             : Icon(
              //           Icons.search,
              //           color: Colors.grey[600],
              //           size: 30,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              Expanded(
                child: Container(
                  height: 40,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Trip Id',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      isDense: true,
                      suffixIcon: _isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                          : IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 30,
                        ),
                        onPressed: () => _searchTrip(_searchController.text),
                      ),
                    ),
                  ),
                ),
              ),

              // Notification Button
              if (profile?.toLowerCase() != 'loadingmanager')
                IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_active,
                  size: 30,
                  color: Colors.yellow,
                ),
              ),

              IconButton(
                onPressed: () async {
                  // Show confirmation dialog
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Yes, Logout',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  // If user confirmed logout
                  if (confirm == true) {
                    try {
                      final authService = AuthService();
                      await authService.logout();

                      // Clear authentication state
                      await AuthService.setAuthToken(false);

                      // Navigate to login screen
                      // Note: Replace '/login' with your actual login route
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    } catch (e) {
                      // Show error message if logout fails
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Logout failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(
                  Icons.logout,
                  size: 30,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

