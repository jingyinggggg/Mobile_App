import 'package:flutter/material.dart';

class LocalBuddyCustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LocalBuddyCustomBottomNavBar({
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
            return const IconThemeData(color: Color(0xFF749CB9));
          }
          return const IconThemeData(color: Colors.white);
        }),
      ),
      child: NavigationBar(
        onDestinationSelected: onTap,
        selectedIndex: currentIndex,
        backgroundColor: const Color(0xFF749CB9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore, size: 20),
            label: "Explore",
          ),
          NavigationDestination(
            icon: Icon(Icons.person, size: 20),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
