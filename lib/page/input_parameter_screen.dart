import 'package:flutter/material.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';

// Layar untuk input parameter berat badan dan tas sebelum memulai pendakian
class InputParameterScreen extends StatefulWidget {
  const InputParameterScreen({super.key});

  @override
  State<InputParameterScreen> createState() => _InputParameterScreenState();
}

// Kelas State untuk mengelola input parameter pendakian
class _InputParameterScreenState extends State<InputParameterScreen> {
  // Pengontrol untuk input berat badan pengguna dalam kilogram
  final _bodyWeightController = TextEditingController();
  // Pengontrol untuk input berat tas/perlengkapan dalam kilogram
  final _bagWeightController = TextEditingController();

  // Membersihkan pengontrol saat widget dihapus dari memori
  @override
  void dispose() {
    _bodyWeightController.dispose();
    _bagWeightController.dispose();
    super.dispose();
  }

  // Membangun tampilan form input parameter pendakian
  @override
  Widget build(BuildContext context) {
    // Mengambil argumen gunung dan jalur dari navigasi sebelumnya
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final mountain = args?['mountain'] as Mountain?;
    final route = args?['route'] as HikingRoute?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Input Parameter',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card jalur yang dipilih
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 16,
                  right: 16,
                  bottom: 10,
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jalur yang dipilih:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${route?.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Body Weight Input
              const Text(
                'Berat Badan (kg):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _bodyWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 70',
                    hintStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.25), // bisa ubah ke grey[500], grey[400], dll
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    prefixIcon: const Icon(Icons.monitor_weight, size: 20),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Bag Weight Input
              const Text(
                'Berat Tas (kg)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _bagWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 15',
                    hintStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.25), // bisa ubah ke grey[500], grey[400], dll
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    prefixIcon: const Icon(Icons.backpack, size: 20),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Tombol untuk memulai pendakian setelah memasukkan parameter
              // ketika ditekan akan memvalidasi input dan melanjutkan ke
              // layar peta dengan membawa data yang dimasukkan.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final bodyWeightText = _bodyWeightController.text.trim();
                    final bagWeightText = _bagWeightController.text.trim();

                    if (bodyWeightText.isEmpty || bagWeightText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan isi semua parameter'),
                        ),
                      );
                      return;
                    }

                    final bodyWeight = double.tryParse(bodyWeightText);
                    final bagWeight = double.tryParse(bagWeightText);

                    if (bodyWeight == null || bagWeight == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Masukkan angka yang valid untuk berat badan dan berat tas'),
                        ),
                      );
                      return;
                    }

                    if (bodyWeight < 56 || bodyWeight > 68) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berat badan harus di antara 56 kg dan 68 kg'),
                        ),
                      );
                      return;
                    }

                    if (bagWeight < 0 || bagWeight > 15) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berat tas harus di antara 0 kg dan 15 kg'),
                        ),
                      );
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      '/hiking-map',
                      arguments: {
                        'mountain': mountain,
                        'route': route,
                        'bodyWeight': bodyWeight,
                        'bagWeight': bagWeight,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Mulai Pendakian',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
