import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pethaven/colors.dart';

class PetProfileScreen extends StatefulWidget {
  final String selectedPetId;
  const PetProfileScreen({super.key, required this.selectedPetId});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _catBreeds = [
    'Abyssinian',
    'American Curl',
    'American Shorthair',
    'Balinese',
    'Bengal',
    'Birman',
    'Bombay',
    'British Longhair',
    'British Shorthair',
    'Burmese',
    'Chartreux',
    'Cornish Rex',
    'Devon Rex',
    'Domestic Longhair',
    'Domestic Shorthair',
    'Egyptian Mau',
    'Exotic Shorthair',
    'Himalayan',
    'Japanese Bobtail',
    'Korat',
    'Maine Coon',
    'Manx',
    'Mixed Breed / Unknown',
    'Norwegian Forest Cat',
    'Ocicat',
    'Oriental Longhair',
    'Oriental Shorthair',
    'Persian',
    'Ragdoll',
    'Russian Blue',
    'Savannah',
    'Scottish Fold',
    'Scottish Straight',
    'Selkirk Rex',
    'Siamese',
    'Siberian',
    'Singapura',
    'Snowshoe',
    'Somali',
    'Sphynx',
    'Tonkinese',
    'Turkish Angora',
    'Turkish Van',
  ];

  final List<String> _dogBreeds = [
    'Akita',
    'Alaskan Malamute',
    'American Pit Bull Terrier',
    'Australian Cattle Dog',
    'Australian Shepherd',
    'Basenji',
    'Beagle',
    'Belgian Malinois',
    'Bichon Frise',
    'Border Collie',
    'Boston Terrier',
    'Boxer',
    'Bulldog',
    'Bull Terrier',
    'Cavalier King Charles Spaniel',
    'Chihuahua',
    'Cocker Spaniel',
    'Corgi (Cardigan)',
    'Corgi (Pembroke)',
    'Dachshund',
    'Doberman Pinscher',
    'French Bulldog',
    'German Shepherd',
    'Golden Retriever',
    'Great Dane',
    'Greyhound',
    'Jack Russell Terrier',
    'Labrador Retriever',
    'Lhasa Apso',
    'Maltese',
    'Miniature Schnauzer',
    'Mixed Breed / Unknown',
    'Papillon',
    'Pekingese',
    'Pomeranian',
    'Poodle (Miniature)',
    'Poodle (Standard)',
    'Poodle (Toy)',
    'Rottweiler',
    'Saint Bernard',
    'Saluki',
    'Samoyed',
    'Shar Pei',
    'Shiba Inu',
    'Shih Tzu',
    'Siberian Husky',
    'Staffordshire Bull Terrier',
    'Vizsla',
    'Weimaraner',
    'West Highland White Terrier',
    'Whippet',
    'Yorkshire Terrier',
  ];

  // 🧩 Controllers
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _microchipCtrl = TextEditingController();
  final _vetNameCtrl = TextEditingController();
  final _vetPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // 🐾 Dropdown and data variables
  String _species = 'Cat';
  String _spayedStatus = 'Unknown';
  String _allergy = 'None';
  String _weightUnit = 'Kg';
  DateTime? _birthday;

  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  String? _uploadedFileUrl;

  @override
  void initState() {
    super.initState();
    _loadPetProfile();
  }

