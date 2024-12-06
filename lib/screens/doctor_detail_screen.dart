import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const DoctorDetailScreen(
      {Key? key, required this.doctorId, required this.doctorData})
      : super(key: key);

  @override
  _DoctorDetailScreenState createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableDates();
  }

  Future<void> _fetchAvailableDates() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('freeDates')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('isReserved', isEqualTo: false)
          .get();

      setState(() {
        _availableDates = snapshot.docs
            .map((doc) => {
                  'dateTime': (doc['dateTime'] as Timestamp).toDate(),
                  'docId': doc.id,
                })
            .toList();
      });
    } catch (e) {
      print('Error al recuperar fechas: $e');
    }
  }

  Future<void> _reserveDate(DateTime dateTime, String docId) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user!.uid,
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorData['name'] ?? 'Doctor',
        'date': dateTime,
      });

      await FirebaseFirestore.instance
          .collection('freeDates')
          .doc(docId)
          .update({
        'isReserved': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha reservada correctamente')),
      );

      // Actualizar las fechas disponibles después de reservar una
      _fetchAvailableDates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorData['specialty'] ?? 'Especialidad'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.doctorData['imageUrl'] != null
                      ? NetworkImage(widget.doctorData['imageUrl'])
                      : null,
                  radius: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.doctorData['name'] ?? 'Nombre del Doctor',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(widget.doctorData['description'] ??
                'Descripción no disponible'),
            const SizedBox(height: 20),
            const Text(
              'Fechas Disponibles:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _availableDates.length,
                itemBuilder: (context, index) {
                  final dateTime = _availableDates[index]['dateTime'];
                  final docId = _availableDates[index]['docId'];
                  return ListTile(
                    title: Text(
                        '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}'),
                    trailing: ElevatedButton(
                      onPressed: () => _reserveDate(dateTime, docId),
                      child: const Text('Reservar'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
