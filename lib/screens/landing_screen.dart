import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth_screens/login_screen.dart';

class LandingScreen extends StatefulWidget {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  OverlayEntry? _infoOverlay;

  void _showInfoBubble(BuildContext context) {
    final RenderBox iconBox = context.findRenderObject() as RenderBox;
    final Offset iconPosition = iconBox.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;

    _infoOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                _removeInfoBubble();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Positioned(
              top: screenSize.height * 0.65,
              left: iconPosition.dx + 30,
              child: Material(
                color: Colors.white24,
                child: Container(
                  padding: EdgeInsets.all(8),
                  width: screenSize.width * 0.75,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Information",
                        style: TextStyle(
                          fontFamily: 'Sarala',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "S.mart helps you shop smarter, faster, and easier. ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_infoOverlay!);
  }

  void _removeInfoBubble() {
    _infoOverlay?.remove();
    _infoOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double logoHeight = screenSize.height * 0.2;
    final double buttonWidth = screenSize.width * 0.45;
    final double bgHeight = screenSize.height * 0.75; // Similar to original 651px height
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image with original dimensions
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: CurveClipper(),
              child: Image.asset(
                'assets/bg.png',
                height: bgHeight,
                width: screenSize.width,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Content container
          SafeArea(
            child: Column(
              children: [
                // Logo section
                SizedBox(height: screenSize.height * 0.08),
                Image.asset(
                  'assets/logo-light.png',
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),
                
                // Spacer to push content to bottom
                Spacer(),
                
                // Info icon
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        _showInfoBubble(context);
                      },
                      child: Icon(
                        Icons.info,
                        size: 48,
                        color: Color(0xFF0CA8E1),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 40),
                
                // Text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
                  child: Text(
                    "Shop smarter, faster, and easier with S.mart\n"
                    "your ultimate shopping companion.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Sarala',
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width * 0.04,
                      height: 1.6,
                      color: Colors.black,
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Button
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: screenSize.height * 0.02
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'Start Shopping',
                      style: TextStyle(
                        fontFamily: 'Sarala',
                        fontWeight: FontWeight.bold,
                        fontSize: screenSize.width * 0.04,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.06),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - (size.height * 0.3)); // Proportional curve
    path.quadraticBezierTo(
        size.width / 200, size.height + 40, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
