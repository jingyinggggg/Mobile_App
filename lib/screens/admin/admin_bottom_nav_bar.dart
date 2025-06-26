import 'package:flutter/material.dart';

class AdminCustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdminCustomBottomNavBar({
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
              color: Color(0xFFF50057),
              fontFamily: "inika",
              fontSize: 12,
            );
          }
          return const TextStyle(color: Color(0XFFBDBDBD), fontFamily: "inika",fontSize: 12,);
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFF50057));
          }
          return const IconThemeData(color: Color(0XFFBDBDBD));
        }),
      ),
      child: NavigationBar(
        onDestinationSelected: onTap,
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: ImageIcon(AssetImage("images/home.png"), size: 19),
            label: "Home",
          ),
          NavigationDestination(
            icon: ImageIcon(AssetImage("images/chat.png"), size: 19),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: ImageIcon(AssetImage("images/account.png"), size: 19),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
