import 'package:flutter/material.dart';

// 🍓🍵 Strawberry Matcha Theme Colors

// 🌿 Backgrounds
const kBackgroundColor = Color(0xFFF9FBE7); // creamy matcha
const kCardBackground = Colors.white; // clean white for cards

// 💚 Primary & Accent
const kPrimaryColor = Color(0xFFA5D6A7); // matcha green
const kAccentColor = Color(0xFFF48FB1); // strawberry pink

// 🖋️ Text Colors
const kTextMain = Color(0xFF212121); // dark charcoal (main readable text)
const kTextSecondary = Color(0xFF33691E); // dark olive green (labels)

// ⚠️ Feedback Colors
const kErrorColor = Color(0xFFFFAB91); // soft coral for errors
const kSuccessColor = Color(0xFF81C784); // soft mint green for success

// 🌈 Optional Gradient
const kGradient = LinearGradient(
  colors: [kAccentColor, kPrimaryColor],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
