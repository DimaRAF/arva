// medication_approval_listener.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MedicationApprovalListener {
  MedicationApprovalListener._internal();
  static final MedicationApprovalListener instance =
      MedicationApprovalListener._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

 
  final Map<String, String?> _lastStatuses = {};

  bool _initialized = false;

  Future<void> initNotifications() async {
    if (_initialized) return;

  
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;
  }

  
  Future<void> startListening() async {
    await initNotifications();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠ لا يوجد مستخدم مسجّل (Patient) → لن نفعّل الـ listener');
      return;
    }

    final patientId = user.uid;

   
    await _sub?.cancel();
    _lastStatuses.clear();

    _sub = FirebaseFirestore.instance
        .collection('patient_profiles')
        .doc(patientId)
        .collection('medications')
        .snapshots()
        .listen(
      (snapshot) {
        
        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final data = doc.data();
          if (data == null) continue;

          final String docId = doc.id;
          final String? status = data['status'] as String?;

          if (change.type == DocumentChangeType.added) {
            
            _lastStatuses[docId] = status;
          } else if (change.type == DocumentChangeType.modified) {
            final prevStatus = _lastStatuses[docId];

          
            _lastStatuses[docId] = status;

            
            if (status == 'Approved' && prevStatus != 'Approved') {
              final drugName = (data['drug_name'] ?? 'your medication').toString();
              _showPatientMedicationApprovedNotification(
                patientId: patientId,
                medicationId: docId,
                drugName: drugName,
              );
            }
          } else if (change.type == DocumentChangeType.removed) {
            _lastStatuses.remove(docId);
          }
        }
      },
      onError: (e) {
        print('❌ MedicationApprovalListener error: $e');
      },
    );
  }

  Future<void> stopListening() async {
    await _sub?.cancel();
    _sub = null;
    _lastStatuses.clear();
  }

 
  Future<void> _showPatientMedicationApprovedNotification({
    required String patientId,
    required String medicationId,
    required String drugName,
  }) async {
    String patientName = 'you';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(patientId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          patientName =
              (data['username'] ?? data['name'] ?? patientName).toString();
        }
      }
    } catch (e) {
      print('⚠ Failed to load patient name for notification: $e');
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'patient_medication_updates',
      'Patient Medication Updates',
      channelDescription:
          'Notifies the patient when the doctor approves medication doses',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    
    final int notifId = medicationId.hashCode & 0x7FFFFFFF;

    await _notificationsPlugin.show(
      notifId,
      '✅ Medication Approved',
      'Your doctor has approved the dose for $drugName, $patientName.',
      notificationDetails,
      payload: jsonEncode({
        'type': 'medication_approved',
        'patientId': patientId,
        'medicationId': medicationId,
        'patientName': patientName,
      }),
    );
  }
}
