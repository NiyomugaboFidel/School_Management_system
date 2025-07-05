import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/models/student.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class StudentList extends StatefulWidget {
  final List<Student> students;
  final Map<int, String> attendanceStatus;
  final void Function(Student, String) onMarkAttendance;

  const StudentList({
    Key? key,
    required this.students,
    required this.attendanceStatus,
    required this.onMarkAttendance,
  }) : super(key: key);

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.students
            .where(
              (s) =>
                  s.fullName.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  s.regNumber.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search students...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => searchQuery = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final student = filtered[i];
              final status = widget.attendanceStatus[student.studentId];
              return Card(
                child: ListTile(
                  title: Text(student.fullName),
                  subtitle: Text(student.regNumber),
                  trailing:
                      status != null
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(label: Text(status)),
                              TextButton(
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder:
                                        (context) => Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                Icons.check_circle,
                                                color: AppColors.success,
                                              ),
                                              title: const Text('Present'),
                                              onTap: () {
                                                widget.onMarkAttendance(
                                                  student,
                                                  'Present',
                                                );
                                                Navigator.pop(context);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.access_time,
                                                color: AppColors.warning,
                                              ),
                                              title: const Text('Late'),
                                              onTap: () {
                                                widget.onMarkAttendance(
                                                  student,
                                                  'Late',
                                                );
                                                Navigator.pop(context);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.cancel,
                                                color: AppColors.error,
                                              ),
                                              title: const Text('Absent'),
                                              onTap: () {
                                                widget.onMarkAttendance(
                                                  student,
                                                  'Absent',
                                                );
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              ),
                            ],
                          )
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                onPressed:
                                    () => widget.onMarkAttendance(
                                      student,
                                      'Present',
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.access_time,
                                  color: AppColors.warning,
                                ),
                                onPressed:
                                    () => widget.onMarkAttendance(
                                      student,
                                      'Late',
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: AppColors.error,
                                ),
                                onPressed:
                                    () => widget.onMarkAttendance(
                                      student,
                                      'Absent',
                                    ),
                              ),
                            ],
                          ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
