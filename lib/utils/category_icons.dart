import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

// Main category icons
const mainCategoryIcons = <({String key, String label, IconData icon})>[
  (key: 'vegi', label: 'Vegi', icon: Icons.eco_outlined),
  (key: 'fleisch', label: 'Fleisch', icon: Icons.set_meal_outlined),
  (key: 'fisch', label: 'Fisch', icon: MaterialCommunityIcons.fishbowl_outline),
  (key: 'süss', label: 'Süss', icon: Icons.cake_outlined),
  (key: 'drink', label: 'Drink', icon: Icons.local_drink_outlined),
];

// Additional icons for the picker
const additionalCategoryIcons = <({String key, String label, IconData icon})>[
  // Food & Drinks
  (key: 'pizza', label: 'Pizza', icon: Icons.local_pizza_outlined),
  (key: 'burger', label: 'Burger', icon: Icons.lunch_dining_outlined),
  (key: 'ramen', label: 'Ramen', icon: Icons.ramen_dining_outlined),
  (key: 'soup', label: 'Suppe', icon: Icons.soup_kitchen_outlined),
  (key: 'breakfast', label: 'Frühstück', icon: Icons.breakfast_dining_outlined),
  (key: 'dinner', label: 'Dinner', icon: Icons.dinner_dining_outlined),
  (key: 'icecream', label: 'Eis', icon: Icons.icecream_outlined),
  (key: 'coffee', label: 'Kaffee', icon: Icons.coffee_outlined),
  (key: 'wine', label: 'Wein', icon: Icons.wine_bar_outlined),
  (key: 'cocktail', label: 'Cocktail', icon: Icons.local_bar_outlined),
  (key: 'restaurant', label: 'Restaurant', icon: Icons.restaurant_outlined),
  (key: 'fastfood', label: 'Fastfood', icon: Icons.fastfood_outlined),
  (key: 'tapas', label: 'Tapas', icon: Icons.tapas_outlined),
  (key: 'brunch', label: 'Brunch', icon: Icons.brunch_dining_outlined),
  (key: 'bakery', label: 'Bäckerei', icon: Icons.bakery_dining_outlined),
  (key: 'egg', label: 'Ei', icon: Icons.egg_outlined),
  (key: 'rice', label: 'Reis', icon: Icons.rice_bowl_outlined),
  (key: 'bento', label: 'Bento', icon: Icons.bento_outlined),

  // Cooking & Kitchen
  (key: 'kitchen', label: 'Küche', icon: Icons.kitchen_outlined),
  (key: 'microwave', label: 'Mikrowelle', icon: Icons.microwave_outlined),
  (key: 'blender', label: 'Mixer', icon: Icons.blender_outlined),
  (key: 'grill', label: 'Grill', icon: Icons.outdoor_grill_outlined),
  (key: 'fireplace', label: 'Ofen', icon: Icons.fireplace_outlined),

  // Occasions & Themes
  (key: 'celebration', label: 'Feier', icon: Icons.celebration_outlined),
  (key: 'favorite', label: 'Favoriten', icon: Icons.favorite_outline),
  (key: 'star', label: 'Star', icon: Icons.star_outline),
  (key: 'child', label: 'Kinder', icon: Icons.child_care_outlined),
  (key: 'family', label: 'Familie', icon: Icons.family_restroom_outlined),
  (key: 'grade', label: 'Top', icon: Icons.grade_outlined),
  (key: 'holiday', label: 'Urlaub', icon: Icons.holiday_village_outlined),
  (key: 'beach', label: 'Strand', icon: Icons.beach_access_outlined),
  (key: 'spa', label: 'Wellness', icon: Icons.spa_outlined),
  (key: 'fitness', label: 'Fitness', icon: Icons.fitness_center_outlined),

  // Regional & World Cuisine
  (key: 'public', label: 'International', icon: Icons.public_outlined),
  (key: 'language', label: 'Sprache', icon: Icons.language_outlined),
  (key: 'flight', label: 'Reise', icon: Icons.flight_outlined),
  (key: 'terrain', label: 'Regional', icon: Icons.terrain_outlined),

  // Time-based
  (key: 'schedule', label: 'Zeitplan', icon: Icons.schedule_outlined),
  (key: 'alarm', label: 'Schnell', icon: Icons.alarm_outlined),
  (key: 'today', label: 'Heute', icon: Icons.today_outlined),
  (key: 'weekend', label: 'Wochenende', icon: Icons.weekend_outlined),
  (key: 'nights', label: 'Abend', icon: Icons.nights_stay_outlined),
  (key: 'sunny', label: 'Sommer', icon: Icons.wb_sunny_outlined),
  (key: 'cloudy', label: 'Herbst', icon: Icons.wb_cloudy_outlined),
  (key: 'snow', label: 'Winter', icon: Icons.ac_unit_outlined),

  // Health & Diet
  (key: 'health', label: 'Gesund', icon: Icons.health_and_safety_outlined),
  (key: 'water', label: 'Wasser', icon: Icons.water_drop_outlined),
  (key: 'energy', label: 'Energie', icon: Icons.bolt_outlined),
  (key: 'mediation', label: 'Balance', icon: Icons.self_improvement_outlined),

  // Ingredients & Categories
  (key: 'grain', label: 'Getreide', icon: Icons.grain_outlined),
  (key: 'pepper', label: 'Gewürze', icon: Icons.local_florist_outlined),
  (key: 'cheese', label: 'Käse', icon: Icons.food_bank_outlined),
  (key: 'bread', label: 'Brot', icon: Icons.breakfast_dining_outlined),
  (key: 'noodles', label: 'Nudeln', icon: Icons.ramen_dining_outlined),
  (key: 'pot', label: 'Topf', icon: Icons.soup_kitchen_outlined),
  (key: 'food_apple', label: 'Apfel', icon: Icons.apple_outlined),
  (key: 'carrot', label: 'Gemüse', icon: Icons.eco_outlined),
  (key: 'chili', label: 'Scharf', icon: Icons.whatshot_outlined),

  // Others
  (key: 'book', label: 'Buch', icon: Icons.menu_book_outlined),
  (key: 'palette', label: 'Kreativ', icon: Icons.palette_outlined),
  (key: 'whatshot', label: 'Trending', icon: Icons.whatshot_outlined),
  (key: 'new', label: 'Neu', icon: Icons.new_releases_outlined),
  (key: 'explore', label: 'Entdecken', icon: Icons.explore_outlined),
  (key: 'lightbulb', label: 'Ideen', icon: Icons.lightbulb_outline),
  (key: 'andere', label: 'Andere', icon: Icons.category_outlined),
];

// Helper function to get icon by key
IconData getIconForKey(String? key) {
  if (key == null) return Icons.folder_outlined;

  // Check main icons first
  for (final icon in mainCategoryIcons) {
    if (icon.key == key) return icon.icon;
  }

  // Check additional icons
  for (final icon in additionalCategoryIcons) {
    if (icon.key == key) return icon.icon;
  }

  // Default fallback
  return Icons.folder_outlined;
}
