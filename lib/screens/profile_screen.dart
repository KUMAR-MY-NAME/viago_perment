import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  String? _profileImageUrl;

  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Load profile data from Firestore
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString("username");
    String? phone = prefs.getString("phone");

    if (username == null || phone == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final query = await FirebaseFirestore.instance
            .collection("users")
            .where("uid", isEqualTo: user.uid)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final userData = query.docs.first.data();
          username = userData["username"];
          phone = userData["phone"];

          await prefs.setString("username", username!);
          await prefs.setString("phone", phone!);
        }
      }
    }

    if (username != null) {
      final profileDoc = await FirebaseFirestore.instance
          .collection("profiles")
          .doc(username)
          .get();

      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        setState(() {
          _usernameController.text = username!;
          _phoneController.text = phone ?? "";
          _nameController.text = data["name"] ?? "";
          _ageController.text = data["age"] ?? "";
          _genderController.text = data["gender"] ?? "";
          _emailController.text = data["email"] ?? "";
          _profileImageUrl = data["profileImage"];
        });
      }
    }
  }

  /// ✅ Pick Image from gallery
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// ✅ Upload image to Firebase Storage
  Future<String?> _uploadImage(File file, String username) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child("$username.jpg");

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }

  /// ✅ Save Profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate user exists
    final query = await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .where("phone", isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Invalid username or phone number. Try again.")),
      );
      return;
    }

    // Upload new image if selected
    if (_imageFile != null) {
      final url = await _uploadImage(_imageFile!, username);
      if (url != null) {
        setState(() {
          _profileImageUrl = url;
        });
      }
    }

    // Save profile into Firestore
    final data = {
      "username": username,
      "phone": phone,
      "name": _nameController.text.trim(),
      "age": _ageController.text.trim(),
      "gender": _genderController.text.trim(),
      "email": _emailController.text.trim(),
      "profileImage": _profileImageUrl ?? "",
      "updatedAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("profiles")
        .doc(username)
        .set(data, SetOptions(merge: true));

    // ✅ Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
    await prefs.setString("phone", phone);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  /// ✅ Settings Modal
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, "/login");
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete Account"),
            onTap: () async {
              Navigator.pop(ctx);
              final username = _usernameController.text.trim();
              if (username.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .where("username", isEqualTo: username)
                    .get()
                    .then((snapshot) async {
                  for (var doc in snapshot.docs) {
                    await doc.reference.delete();
                  }
                });

                await FirebaseFirestore.instance
                    .collection("profiles")
                    .doc(username)
                    .delete();

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!mounted) return;
                Navigator.pushReplacementNamed(context, "/login");
              }
            },
          ),
        ],
      ),
    );
  }

  /// ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) as ImageProvider<Object>
                      : (_profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                              as ImageProvider<Object>
                          : null),
                  child: _imageFile == null &&
                          (_profileImageUrl == null ||
                              _profileImageUrl!.isEmpty)
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter username" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter phone number" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Age"),
                validator: (v) => v == null || v.isEmpty ? "Enter age" : null,
              ),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(labelText: "Gender"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter gender" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v == null || v.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
