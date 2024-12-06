import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewReservationsScreen extends StatefulWidget {
  const ViewReservationsScreen({Key? key}) : super(key: key);

  @override
  _ViewReservationsScreenState createState() => _ViewReservationsScreenState();
}

class _ViewReservationsScreenState extends State<ViewReservationsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _deleteReservation(String reservationId) async {
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservación eliminada exitosamente')),
    );
  }

  Future<void> _updateReservation(String reservationId, String doctorId) async {
    List<Map<String, dynamic>> availableDates = [];

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('freeDates')
          .where('doctorId', isEqualTo: doctorId)
          .where('isReserved', isEqualTo: false)
          .get();

      availableDates = snapshot.docs
          .map((doc) => {
                'dateTime': (doc['dateTime'] as Timestamp).toDate(),
                'docId': doc.id,
              })
          .toList();
    } catch (e) {
      print('Error al recuperar fechas: $e');
    }

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay fechas libres disponibles')),
      );
      return;
    }

    DateTime? newDate = await _selectNewDate(context, availableDates);
    if (newDate != null) {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({
        'date': newDate,
      });

      // Marcar la nueva fecha como reservada
      String selectedDocId = availableDates
          .firstWhere((date) => date['dateTime'] == newDate)['docId'];
      await FirebaseFirestore.instance
          .collection('freeDates')
          .doc(selectedDocId)
          .update({
        'isReserved': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservación actualizada exitosamente')),
      );
    }
  }

  Future<DateTime?> _selectNewDate(
      BuildContext context, List<Map<String, dynamic>> availableDates) async {
    DateTime? selectedDate;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Nueva Fecha'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableDates.length,
              itemBuilder: (context, index) {
                final dateTime = availableDates[index]['dateTime'];
                return ListTile(
                  title: Text(
                      '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}'),
                  onTap: () {
                    selectedDate = dateTime;
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
    return selectedDate;
  }

  Future<void> _showReservationDetails(
      BuildContext context, String doctorId) async {
    final DocumentSnapshot doctorSnapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();
    final doctorData = doctorSnapshot.data() as Map<String, dynamic>?;

    if (doctorData != null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title:
                Text(doctorData['specialty'] ?? 'Especialidad no disponible'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                doctorData['imageUrl'] != null
                    ? Image.network(
                        doctorData['imageUrl'],
                        width: 150, // Ajustar ancho de la imagen
                        height: 150, // Ajustar alto de la imagen
                        fit: BoxFit.cover,
                      )
                    : Container(),
                const SizedBox(height: 10),
                Text(doctorData['description'] ??
                    'No hay descripción disponible'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservaciones'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(
                    'Especialidad: ${data['doctorSpecialty'] ?? 'Especialidad no disponible'}'),
                subtitle:
                    Text('Fecha: ${(data['date'] as Timestamp).toDate()}'),
                onTap: () => _showReservationDetails(context, data['doctorId']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteReservation(doc.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _updateReservation(doc.id, data['doctorId']),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
