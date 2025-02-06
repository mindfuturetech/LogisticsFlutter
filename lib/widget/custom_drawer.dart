import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

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
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 150,
            child: const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home,size: 30),
            title: const Text('Upload Truck Details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text("Today's List"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/todaylist');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month,size: 30),
            title: const Text("Today's List"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/todaylist');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping,size: 30),
            title: const Text('Freight Master'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/freight');
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car,size: 30),
            title: const Text('Vehicle Master'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/vehicle');
            },
          ),
          ListTile(
            leading: const Icon(Icons.man,size: 30),
            title: const Text('Vendor Master'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/vendor');
            },
          ),
          ListTile(
            leading: const Icon(Icons.book,size: 30),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.money_outlined,size: 30),
            title: const Text('Billing'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/generate-bill');
            },
          ),
          ListTile(
            leading: const Icon(Icons.report,size: 30),
            title: const Text('Transaction'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/transaction');
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_shopping_cart_sharp,size: 30),
            title: const Text('Business'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/business');
            },
          ),
        ],
      ),
    );
  }

}