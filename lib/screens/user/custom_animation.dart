import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomAnimation extends StatefulWidget{

  const CustomAnimation({
    super.key,
  });

  @override
  State<CustomAnimation> createState() => _CustomAnimationState();
}

class _CustomAnimationState extends State<CustomAnimation> with TickerProviderStateMixin{
  //Animation controller for manage animation
  late AnimationController _animationController;
  //Animation for scaling the container
  late Animation<double> _scaleAnimation;
  //Animation for aligning the container
  late Animation<double> _alignAnimation;
  //Animation for changing the border radius
  late Animation<double> _borderRadiusAnimation;
  //Animation for scaling the close icon
  late Animation<double> _iconScaleAnimation;
  //Animation for rotating the close icon
  late Animation<double> _iconRotateAnimation;
  
  //For checking, if the menu is open or closed
  bool isOpen = false;

  @override
  void initState() {
    super.initState();

    //Inizialite the animationController with a duration
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400)
    );

    //Curveanimation to apply easing effect
    final curveAnimation = CurvedAnimation(parent: _animationController, curve: Curves.ease);
    //Define various animations using Tween and Curved animations
    _scaleAnimation = Tween(begin: 59.0, end: 200.0).animate(curveAnimation);
    _alignAnimation = Tween(begin: 0.0, end: -1.0).animate(curveAnimation);
    _borderRadiusAnimation = Tween(begin: 100.0, end: 15.0).animate(curveAnimation);
    _iconRotateAnimation = Tween(begin: 0.0, end: math.pi).animate(curveAnimation);
    _iconScaleAnimation = Tween(begin: 0.0, end: 30.0).animate(curveAnimation);
  }

  //Function to toggle the menu's open/close state
  void _toggleMenu(){
    setState(() {
      if(isOpen){
        _animationController.reverse();
      } else{
        _animationController.forward();
      }
      isOpen = !isOpen;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF467BA1),
      body: Center(
        child:Container(
          color: Color(0xFF467BA1),
          height: 235,
          width: 200,
          child: Stack(
            children: [
              _buildAnimatedContainer(),
              _buildMenuIcon()
            ],
          )
        )
      ),
    );
  }

  Widget _buildAnimatedContainer(){
    return AnimatedBuilder(
      animation: _animationController, 
      builder: (context, child){
        return Align(
          alignment: Alignment(_alignAnimation.value, _alignAnimation.value),
          child: Container(
            height: _scaleAnimation.value,
            width: _scaleAnimation.value,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                _borderRadiusAnimation.value,
              )
            ),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            MenuContent(index: 1, title:  'Translator', icon: Icons.g_translate_rounded, color: Color(0xFF467BA1), isOpen: isOpen),
            MenuContent(index: 2, title: 'Converter', icon: Icons.currency_exchange_rounded, color: Color(0xFF467BA1), isOpen: isOpen),
            MenuContent(index: 3, title: 'Nearest Money Changer', icon: Icons.attach_money_rounded, color: Color(0xFF467BA1), isOpen: isOpen)
          ],
        ),
      ),
    );
  }

  //Function for build the menu icon
  Widget _buildMenuIcon(){
    return AnimatedBuilder(
      animation: _animationController, 
      builder: (context, child){
        return Align(
          alignment: Alignment(_animationController.value, _animationController.value),
          child: InkWell(
            onTap: (){
              _toggleMenu();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _iconRotateAnimation.value,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: _iconScaleAnimation.value,
                  )
                ),

                if(_animationController.isDismissed)
                Icon(
                  Icons.menu,
                  size: 25,
                  color: Colors.black,
                )
              ],
            ),
          )
        );
      }
    );
  }
}

class MenuContent extends StatefulWidget{
  final int index;
  final String title;
  final IconData icon;
  final Color color;
  final isOpen;

  const MenuContent({
    super.key, 
    required this.index,
    required this.title, 
    required this.icon, 
    required this.color, 
    this.isOpen
  });

  @override
  State<MenuContent> createState() => _MenuContentState();
}

