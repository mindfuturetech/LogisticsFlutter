import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//new man
class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? profile = "Loading..."; // Default value
  String? username = "Loading..."; // Default value

  static final Map<String, List<String>> profileRestrictions = {
    'loadingManager': ['/freight','/vehicle','/vendor','/reports','/generate-bill', '/business', '/transaction'],
    'unloadingManager': ['/business', '/freight', '/vehicle', '/vendor', '/transaction', '/generate-bill'],
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profile = prefs.getString('profile') ?? "No profile available";
      username = prefs.getString('_username') ;
    });
  }

  bool isRestricted(String route) {
    return profile != null &&
        profileRestrictions.containsKey(profile) &&
        profileRestrictions[profile]!.contains(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
           DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 34),
                ),
                // Text(
                //   "Profile: $profile",
                //   style: TextStyle(fontSize: 18,color: Colors.white),
                // ),
                // Text(
                //   "User Name: $username",
                //   style: TextStyle(fontSize: 18,color: Colors.white),
                // )
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Text(
                    //   "Profile: ${profile ?? 'No profile'}",
                    //   style: TextStyle(fontSize: 18, color: Colors.white),
                    // ),
                      // Add some spacing between the two texts
                    Text(
                      "Hello, ${username ?? 'Guest'}",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ],
                ),

              ],
            ),
          ),
          _buildDrawerItem(context, Icons.home, 'Upload Truck Details', '/home'),
          _buildDrawerItem(context, Icons.calendar_month, "Today's List", '/todaylist'),
          _buildDrawerItem(context, Icons.local_shipping, 'Freight Master', '/freight'),
          _buildDrawerItem(context, Icons.directions_car, 'Vehicle Master', '/vehicle'),
          _buildDrawerItem(context, Icons.man, 'Vendor Master', '/vendor'),
          _buildDrawerItem(context, Icons.book, 'Reports', '/reports'),
          _buildDrawerItem(context, Icons.money_outlined, 'Billing', '/generate-bill'),
          _buildDrawerItem(context, Icons.report, 'Transaction', '/transaction'),
          _buildDrawerItem(context, Icons.add_shopping_cart_sharp, 'Business', '/business'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route) {
    if (isRestricted(route)) return const SizedBox.shrink();

    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}

