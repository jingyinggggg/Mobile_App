import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'inika',
              fontSize: 12,
            );
          }
          return const TextStyle(color: Colors.white, fontFamily: 'inika',fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFE57373));
          }
          return const IconThemeData(color: Colors.white);
        }),
      ),
      child: NavigationBar(
        onDestinationSelected: onTap,
        selectedIndex: currentIndex,
        backgroundColor: const Color(0xFFE57373),
        destinations: const [
          NavigationDestination(
            icon: ImageIcon(AssetImage("images/home.png"), size: 20),
            label: "Home",
          ),
          NavigationDestination(
            icon: ImageIcon(AssetImage("images/map.png"), size: 20),
            label: 'Itinerary',
          ),
          NavigationDestination(
            icon: ImageIcon(AssetImage("images/chat.png"), size: 20),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: ImageIcon(AssetImage("images/booking.png"), size: 20),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: ImageIcon(AssetImage("images/account.png"), size: 20),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
