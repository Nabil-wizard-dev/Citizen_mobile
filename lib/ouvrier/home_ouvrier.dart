import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppe_mobile/ouvrier/screens/notifications_screen.dart';
import 'package:ppe_mobile/ouvrier/screens/taches_list.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../screens/login.dart';
import '../screens/profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class HomeOuvrierScreen extends StatefulWidget {
  final User user;
  const HomeOuvrierScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeOuvrierScreen> createState() => _HomeOuvrierScreenState();
}

class _HomeOuvrierScreenState extends State<HomeOuvrierScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String? userPhotoUrl;
  String userName = 'Ouvrier';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
    _pages = [
      TachesListScreen(user: widget.user),
      NotificationsScreen(ouvrierId: widget.user.trackingId ?? ''),
      ProfileScreen(user: widget.user, onProfileUpdated: _forceRefreshUserInfo),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      print('🔍 Données utilisateur brutes: $userDataStr');

      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        print('🔍 Données décodées: $userData');
        print('🔍 Photo profil: ${userData['photoProfil']}');
        print('🔍 Type photo profil: ${userData['photoProfil'].runtimeType}');

        setState(() {
          userName =
              '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}'.trim();

          // Ne mettre à jour la photo que si elle n'existe pas déjà ou si elle a changé
          final newPhotoUrl =
              userData['photoProfil'] != null &&
                      userData['photoProfil'].toString().isNotEmpty &&
                      userData['photoProfil'].toString() != 'null'
                  ? 'http://192.168.1.70:8080/${userData['photoProfil']}'
                  : null;

          if (userPhotoUrl == null || userPhotoUrl != newPhotoUrl) {
            userPhotoUrl = newPhotoUrl;
            if (newPhotoUrl != null) {
              print('✅ URL photo mise à jour: $newPhotoUrl');
            } else {
              print('❌ Pas de photo de profil valide');
            }
          } else {
            print('✅ Photo déjà affichée, pas de changement');
          }
        });

        // Forcer le rafraîchissement de l'interface
        if (mounted) {
          setState(() {});
        }
      } else {
        print('❌ Pas de données utilisateur dans localStorage');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des infos utilisateur: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Ne pas recharger les infos quand on va au profil car la photo est déjà gérée
    // if (index == 2) {
    //   _loadUserInfo();
    // }
  }

  void _forceRefreshUserInfo([String? photoUrl]) {
    if (photoUrl != null) {
      // Utiliser directement l'URL de la photo fournie
      setState(() {
        userPhotoUrl = photoUrl;
      });
      print('✅ Photo mise à jour directement: $photoUrl');
    } else {
      // Fallback vers le chargement depuis localStorage
      _loadUserInfo();
    }
  }

  Widget _buildProfileAvatar({
    required double radius,
    required double iconSize,
  }) {
    if (userPhotoUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person, color: Colors.grey[600], size: iconSize),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(userPhotoUrl!),
      backgroundColor: Colors.grey[300],
      onBackgroundImageError: (exception, stackTrace) {
        // Ne pas réinitialiser userPhotoUrl, juste afficher l'icône par défaut
        print(
          '⚠️ Erreur de chargement de la photo, affichage de l\'icône par défaut',
        );
      },
      child:
          userPhotoUrl == null
              ? Icon(Icons.person, color: Colors.grey[600], size: iconSize)
              : null,
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Poignée
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // En-tête avec photo et nom
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildProfileAvatar(radius: 30, iconSize: 30),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Ouvrier',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey[200]),

              // Options du menu
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Mon Profil',
                      subtitle: 'Gérer mes informations',
                      onTap: () {
                        Navigator.pop(context);
                        setState(
                          () => _selectedIndex = 2,
                        ); // Aller à la page profil
                        _forceRefreshUserInfo();
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Voir mes notifications',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedIndex = 1);
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.assignment_outlined,
                      title: 'Mes Tâches',
                      subtitle: 'Voir mes signalements',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedIndex = 0);
                      },
                    ),

                    Divider(height: 1, color: Colors.grey[200]),

                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Déconnexion',
                      subtitle: 'Se déconnecter de l\'application',
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await AuthService.forceLogout();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erreur lors de la déconnexion: $e',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.assignment_outlined, 'Tâches'),
              _buildNavItem(1, Icons.notifications_outlined, 'Notifications'),
              _buildNavItem(2, Icons.person_outline, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[600],
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[600],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Accueil $userName',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.more_vert, size: 28, color: const Color(0xFF1E3A8A)),
          onPressed: () => _showMenu(context),
        ),
        actions: [
          // Photo de profil cliquable
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 2; // Aller à la page profil
              });
              _forceRefreshUserInfo();
            },
            child: Container(
              margin: EdgeInsets.only(right: 16),
              child: _buildProfileAvatar(radius: 18, iconSize: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
