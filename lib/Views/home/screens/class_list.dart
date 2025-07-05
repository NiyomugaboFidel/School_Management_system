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
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search class name...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onSearchChanged,
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
