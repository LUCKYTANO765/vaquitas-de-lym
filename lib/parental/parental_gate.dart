import 'dart:math';
import 'package:flutter/material.dart';

class ParentalGate extends StatefulWidget {
  final Widget destination;

  const ParentalGate({super.key, required this.destination});

  @override
  State<ParentalGate> createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  late int num1;
  late int num2;
  late int correctAnswer;
  final TextEditingController _controller = TextEditingController();
  String _message = 'Solo para adultos: Resuelve para continuar';

  @override
  void initState() {
    super.initState();
    _generateChallenge();
  }

  void _generateChallenge() {
    final random = Random();
    num1 = random.nextInt(10) + 5; // 5-15
    num2 = random.nextInt(10) + 2; // 2-12
    correctAnswer = num1 + num2;
  }

  void _verify() {
    final userAnswer = int.tryParse(_controller.text);
    if (userAnswer == correctAnswer) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.destination),
      );
    } else {
      setState(() {
        _message = 'Incorrecto. Intenta de nuevo.';
        _controller.clear();
        _generateChallenge();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                '$num1 + $num2 = ?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Resultado',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCELAR'),
                  ),
                  ElevatedButton(
                    onPressed: _verify,
                    child: const Text('ENTRAR'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
