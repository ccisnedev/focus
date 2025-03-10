import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PwmController extends ChangeNotifier {
  // Sliders para enfoque y descanso
  int duty = 25;  // minutos de enfoque
  int rest = 5;  // minutos de descanso

  // El período es la suma de duty + rest
  int get period => duty + rest;

  bool isRunning = false;
  bool isFocusing = true;
  int _timeLeft = 25 * 60; // en segundos

  int get timeLeft => _timeLeft;
  set timeLeft(int value) {
    _timeLeft = value;
    notifyListeners();
  }

  Timer? timer;

  // Contador de ciclos completados
  int cycleCount = 0;

  // Reproductor de audio (usar package audioplayers)
  final AudioPlayer audioPlayer = AudioPlayer();

  // Para diferenciar colores en fase de enfoque vs. descanso
  final Color focusColor = const Color(0xFFB2FFCE); // Verde suave
  final Color restColor = const Color(0xFFB2EBF2);  // Azul suave

  // Cambiamos color de fondo según estado (enfoque / descanso)
  Color get currentBgColor => isFocusing ? focusColor : restColor;

  /// Reproduce un archivo de audio almacenado en assets/sound/
  Future<void> _playSound(String fileName) async {
    try {
      await audioPlayer.play(AssetSource('sound/$fileName'));
    } on PlatformException catch (e) {
      debugPrint('Error reproduciendo sonido: $e');
    }
  }

  /// Inicia o detiene el cronómetro
  void toggleTimer() {
    if (isRunning) {
      _stopAndReset();
    } else {
      isRunning = true;
      _startCountdown();
    }

    notifyListeners();
  }

  /// Inicia el conteo regresivo
  void _startCountdown() {
    // Reproducir bell al iniciar el enfoque
    _playSound('bell.mp3');

    timer = Timer.periodic(
      const Duration(seconds: 1),
      _timerCallback,
    );
  }

  /// Detiene y reinicia el cronómetro
  void _stopAndReset() {
    timer?.cancel();
    isRunning = false;
    isFocusing = true;
    _timeLeft = duty * 60;
    cycleCount = 0;

    // Detener audio
    audioPlayer.stop();

    notifyListeners();
  }

  void _timerCallback(Timer timer) {
    _timeLeft--;

    if (_timeLeft <= 0) {
      // Se terminó la fase actual
      _timeLeft = rest * 60;

      if (isFocusing) {
        // Terminamos enfoque → Inicia descanso
        isFocusing = false;
        // Reproducir beep al iniciar el descanso
        _playSound('beep.mp3');
      } else {
        // Terminamos descanso → se completa un ciclo y vuelta al enfoque
        cycleCount++;
        isFocusing = true;
        // Reproducir bell al iniciar el enfoque
        _playSound('bell.mp3');
      }
    }
    
    notifyListeners();
  }
}