import 'package:flutter/material.dart';
import 'package:ppe_mobile/screens/signalement.dart';
import 'package:ppe_mobile/screens/signalement_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'login.dart';
import '../services/auth_service.dart';
import '../services/signalement_service.dart';
import '../models/user.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isSideBarOpen = false;
  AnimationController? _animationController;
  String? userPhotoUrl;
  String userName = 'Utilisateur';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Rafraîchir les données quand l'app revient au premier plan
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        setState(() {
          userName =
              '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}'.trim();

          // Vérifier si la photo existe et n'est pas vide
          if (userData['photoProfil'] != null &&
              userData['photoProfil'].toString().isNotEmpty &&
              userData['photoProfil'].toString() != 'null') {
            userPhotoUrl =
                'http://192.168.1.70:8080/${userData['photoProfil']}';
            print('✅ Photo chargée pour citoyen: $userPhotoUrl');
          } else {
            userPhotoUrl = null;
            print('❌ Pas de photo de profil pour le citoyen');
          }
        });
      } else {
        print('❌ Pas de données utilisateur dans localStorage pour le citoyen');
      }
    } catch (e) {
      print('Erreur lors du chargement des infos utilisateur: $e');
    }
  }

  // Fonction utilitaire pour vérifier si l'appareil peut faire des appels
  Future<bool> _canMakePhoneCalls() async {
    try {
      // Tester avec un numéro d'urgence réel pour voir si l'appareil peut lancer des appels
      final Uri testUri = Uri(scheme: 'tel', path: '112');
      bool canLaunch = await canLaunchUrl(testUri);
      print('🔍 Test de capacité d\'appel: $canLaunch');
      return canLaunch;
    } catch (e) {
      print('❌ Erreur lors de la vérification des capacités d\'appel: $e');
      return false;
    }
  }

  // Fonction pour tester les différentes méthodes d'appel
  Future<void> _testCallMethods(String phoneNumber) async {
    print('🧪 Test des méthodes d\'appel pour: $phoneNumber');

    // Test 1: Uri.parse
    try {
      final Uri uri1 = Uri.parse('tel:$phoneNumber');
      bool canLaunch1 = await canLaunchUrl(uri1);
      print('Test 1 - Uri.parse: $canLaunch1');
    } catch (e) {
      print('Test 1 - Uri.parse erreur: $e');
    }

    // Test 2: Uri scheme
    try {
      final Uri uri2 = Uri(scheme: 'tel', path: phoneNumber);
      bool canLaunch2 = await canLaunchUrl(uri2);
      print('Test 2 - Uri scheme: $canLaunch2');
    } catch (e) {
      print('Test 2 - Uri scheme erreur: $e');
    }

    // Test 3: Direct launch
    try {
      final Uri uri3 = Uri.parse('tel:$phoneNumber');
      await launchUrl(uri3);
      print('Test 3 - Direct launch: SUCCESS');
    } catch (e) {
      print('Test 3 - Direct launch erreur: $e');
    }
  }

  // Fonction pour afficher des informations sur les capacités d'appel
  void _showCallCapabilitiesInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Informations sur les appels'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre appareil semble ne pas pouvoir faire d\'appels téléphoniques.',
              ),
              SizedBox(height: 12),
              Text('Causes possibles :'),
              SizedBox(height: 8),
              Text('• Vous utilisez un simulateur/émulateur'),
              Text('• Aucune carte SIM installée'),
              Text('• Aucune application téléphone'),
              Text('• Permissions manquantes'),
              SizedBox(height: 12),
              Text('Solutions :'),
              SizedBox(height: 8),
              Text('• Testez sur un appareil réel'),
              Text('• Vérifiez les permissions'),
              Text('• Installez une app téléphone'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Compris'),
            ),
          ],
        );
      },
    );
  }

  // Fonction pour expliquer comment confirmer l'appel
  void _showCallConfirmationInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer l\'appel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'L\'application téléphone s\'est ouverte avec le numéro composé.',
              ),
              SizedBox(height: 12),
              Text('Pour lancer l\'appel :'),
              SizedBox(height: 8),
              Text('1. Vérifiez que le numéro est correct'),
              Text('2. Appuyez sur le bouton vert d\'appel'),
              Text('3. Confirmez l\'appel si demandé'),
              SizedBox(height: 12),
              Text(
                'Note : Cette confirmation est une mesure de sécurité d\'Android.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Compris'),
            ),
          ],
        );
      },
    );
  }

  void _toggleSideBar() {
    setState(() {
      _isSideBarOpen = !_isSideBarOpen;
      if (_isSideBarOpen) {
        _animationController?.forward();
      } else {
        _animationController?.reverse();
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.forceLogout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Accueil $userName'),
        actions: [
          // Photo de profil cliquable
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 2; // Aller à la page profil
              });
              _loadUserInfo(); // Rafraîchir les données
            },
            child: Container(
              margin: EdgeInsets.only(right: 16),
              child: _buildProfileAvatar(radius: 18, iconSize: 20),
            ),
          ),
        ],
      ),
      drawer: _buildSideBar(context),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [_buildHomePage(), _buildReportPage(), _buildProfilePage()],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatbotScreen()),
                );
              },
              backgroundColor: Colors.deepPurple,
              heroTag: 'chatbot',
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignalementPage(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF1E3A8A),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              heroTag: 'signalement',
              child: const Icon(Icons.add_alert, color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
              _buildNavItem(0, Icons.home_outlined, 'Accueil'),
              _buildNavItem(1, Icons.report_outlined, 'Signalements'),
              _buildNavItem(2, Icons.person_outline, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            setState(() {
              _selectedIndex = 0; // Page d'accueil
            });
            break;
          case 1:
            setState(() {
              _selectedIndex = 1; // Page signalements
            });
            break;
          case 2:
            setState(() {
              _selectedIndex = 2; // Page profil
            });
            _loadUserInfo(); // Rafraîchir les données
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                _selectedIndex == index
                    ? const Color(0xFF1E3A8A)
                    : Colors.grey[600],
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  _selectedIndex == index
                      ? const Color(0xFF1E3A8A)
                      : Colors.grey[600],
              fontSize: 12,
              fontWeight:
                  _selectedIndex == index ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 30.0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E3A8A),
                          const Color(0xFF3B82F6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child:
                          userPhotoUrl != null
                              ? Image.network(
                                userPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  );
                                },
                              )
                              : const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isNotEmpty ? userName : "Utilisateur",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.user.email ?? "Aucun email",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        SizedBox(height: 2),

                        ...[
                        SizedBox(height: 2),
                        Text(
                          "📞 ${widget.user.numero}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.dashboard_outlined,
              title: "Tableau de bord",
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: "Historique des signalements",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignalementListPage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.map_outlined,
              title: "Carte des signalements",
              onTap: () => Navigator.pop(context),
            ),

            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: "Paramètres",
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 2; // Aller à la page profil
                });
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: "Aide et support",
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.logout,
              title: "Déconnexion",
              onTap: () => _logout(context),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 16)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Section héroïque modernisée
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    bottom: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    top: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shield,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Citoyen Alert",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Signaler un incident",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Services municipaux et d'urgence",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignalementPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E3A8A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_alert, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  "Signaler maintenant",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Section services modernisée
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Services",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                  ),
                  child: const Text("Voir tout"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildServiceCard(
                  title: "Police",
                  icon: Icons.local_police,
                  color: const Color(0xFF3B82F6),
                  phoneNumber: "117",
                ),
                _buildServiceCard(
                  title: "Pompiers",
                  icon: Icons.fire_truck,
                  color: const Color(0xFFEF4444),
                  phoneNumber: "118",
                ),
                _buildServiceCard(
                  title: "Urgence",
                  icon: Icons.emergency,
                  color: const Color(0xFF10B981),
                  phoneNumber: "112",
                ),
                _buildServiceCard(
                  title: "Mairie",
                  icon: Icons.account_balance,
                  color: const Color(0xFF8B5CF6),
                  phoneNumber: "118",
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Section signalements récents modernisée
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Signalements récents",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignalementListPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                  ),
                  child: const Text("Voir tout"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Liste des signalements récents modernisée
            FutureBuilder<Map<String, dynamic>>(
              future: SignalementService.getSignalements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.data!['success']) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Impossible de charger les signalements',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tirez vers le bas pour actualiser',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final signalements = snapshot.data!['data'] as List<dynamic>;

                if (signalements.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun signalement récent',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre premier signalement !',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Afficher seulement les 3 premiers signalements
                final recentSignalements = signalements.take(3).toList();

                return Column(
                  children:
                      recentSignalements.map((signalement) {
                        return _buildReportCard(
                          title: signalement['titre'] ?? 'Sans titre',
                          description:
                              signalement['description'] ??
                              'Aucune description',
                          status: _getStatusText(
                            signalement['statut'] ?? 'EN_ATTENTE',
                          ),
                          date: _formatDate(signalement['dateCreation']),
                          icon: _getTypeServiceIcon(signalement['typeService']),
                          statusColor: _getStatusColor(
                            signalement['statut'] ?? 'EN_ATTENTE',
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color color,
    required String phoneNumber,
  }) {
    return GestureDetector(
      onTap: () async {
        // Demander confirmation avant l'appel d'urgence
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirmer l\'appel'),
              content: Text(
                'Voulez-vous vraiment appeler $title ($phoneNumber) ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Appeler', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          // Tester d'abord les méthodes disponibles
          await _testCallMethods(phoneNumber);

          // Essayer de lancer l'appel avec plusieurs méthodes
          bool callLaunched = false;

          // Méthode 1: Utiliser Uri.parse avec tel: (la plus courante)
          try {
            final Uri phoneUri = Uri.parse('tel:$phoneNumber');
            print('📞 Tentative d\'appel avec Uri.parse vers: $phoneNumber');

            await launchUrl(phoneUri);
            callLaunched = true;
            print('✅ Appel lancé avec Uri.parse vers: $phoneNumber');
          } catch (e) {
            print('❌ Erreur avec Uri.parse: $e');
          }

          // Méthode 2: Essayer avec des paramètres supplémentaires pour lancer automatiquement
          if (!callLaunched) {
            try {
              final Uri phoneUri = Uri.parse('tel:$phoneNumber?autodial=true');
              print(
                '📞 Tentative d\'appel automatique avec paramètres vers: $phoneNumber',
              );

              await launchUrl(phoneUri);
              callLaunched = true;
              print('✅ Appel automatique lancé vers: $phoneNumber');
            } catch (e) {
              print('❌ Erreur avec appel automatique: $e');
            }
          }

          // Méthode 3: Utiliser le schéma tel: directement
          if (!callLaunched) {
            try {
              final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
              print(
                '📞 Tentative d\'appel avec tel: scheme vers: $phoneNumber',
              );

              await launchUrl(phoneUri);
              callLaunched = true;
              print('✅ Appel lancé avec tel: scheme vers: $phoneNumber');
            } catch (e) {
              print('❌ Erreur avec tel: scheme: $e');
            }
          }

          // Méthode 4: Essayer avec canLaunchUrl d'abord, puis launchUrl
          if (!callLaunched) {
            try {
              final Uri phoneUri = Uri.parse('tel:$phoneNumber');
              print(
                '📞 Tentative d\'appel avec vérification préalable vers: $phoneNumber',
              );

              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
                callLaunched = true;
                print('✅ Appel lancé avec vérification vers: $phoneNumber');
              } else {
                print('❌ canLaunchUrl retourne false pour: $phoneNumber');
              }
            } catch (e) {
              print('❌ Erreur avec vérification préalable: $e');
            }
          }

          // Si l'appel a été lancé, afficher un message informatif
          if (callLaunched) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Appel lancé'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'L\'appel vers $title ($phoneNumber) a été lancé.',
                        ),
                        SizedBox(height: 12),
                        Text(
                          'L\'application téléphone s\'est ouverte avec le numéro composé.',
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Pour confirmer l\'appel, appuyez sur le bouton vert dans l\'application téléphone.',
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showCallConfirmationInfo();
                        },
                        child: Text('Instructions'),
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            // Si aucune méthode n'a fonctionné
            print(
              '❌ Aucune méthode d\'appel n\'a fonctionné pour: $phoneNumber',
            );
            if (mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Impossible d\'appeler'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'L\'appel vers $title ($phoneNumber) n\'a pas pu être lancé automatiquement.',
                        ),
                        SizedBox(height: 12),
                        Text('Causes possibles :'),
                        SizedBox(height: 8),
                        Text('• Application téléphone non détectée'),
                        Text('• Permissions manquantes'),
                        Text('• Configuration système'),
                        SizedBox(height: 12),
                        Text('Solutions :'),
                        SizedBox(height: 8),
                        Text('• Vérifiez les permissions'),
                        Text('• Redémarrez l\'application'),
                        Text('• Contactez le support'),
                        SizedBox(height: 12),
                        Text('Numéro à composer manuellement :'),
                        Text(
                          phoneNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showCallCapabilitiesInfo();
                        },
                        child: Text('Plus d\'infos'),
                      ),
                    ],
                  );
                },
              );
            }
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required String status,
    required String date,
    required IconData icon,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPage() {
    return const SignalementListPage();
  }

  Widget _buildProfilePage() {
    return ProfileScreen(
      user: widget.user,
      onProfileUpdated: (photoUrl) {
        // Mettre à jour la photo si fournie
        if (photoUrl != null) {
          setState(() {
            userPhotoUrl = photoUrl;
          });
        }
        _loadUserInfo(); // Rafraîchir les autres données
      },
    );
  }

  // Méthodes utilitaires pour les signalements
  String _getStatusText(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'EN_COURS':
        return 'En cours';
      case 'TRAITE':
        return 'Traité';
      case 'REJETE':
        return 'Rejeté';
      case 'ARCHIVE':
        return 'Archivé';
      default:
        return status;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return 'Date invalide';
    }
  }

  IconData _getTypeServiceIcon(String? typeService) {
    switch (typeService) {
      case 'SERVICE_HYGIENE':
        return Icons.cleaning_services;
      case 'SERVICE_MUNICIPAL':
        return Icons.location_city;
      default:
        return Icons.report_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return Colors.orange;
      case 'EN_COURS':
        return Colors.blue;
      case 'TRAITE':
        return Colors.green;
      case 'REJETE':
        return Colors.red;
      case 'ARCHIVE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
