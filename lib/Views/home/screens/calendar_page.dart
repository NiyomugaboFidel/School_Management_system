import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/event.dart';
import '../../../services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final EventService eventService;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    eventService = EventService(firestore: FirebaseFirestore.instance);
    eventService.getEvents().listen((eventList) {
      setState(() {
        _events = {};
        for (var event in eventList) {
          final day = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          _events.putIfAbsent(day, () => []).add(event);
        }
      });
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addEvent() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<Event>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Event'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final event = Event(
                    id: '',
                    title: titleController.text,
                    description: descController.text,
                    date: _selectedDay ?? _focusedDay,
                  );
                  Navigator.pop(context, event);
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
    if (result != null) {
      await eventService.addEvent(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar')),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          Expanded(
            child: ListView(
              children:
                  _getEventsForDay(_selectedDay ?? _focusedDay)
                      .map(
                        (event) => ListTile(
                          title: Text(event.title),
                          subtitle: Text(event.description),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await eventService.deleteEvent(event.id);
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: Icon(Icons.add),
      ),
    );
  }
}
