import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/services/auth_service.dart';

class HomeHeader extends StatelessWidget {
  final bool isDark;

  const HomeHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    AuthService? authService;
    try {
      authService = Provider.of<AuthService>(context, listen: false);
    } catch (_) {}

    final photoUrl = authService?.currentUser?.photoURL ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAOmebCcL-tBf75LvGc6ipwfwsOuoOk0JHFI9_-bxtFtzxg-Gvn9k6VI8MliWvYzLg-xAeQ0SagmyxKKE1Z_36s2wkff5JPgMEk5XhogzNBDh-vl1XFdn6pGT9Spt-6zIdcPzfQewpZYs-2jpZ_47qkNM163fNM3IqQYOQzFQcEA10umHVOHOxSCj7ZoHIeGZ-VAH5EcWQiV9sXiomk3tZR36v18pacx1xwmqmWlEo7MrOgSh2JYUQwJxqkICkhRDy2n0dALOilShrw';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Open Manga Reader',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
              image: DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
