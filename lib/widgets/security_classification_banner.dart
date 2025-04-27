import 'package:flutter/material.dart';
import '../constants/security_constants.dart';

/// A widget that displays the security classification of the app
class SecurityClassificationBanner extends StatelessWidget {
  final bool isTop;
  final bool isCompact;
  
  const SecurityClassificationBanner({
    Key? key,
    this.isTop = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final classification = SecurityConstants.securityClassification;
    final Color bannerColor = _getBannerColor(classification);
    
    return Container(
      width: double.infinity,
      color: bannerColor,
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 2.0 : 4.0,
        horizontal: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isCompact) const Icon(Icons.security, color: Colors.white, size: 16),
          if (!isCompact) const SizedBox(width: 8),
          Text(
            classification,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 10.0 : 14.0,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getBannerColor(String classification) {
    switch (classification.toUpperCase()) {
      case 'TOP SECRET':
        return Colors.orange;
      case 'SECRET':
        return Colors.red;
      case 'CONFIDENTIAL':
        return Colors.blue;
      case 'RESTRICTED':
        return Colors.green;
      case 'OFFICIAL':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// A widget that wraps content with security classification banners
class SecurityClassificationWrapper extends StatelessWidget {
  final Widget child;
  final bool showTopBanner;
  final bool showBottomBanner;
  final bool isCompact;
  
  const SecurityClassificationWrapper({
    Key? key,
    required this.child,
    this.showTopBanner = true,
    this.showBottomBanner = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopBanner)
          SecurityClassificationBanner(isTop: true, isCompact: isCompact),
        Expanded(child: child),
        if (showBottomBanner)
          SecurityClassificationBanner(isTop: false, isCompact: isCompact),
      ],
    );
  }
}
