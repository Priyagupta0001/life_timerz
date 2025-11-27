import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int selectedIndex;
  final List<String>? sortOptions;
  final Function(String)? onSortChanged;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.selectedIndex,
    this.sortOptions,
    this.onSortChanged,
    required Color backgroundColor,
    required String selectedSort,
    required TextStyle style,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 246, 246, 255),
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      centerTitle: true, // Properly center the title
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions:
          (selectedIndex == 1 && sortOptions != null && onSortChanged != null)
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.sort_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                  onSelected: (value) {
                    onSortChanged!(value);
                  },
                  itemBuilder: (BuildContext context) {
                    return sortOptions!.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(
                          choice,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ]
          : [],
    );
  }
}