class _MenuContentState extends State<MenuContent> with SingleTickerProviderStateMixin{
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    if(widget.isOpen){
      Future.delayed(Duration(milliseconds: widget.index * 200),(){
        if(mounted)
          _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(MenuContent oldWidget){
    super.didUpdateWidget(oldWidget);
    if(mounted){
      if(widget.isOpen){
        Future.delayed(Duration(milliseconds: widget.index * 200),(){
          if(mounted)
            _controller.forward();
        }); 
      } else{
        _controller.reverse();
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller, 
      builder: (context, child){
        return Transform.scale(
          scale: _controller.value,
          child: Opacity(
            opacity: _controller.value,
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: (){},
                child: Container(
                  height: 50,
                  // width: 200,
                  // padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: widget.color,
                        )
                      ),
                      SizedBox(width: 5,),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black
                          ),
                        )
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

// import 'package:flutter/material.dart';
// import 'dart:math' as math;

// class CustomAnimation extends StatefulWidget {
//   final VoidCallback onTap;
//   final Function(int) onMenuItemSelected;
//   final bool isExpanded;

//   const CustomAnimation({
//     Key? key,
//     required this.onTap,
//     required this.onMenuItemSelected,
//     this.isExpanded = false,
//   }) : super(key: key);

//   @override
//   State<CustomAnimation> createState() => _CustomAnimationState();
// }

// class _CustomAnimationState extends State<CustomAnimation> with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _alignAnimation;
//   late Animation<double> _borderRadiusAnimation;
//   late Animation<double> _iconScaleAnimation;
//   late Animation<double> _iconRotateAnimation;
  
//   bool isOpen = false;

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 400),
//     );

//     final curveAnimation = CurvedAnimation(parent: _animationController, curve: Curves.ease);
//     _scaleAnimation = Tween(begin: 59.0, end: 200.0).animate(curveAnimation);
//     _alignAnimation = Tween(begin: 0.0, end: -1.0).animate(curveAnimation);
//     _borderRadiusAnimation = Tween(begin: 100.0, end: 15.0).animate(curveAnimation);
//     _iconRotateAnimation = Tween(begin: 0.0, end: math.pi).animate(curveAnimation);
//     _iconScaleAnimation = Tween(begin: 0.0, end: 30.0).animate(curveAnimation);
//   }

//   void _toggleMenu() {
//     setState(() {
//       if (isOpen) {
//         _animationController.reverse();
//       } else {
//         _animationController.forward();
//       }
//       isOpen = !isOpen;
//     });
//     widget.onTap();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         _buildAnimatedContainer(),
//         _buildMenuIcon(),
//       ],
//     );
//   }

//   Widget _buildAnimatedContainer() {
//     return AnimatedBuilder(
//       animation: _animationController, 
//       builder: (context, child) {
//         return Align(
//           alignment: Alignment(_alignAnimation.value, _alignAnimation.value),
//           child: Container(
//             height: _scaleAnimation.value,
//             width: _scaleAnimation.value,
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
//             ),
//             child: child,
//           ),
//         );
//       },
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             MenuContent(
//               index: 1,
//               title: 'Translator',
//               icon: Icons.g_translate_rounded,
//               color: Color(0xFF467BA1),
//               isOpen: isOpen,
//               onTap: () => widget.onMenuItemSelected(1),
//             ),
//             MenuContent(
//               index: 2,
//               title: 'Converter',
//               icon: Icons.currency_exchange_rounded,
//               color: Color(0xFF467BA1),
//               isOpen: isOpen,
//               onTap: () => widget.onMenuItemSelected(2),
//             ),
//             MenuContent(
//               index: 3,
//               title: 'Nearest Money Changer',
//               icon: Icons.attach_money_rounded,
//               color: Color(0xFF467BA1),
//               isOpen: isOpen,
//               onTap: () => widget.onMenuItemSelected(3),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuIcon() {
//     return AnimatedBuilder(
//       animation: _animationController, 
//       builder: (context, child) {
//         return Align(
//           alignment: Alignment(_alignAnimation.value, _alignAnimation.value),
//           child: InkWell(
//             onTap: _toggleMenu,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 Transform.rotate(
//                   angle: _iconRotateAnimation.value,
//                   child: Icon(
//                     Icons.close_rounded,
//                     color: Colors.white,
//                     size: 25,
//                   ),
//                 ),
//                 if (_animationController.isDismissed)
//                   Icon(
//                     Icons.menu,
//                     size: 25,
//                     color: Colors.white,
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class MenuContent extends StatefulWidget {
//   final int index;
//   final String title;
//   final IconData icon;
//   final Color color;
//   final bool isOpen;
//   final VoidCallback onTap;

//   const MenuContent({
//     Key? key, 
//     required this.index,
//     required this.title, 
//     required this.icon, 
//     required this.color,
//     required this.onTap,
//     this.isOpen = false,
//   }) : super(key: key);

//   @override
//   State<MenuContent> createState() => _MenuContentState();
// }

// class _MenuContentState extends State<MenuContent> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 400),
//     );
//     if (widget.isOpen) {
//       Future.delayed(Duration(milliseconds: widget.index * 200), () {
//         if (mounted) _controller.forward();
//       });
//     }
//   }

//   @override
//   void didUpdateWidget(MenuContent oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (mounted) {
//       if (widget.isOpen) {
//         Future.delayed(Duration(milliseconds: widget.index * 200), () {
//           if (mounted) _controller.forward();
//         }); 
//       } else {
//         _controller.reverse();
//       }
//     } 
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller, 
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _controller.value,
//           child: Opacity(
//             opacity: _controller.value,
//             child: Material(
//               color: Colors.white,
//               child: InkWell(
//                 onTap: widget.onTap,
//                 child: Container(
//                   height: 45,
//                   width: 200,
//                   padding: EdgeInsets.all(8),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Icon(
//                           widget.icon,
//                           size: 20,
//                           color: widget.color,
//                         ),
//                       ),
//                       SizedBox(width: 5),
//                       Expanded(
//                         child: Text(
//                           widget.title,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
