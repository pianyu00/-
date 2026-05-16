import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final String nameEn;
  final IconData icon;
  final Color color;

  const CategoryInfo(this.name, this.nameEn, this.icon, this.color);
}

final List<CategoryInfo> expenseCategories = [
  CategoryInfo('餐饮', 'Dining', Icons.restaurant_outlined, Colors.orange),
  CategoryInfo('奶茶', 'Bubble Tea', Icons.coffee_outlined, Colors.brown),
  CategoryInfo('交通', 'Transport', Icons.directions_bus_outlined, Colors.blue),
  CategoryInfo('购物', 'Shopping', Icons.shopping_bag_outlined, Colors.pink),
  CategoryInfo('娱乐', 'Entertainment', Icons.movie_outlined, Colors.purple),
  CategoryInfo('医疗', 'Medical', Icons.medical_services_outlined, Colors.red),
  CategoryInfo('教育', 'Education', Icons.school_outlined, Colors.teal),
  CategoryInfo('通讯', 'Communication', Icons.phone_outlined, Colors.indigo),
  CategoryInfo('住房', 'Housing', Icons.home_outlined, Colors.brown),
  CategoryInfo('服饰', 'Clothing', Icons.checkroom_outlined, Colors.deepOrange),
  CategoryInfo('日用', 'Daily', Icons.shopping_cart_outlined, Colors.cyan),
  CategoryInfo('社交', 'Social', Icons.people_outlined, Colors.amber),
  CategoryInfo('其他', 'Other', Icons.more_horiz, Colors.grey),
];

final List<CategoryInfo> incomeCategories = [
  CategoryInfo('工资', 'Salary', Icons.work_outlined, Colors.green),
  CategoryInfo('兼职', 'Part-time', Icons.code_outlined, Colors.lightGreen),
  CategoryInfo('投资', 'Investment', Icons.trending_up, Colors.lime),
  CategoryInfo('红包', 'Red Packet', Icons.card_giftcard_outlined, Colors.redAccent),
  CategoryInfo('退款', 'Refund', Icons.refresh, Colors.blueGrey),
  CategoryInfo('其他', 'Other', Icons.more_horiz, Colors.grey),
];

/// Returns the display name for a category based on current language.
String categoryDisplayName(String chineseName, String lang) {
  if (lang != 'en') return chineseName;
  for (final cat in [...expenseCategories, ...incomeCategories]) {
    if (cat.name == chineseName) return cat.nameEn;
  }
  return chineseName;
}