  // 🐶 Load existing pet profile
  Future<void> _loadPetProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await _firestore.collection('pets').doc(widget.selectedPetId).get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      _nameCtrl.text = data['name'] ?? '';
      _breedCtrl.text = data['breed'] ?? '';
      _species = data['species'] ?? 'Cat';
      _spayedStatus = data['spayedNeutered'] ?? 'Unknown';
      _allergy = data['allergy'] ?? 'None';
      _weightCtrl.text = data['weight']?.toString() ?? '';
      _weightUnit = data['weightUnit'] ?? 'Kg';
      _microchipCtrl.text = data['microchip'] ?? '';
      _vetNameCtrl.text = data['vetName'] ?? '';
      _vetPhoneCtrl.text = data['vetPhone'] ?? '';
      _notesCtrl.text = data['notes'] ?? '';
      _existingImageUrl = data['imageUrl'];
      _uploadedFileUrl = data['uploadedFile'];
      if (data['birthday'] != null) {
        _birthday = DateTime.tryParse(data['birthday']);
      }
      setState(() {});
    }
  }

  // 📸 Pick image
  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // ☁️ Upload image
  Future<String?> _uploadImage(File file, String uid) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('pet_images/${uid}_${DateTime.now()}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  // 📎 Upload file (PDF/Image)
  Future<void> _uploadPetFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final user = _auth.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance.ref().child(
            'pet_files/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}',
          );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      setState(() => _uploadedFileUrl = url);

      await _firestore.collection('pets').doc(widget.selectedPetId).update({
        'uploadedFile': url,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File uploaded successfully!'),
          backgroundColor: kSuccessColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  // 📅 Pick birthday
  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  // 💾 Save profile
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_nameCtrl.text.isEmpty || _breedCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!, user.uid);
      }

      final data = {
        'userId': user.uid,
        'name': _nameCtrl.text.trim(),
        'species': _species,
        'breed': _breedCtrl.text.trim(),
        'birthday': _birthday?.toIso8601String(),
        'spayedNeutered': _spayedStatus,
        'weight': _weightCtrl.text.trim(),
        'weightUnit': _weightUnit,
        'microchip': _microchipCtrl.text.trim(),
        'allergy': _allergy,
        'vetName': _vetNameCtrl.text.trim(),
        'vetPhone': _vetPhoneCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'imageUrl': imageUrl ?? _existingImageUrl,
        'uploadedFile': _uploadedFileUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.selectedPetId.isEmpty) {
        await _firestore.collection('pets').add(data);
      } else {
        await _firestore.collection('pets').doc(widget.selectedPetId).set(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet profile saved successfully!')),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile saved! You can go back now 💕')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save pet: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Pet Profile 🐾",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: kAccentColor,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: kAccentColor.withOpacity(0.3),
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_existingImageUrl != null
                        ? NetworkImage(_existingImageUrl!)
                        : null) as ImageProvider<Object>?,
                child: _imageFile == null && _existingImageUrl == null
                    ? const Icon(Icons.add_a_photo,
                        color: Colors.white, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              "Species",
              _species,
              ['Cat', 'Dog'],
              (v) {
                setState(() {
                  _species = v!;
                  _breedCtrl.clear(); // reset breed when species changes
                });
              },
            ),
            _buildTextField("Pet Name *", _nameCtrl, Icons.pets),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DropdownButtonFormField<String>(
                value: _breedCtrl.text.isNotEmpty ? _breedCtrl.text : null,
                items: (_species == 'Cat' ? _catBreeds : _dogBreeds)
                    .map(
                      (breed) => DropdownMenuItem(
                        value: breed,
                        child: Text(breed),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _breedCtrl.text = v!;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Breed *",
                  labelStyle: TextStyle(color: kTextSecondary),
                  filled: true,
                  fillColor: kCardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: TextStyle(color: kTextMain),
              ),
            ),
            _buildDatePicker("Birthday", _birthday, _pickBirthday),
            _buildDropdownField(
                "Spayed/Neutered",
                _spayedStatus,
                ['Yes', 'No', 'Unknown'],
                (v) => setState(() => _spayedStatus = v!)),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                      "Weight", _weightCtrl, Icons.monitor_weight),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _weightUnit,
                    items: const [
                      DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                      DropdownMenuItem(value: 'Lb', child: Text('Lb')),
                    ],
                    onChanged: (v) => setState(() => _weightUnit = v!),
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      labelStyle: TextStyle(color: kTextSecondary),
                      filled: true,
                      fillColor: kCardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(color: kTextMain),
                  ),
                ),
              ],
            ),
            _buildTextField("Microchip Number", _microchipCtrl, Icons.qr_code),
            _buildDropdownField(
                "Allergies",
                _allergy,
                [
                  'None',
                  'Beef',
                  'Chicken',
                  'Corn',
                  'Dairy',
                  'Egg',
                  'Fish',
                  'Lamb',
                  'Pork',
                  'Seafood',
                  'Soy',
                  'Wheat',
                  'Yeast'
                ],
                (v) => setState(() => _allergy = v!)),
            _buildTextField("Vet Name", _vetNameCtrl, Icons.local_hospital),
            _buildTextField("Vet Phone Number", _vetPhoneCtrl, Icons.phone),
            _buildTextField("Notes", _notesCtrl, Icons.note, maxLines: 3),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Upload Pet Files (PDF / Image)",
                style: TextStyle(
                    color: kTextSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 6),
            Text(
              "Supported formats: PDF, JPG, PNG",
              style: TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            if (_uploadedFileUrl != null)
              Text("File uploaded successfully ✅",
                  style: TextStyle(color: kSuccessColor)),
            const SizedBox(height: 25),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // 📋 Helper Widgets
  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        style: TextStyle(color: kTextMain),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: kTextSecondary),
          prefixIcon: Icon(icon, color: kAccentColor),
          filled: true,
          fillColor: kCardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: kTextSecondary),
          filled: true,
          fillColor: kCardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        style: TextStyle(color: kTextMain),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: kTextSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: kCardBackground,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date == null
                    ? 'Select date'
                    : DateFormat('MMM d, yyyy').format(date),
                style: TextStyle(color: kTextMain, fontSize: 16),
              ),
              Icon(Icons.calendar_today, color: kPrimaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
