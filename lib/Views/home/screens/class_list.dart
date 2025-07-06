import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/models/class.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/utils/class_color_helper.dart';

class ClassList extends StatelessWidget {
  final List<SchoolClass> classes;
  final void Function(SchoolClass) onClassSelected;
  final int? selectedClassId;
  final String searchQuery;
  final void Function(String) onSearchChanged;
  final Map<int, int>? studentCounts; // classId -> count
  final Map<int, int>? attendanceCounts; // classId -> count

  const ClassList({
    Key? key,
    required this.classes,
    required this.onClassSelected,
    this.selectedClassId,
    required this.searchQuery,
    required this.onSearchChanged,
    this.studentCounts,
    this.attendanceCounts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filtered =
        classes
            .where(
              (c) =>
                  c.fullName.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();
    return Column(
      children: [
        // Enhanced version with shadow and clear button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search class name...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 22,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                  onPressed: () {
                    // Clear the search field
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ),

        Expanded(
          child:
              filtered.isEmpty
                  ? const Center(child: Text('No classes found.'))
                  : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder:
                        (context, index) =>
                            const Divider(height: 1, thickness: 1),
                    itemBuilder: (context, index) {
                      final schoolClass = filtered[index];
                      final color = ClassColorHelper.getColorForClass(
                        schoolClass.classId,
                      );
                      final studentCount =
                          studentCounts?[schoolClass.classId] ??
                          schoolClass.studentCount;
                      final attendanceCount =
                          attendanceCounts?[schoolClass.classId] ?? 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Text(schoolClass.name[0]),
                        ),
                        title: Text(schoolClass.fullName),
                        subtitle: Text('Section: ${schoolClass.section}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Students: $studentCount',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Marked: $attendanceCount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        selected: selectedClassId == schoolClass.classId,
                        onTap: () => onClassSelected(schoolClass),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
