import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFreeDateScreen extends StatefulWidget {
  const AddFreeDateScreen({Key? key}) : super(key: key);

  @override
  _AddFreeDateScreenState createState() => _AddFreeDateScreenState();
}

class _AddFreeDateScreenState extends State<AddFreeDateScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveFreeDate() async {
    if (_selectedDate != null && _selectedTime != null && user != null) {
      final DateTime dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await FirebaseFirestore.instance.collection('freeDates').add({
        'doctorId': user!.uid,
        'dateTime': dateTime,
        'isReserved': false, // Añadir campo para el estado de la fecha
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha guardada correctamente')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor selecciona una fecha y una hora')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Fecha Libre'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Fecha'),
              subtitle: Text(_selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : 'No se ha seleccionado ninguna fecha.'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            ListTile(
              title: const Text('Hora'),
              subtitle: Text(_selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'No se ha seleccionado ninguna hora.'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _selectTime(context),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveFreeDate,
              child: const Text('Guardar Fecha'),
            ),
          ],
        ),
      ),
    );
  }
}
