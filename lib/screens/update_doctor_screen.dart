import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen.dart';

class UpdateDoctorScreen extends StatefulWidget {
  final String doctorId;

  const UpdateDoctorScreen({Key? key, required this.doctorId})
      : super(key: key);

  @override
  _UpdateDoctorScreenState createState() => _UpdateDoctorScreenState();
}

class _UpdateDoctorScreenState extends State<UpdateDoctorScreen> {
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId)
        .get();
    setState(() {
      _specialtyController.text = doc['specialty'];
      _descriptionController.text = doc['description'];
      _imageUrlController.text = doc['imageUrl'];
    });
  }

  Future<void> _updateDoctorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update({
        'specialty': _specialtyController.text,
        'description': _descriptionController.text,
        'imageUrl': _imageUrlController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor actualizado exitosamente')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar doctor: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Doctor'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Especialidad'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: _imageUrlController,
                decoration:
                    const InputDecoration(labelText: 'URL de la Imagen'),
                onChanged: (value) {
                  setState(() {
                    // Actualizar URL de la imagen en tiempo real
                  });
                },
              ),
              const SizedBox(height: 20),
              _imageUrlController.text.isNotEmpty
                  ? Container(
                      constraints: BoxConstraints(
                        maxHeight: 300.0, // Limitar la altura de la imagen
                      ),
                      child: Image.network(_imageUrlController.text,
                          fit: BoxFit.cover),
                    )
                  : const Text('No se ha ingresado una URL de imagen.'),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updateDoctorData,
                      child: const Text('Guardar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
