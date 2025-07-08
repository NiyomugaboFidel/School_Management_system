import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore firestore;
  EventService({required this.firestore});

  Stream<List<Event>> getEvents() {
    return firestore
        .collection('events')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Event.fromMap(doc.data()..['id'] = doc.id))
                  .toList(),
        );
  }

  Future<void> addEvent(Event event) async {
    await firestore.collection('events').add(event.toMap());
  }

  Future<void> updateEvent(Event event) async {
    await firestore.collection('events').doc(event.id).set(event.toMap());
  }

  Future<void> deleteEvent(String id) async {
    await firestore.collection('events').doc(id).delete();
  }
}
