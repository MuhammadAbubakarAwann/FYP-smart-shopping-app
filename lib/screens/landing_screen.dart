import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  OverlayEntry? _infoOverlay;

  void _showInfoBubble(BuildContext context) {
    final RenderBox iconBox = context.findRenderObject() as RenderBox;
    final Offset iconPosition = iconBox.localToGlobal(Offset.zero);

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
              top: 505,
              left: iconPosition.dx + 30,
              child: Material(
                color: Colors.white24,
                child: Container(
                  padding: EdgeInsets.all(8),
                  width: 300,
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
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: CurveClipper(),
              child: Container(
                height: 651,
                color: Color(0xFF0CA8E1),
              ),
            ),
          ),
          Positioned(
            top: 86,
            left: 57,
            right: 57,
            child: Image.asset(
              'assets/logo.png',
              width: 275,
              height: 161,
            ),
          ),
          Positioned(
            top: 250,
            left: 30,
            right: 30,
            child: Image.asset(
              'assets/qr_code.png',
              width: 250,
              height: 250,
            ),
          ),
          Positioned(
            bottom: 112,
            left: 17,
            right: 17,
            child: Text(
              "Shop smarter, faster, and easier with S.mart\n"
              "your ultimate shopping companion.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sarala',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.6,
                color: Colors.black,
              ),
            ),
          ),
          Positioned(
            bottom: 46,
            left: (390 - 163) / 2,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Start Shopping',
                style: TextStyle(
                  fontFamily: 'Sarala',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 205,
            left: 3,
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
        ],
      ),
    );
  }
}

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 195);
    path.quadraticBezierTo(
        size.width / 200, size.height + 40, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