// class CustomDrawer extends StatelessWidget {
//   final String? profile; // User's profile role
//
//   const CustomDrawer({super.key,this.profile});
//
//   // Centralized restrictions
//   static final Map<String, List<String>> profileRestrictions = {
//     'loadingManager': ['/freight','/vehicle','/vendor','/reports','/generate-bill', '/business', '/transactions'],
//     'unloadingManager': ['/business', '/freight', '/vehicle', '/vendor', '/transactions', '/generate-bill'],
//     // 'accountant': ['/vendor', '/vehicle'],
//   };
//
//   // Function to check if a route is restricted
//   bool isRestricted(String route) {
//     return profile != null &&
//         profileRestrictions.containsKey(profile) &&
//         profileRestrictions[profile]!.contains(route);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           const DrawerHeader(
//             decoration: BoxDecoration(color: Colors.black),
//             child: Text(
//               'Menu',
//               style: TextStyle(color: Colors.white, fontSize: 24),
//             ),
//           ),
//           _buildDrawerItem(context, Icons.home, 'Upload Truck Details', '/home'),
//           _buildDrawerItem(context, Icons.calendar_month, "Today's List", '/todaylist'),
//           _buildDrawerItem(context, Icons.local_shipping, 'Freight Master', '/freight'),
//           _buildDrawerItem(context, Icons.directions_car, 'Vehicle Master', '/vehicle'),
//           _buildDrawerItem(context, Icons.man, 'Vendor Master', '/vendor'),
//           _buildDrawerItem(context, Icons.book, 'Reports', '/reports'),
//           _buildDrawerItem(context, Icons.money_outlined, 'Billing', '/generate-bill'),
//           _buildDrawerItem(context, Icons.report, 'Transaction', '/transaction'),
//           _buildDrawerItem(context, Icons.add_shopping_cart_sharp, 'Business', '/business'),
//
//         ],
//       ),
//     );
//   }
//
//   // Helper function to build list items dynamically
//   Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route) {
//     if (isRestricted(route)) return SizedBox.shrink(); // Hide if restricted
//
//     return ListTile(
//       leading: Icon(icon, size: 30),
//       title: Text(title),
//       onTap: () {
//         Navigator.pop(context);
//         Navigator.pushNamed(context, route);
//       },
//     );
//   }
// }

  // @override
  // Widget build(BuildContext context) {
  //   return Drawer(
  //     child: ListView(
  //       padding: EdgeInsets.zero,
  //       children: [
  //         const DrawerHeader(
  //           decoration: BoxDecoration(color: Colors.black),
  //           child: Text(
  //             'Menu',
  //             style: TextStyle(color: Colors.white, fontSize: 24),
  //           ),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.upload_file),
  //           title: const Text('Upload Truck Details'),
  //           onTap: () => _navigateToRoute(context, '/'),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.local_shipping),
  //           title: const Text('Freight Master'),
  //           onTap: () => _navigateToRoute(context, '/freight'),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.directions_car),
  //           title: const Text('Vehicle Master'),
  //           onTap: () => _navigateToRoute(context, '/vehicle'),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.person),
  //           title: const Text('Vendor Master'),
  //           onTap: () => _navigateToRoute(context, '/vendor'),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.summarize),
  //           title: const Text('Reports'),
  //           onTap: () => _navigateToRoute(context, '/reports'),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.receipt),
  //           title: const Text('Billing'),
  //           onTap: () => _navigateToRoute(context, '/generate-bill'),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.compare_arrows),
  //           title: const Text('Transaction'),
  //           onTap: () => _navigateToRoute(context, '/transaction'),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.account_balance_wallet),
  //           title: const Text('Business Reports'),
  //           onTap: () => _navigateToRoute(context, '/business'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // void _navigateToRoute(BuildContext context, String route) {
  //   Navigator.pop(context); // Close the drawer first
  //   if (ModalRoute.of(context)?.settings.name != route) {
  //     Navigator.pushReplacementNamed(context, route).then((value) {
  //       // Add error handling
  //       if (value == null) {
  //         print('Navigation to $route failed');
  //       }
  //     }).catchError((error) {
  //       print('Error navigating to $route: $error');
  //       // Show error dialog if needed
  //       showDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: const Text('Navigation Error'),
  //           content: Text('Failed to navigate to $route'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         ),
  //       );
  //     });
  //   }
  // }


  //new code here
  // @override
  // Widget build(BuildContext context) {
  //   return Drawer(
  //     child: ListView(
  //       padding: EdgeInsets.zero,
  //       children: [
  //         Container(
  //           height: 150,
  //           child: const DrawerHeader(
  //             decoration: BoxDecoration(color: Colors.black),
  //             child: Text(
  //               'Menu',
  //               style: TextStyle(color: Colors.white, fontSize: 24),
  //             ),
  //           ),
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.home,size: 30),
  //           title: const Text('Upload Truck Details'),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/home');
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.calendar_month),
  //           title: const Text("Today's List"),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/todaylist');
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.local_shipping,size: 30),
  //           title: const Text('Freight Master'),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/freight');
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.directions_car,size: 30),
  //           title: const Text('Vehicle Master'),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/vehicle');
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.man,size: 30),
  //           title: const Text('Vendor Master'),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/vendor');
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.book,size: 30),
  //           title: const Text('Reports'),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/reports');
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.money_outlined,size: 30),
  //           title: const Text('Billing'),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/generate-bill');
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.report,size: 30),
  //           title: const Text('Transaction'),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/transaction');
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.add_shopping_cart_sharp,size: 30),
  //           title: const Text('Business'),
  //           onTap: () {
  //             Navigator.pop(context);
  //             Navigator.pushNamed(context, '/business');
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }
// }