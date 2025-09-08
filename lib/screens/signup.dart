import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login.dart';
import '../models/user.dart';
import 'home_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController cniController = TextEditingController();
  final TextEditingController dateNaissanceController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController numeroController = TextEditingController(
    text: "+228 ",
  );
  final TextEditingController adresseController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Focus nodes pour la gestion du focus
  final FocusNode _nomFocus = FocusNode();
  final FocusNode _prenomFocus = FocusNode();
  final FocusNode _cniFocus = FocusNode();
  final FocusNode _dateFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _numeroFocus = FocusNode();
  final FocusNode _adresseFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Assurer que le curseur se place après le préfixe "+228 "
    numeroController.selection = TextSelection.fromPosition(
      TextPosition(offset: numeroController.text.length),
    );
  }

  @override
  void dispose() {
    // Libérer les ressources
    nomController.dispose();
    prenomController.dispose();
    cniController.dispose();
    dateNaissanceController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    numeroController.dispose();
    adresseController.dispose();

    _nomFocus.dispose();
    _prenomFocus.dispose();
    _cniFocus.dispose();
    _dateFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _numeroFocus.dispose();
    _adresseFocus.dispose();

    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // 18 ans par défaut
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff007BFF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dateNaissanceController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Extraire le numéro de téléphone sans le préfixe
      String numeroStr = numeroController.text.replaceAll("+228 ", "");
      int numero = int.tryParse(numeroStr) ?? 0;

      final result = await AuthService.register(
        nom: nomController.text.trim(),
        prenom: prenomController.text.trim(),
        cni: cniController.text.trim(),
        dateNaissance: dateNaissanceController.text.trim(),
        email: emailController.text.trim(),
        motDePasse: passwordController.text.trim(),
        numero: numero,
        adresse: adresseController.text.trim(),
        role: "CITOYEN", // Rôle par défaut pour les nouveaux utilisateurs
      );

      if (!mounted) return;

      if (result['success']) {
        print('✅ Inscription réussie : \n${result['data']}');

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! Veuillez vous connecter.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Rediriger vers la page de connexion après un délai
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Erreur d\'inscription')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'inscription: $e"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required FocusNode focusNode,
    bool isPassword = false,
    bool isDate = false,
    bool isPhone = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText:
          isPassword
              ? (isPassword == true
                  ? _obscurePassword
                  : _obscureConfirmPassword)
              : false,
      readOnly: isDate,
      onTap: isDate ? () => _selectDate(context) : null,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est requis';
            }
            if (label == "Email" &&
                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Veuillez entrer un email valide';
            }
            if (label == "Mot de passe" && value.length < 6) {
              return 'Le mot de passe doit contenir au moins 6 caractères';
            }
            if (label == "Confirmer le mot de passe" &&
                value != passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            if (isPhone && value.length < 13) {
              return 'Numéro de téléphone invalide';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade800),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xff007BFF), width: 1.5),
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    (isPassword == true
                            ? _obscurePassword
                            : _obscureConfirmPassword)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isPassword == true) {
                        _obscurePassword = !_obscurePassword;
                      } else {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }
                    });
                  },
                )
                : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff007BFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Logo or Image
                  Center(
                    child: SizedBox(
                      height: 100,
                      child: Image.asset(
                        "assets/images/background.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Heading
                  const Text(
                    "Créer un compte",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Rejoignez notre communauté",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Form Fields
                  inputField(
                    label: "Nom",
                    controller: nomController,
                    icon: Icons.person_outline,
                    focusNode: _nomFocus,
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: "Prénom",
                    controller: prenomController,
                    icon: Icons.person_outline,
                    focusNode: _prenomFocus,
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: "CNI",
                    controller: cniController,
                    icon: Icons.credit_card_outlined,
                    focusNode: _cniFocus,
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: "Date de naissance",
                    controller: dateNaissanceController,
                    icon: Icons.calendar_today_outlined,
                    focusNode: _dateFocus,
                    isDate: true,
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: "Email",
                    controller: emailController,
                    icon: Icons.email_outlined,
                    focusNode: _emailFocus,
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: "Mot de passe",
                    controller: passwordController,
                    icon: Icons.lock_outline,
                    focusNode: _passwordFocus,
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: "Confirmer le mot de passe",
                    controller: confirmPasswordController,
                    icon: Icons.lock_outline,
                    focusNode: _confirmPasswordFocus,
                    isPassword: false,
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: "Numéro de téléphone",
                    controller: numeroController,
                    icon: Icons.phone_outlined,
                    focusNode: _numeroFocus,
                    isPhone: true,
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: "Adresse",
                    controller: adresseController,
                    icon: Icons.location_on_outlined,
                    focusNode: _adresseFocus,
                  ),
                  const SizedBox(height: 30),
                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff007BFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                "S'inscrire",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Vous avez déjà un compte ? ",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Se connecter",
                          style: TextStyle(
                            color: Color(0xff007BFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
