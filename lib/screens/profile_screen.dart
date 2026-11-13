import 'package:flutter/material.dart';

import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _favoriteController = TextEditingController();
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final provider = UserProvider.of(context);
      _nameController = TextEditingController(text: provider.user.name);
      _emailController = TextEditingController(text: provider.user.email);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final provider = UserProvider.of(context);
      String inputName = _nameController.text.trim();
      String inputEmail = _emailController.text.trim();

      // Latihan 5: Validasi Keamanan (Mendeteksi karakter berbahaya / script injection)
      final dangerousCharRegex = RegExp(
        r'<script>|<\/script>|<|>|script',
        caseSensitive: false,
      );
      if (dangerousCharRegex.hasMatch(inputName) ||
          dangerousCharRegex.hasMatch(inputEmail)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Peringatan: Input mengandung karakter berbahaya (<script>/HTML)!',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedUser = provider.user.copyWith(
        name: inputName,
        email: inputEmail,
        isLoggedIn: true,
      );
      provider.updateUser(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              UserProvider.of(context).logout();
              Navigator.pop(dialogContext);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = UserProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Favorit'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(thickness: 2),
                      const Text(
                        'Daftar Hobi / Item Favorit (Latihan 3)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _favoriteController,
                              decoration: const InputDecoration(
                                hintText: 'Tambah hobi baru...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_favoriteController.text.isNotEmpty) {
                                provider.addFavorite(_favoriteController.text);
                                _favoriteController.clear();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tambah'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      provider.favorites.isEmpty
                          ? const Text(
                              'Belum ada hobi/favorit yang disimpan.',
                              style: TextStyle(color: Colors.grey),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.favorites.length,
                              itemBuilder: (context, index) {
                                final fav = provider.favorites[index];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                                    title: Text(fav),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () =>
                                          provider.removeFavorite(fav),
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),
                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.amber[800]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan Keamanan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Data disimpan di SharedPreferences (plaintext). '
                                'Jangan simpan password atau data sensitif di sini. '
                                'Gunakan secure storage untuk data sensitif.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
