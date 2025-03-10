import 'package:flutter/material.dart';
import 'package:focus/module/pwm/controller/pwm_controller.dart';

class PwmView extends StatefulWidget {
  const PwmView({super.key});

  @override
  State<PwmView> createState() => _PwmViewState();
}

class _PwmViewState extends State<PwmView> {
  final _c = PwmController();

  @override
  void initState() {
    super.initState();
    // Inicializamos el tiempo con la duración de enfoque
    _c.timeLeft = _c.duty * 60;
  }

  @override
  void dispose() {
    _c.timer?.cancel();
    super.dispose();
  }

  /// Formato mm:ss
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return "$mm:$ss";
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: _c.currentBgColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: SafeArea(
              child: Column(
                children: [
                  // Encabezado
                  _buildHeader(),
        
                  const SizedBox(height: 20),
        
                  // "Diagrama PWM" que muestra Periodo, y la relación Enfoque/Descanso
                  _buildPwmDiagram(),
        
                  // Sliders (solo si no está corriendo)
                  const SizedBox(height: 20),
                  if (!_c.isRunning) _buildSliders(),
        
                  // Cronómetro y label "enfoque" / "descanso"
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _labelEnfoqueDescanso(),
                          const SizedBox(height: 16),
                          // Cronómetro en grande, con animación SOLO en descanso
                          _buildTimerText(),
                          const SizedBox(height: 16),
                          // Ciclos completados
                          Text(
                            "Ciclos completados: ${_c.cycleCount}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
        
                  // Botón Iniciar/Detener
                  ElevatedButton(
                    onPressed: _c.toggleTimer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _c.isRunning ? "Detener" : "Iniciar",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  /// Cabecera con título y estado (En ejecución/Detenido)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Enfócate',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _c.isRunning
                ? Colors.lightGreen.shade400
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _c.isRunning ? "En Ejecución" : "Detenido",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Diagrama de PWM (barra dividida en dos segmentos):
  ///  - Verde para el duty (enfoque)
  ///  - Azul para el descanso
  Widget _buildPwmDiagram() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Periodo total: ${_c.period} min",
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Barra que muestra la proporción (duty vs rest)
            Row(
              children: [
                Expanded(
                  flex: _c.duty,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: _c.focusColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(8),
                        bottomLeft: const Radius.circular(8),
                        topRight: _c.rest == 0
                            ? const Radius.circular(8)
                            : Radius.zero,
                        bottomRight: _c.rest == 0
                            ? const Radius.circular(8)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: _c.rest,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: _c.restColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text("Enfoque: ${_c.duty} min | Descanso: ${_c.rest} min"),
          ],
        ),
      ),
    );
  }

  /// Sliders para Enfoque y Descanso
  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderCard(
          title: "Enfoque",
          value: _c.duty,
          min: 1,
          max: 60,
          onChanged: (val) {
            setState(() {
              _c.duty = val.round();
              // Si estamos detenidos, actualizamos timeLeft
              _c.timeLeft = _c.duty * 60;
            });
          },
        ),
        _buildSliderCard(
          title: "Descanso",
          value: _c.rest,
          min: 1,
          max: 60,
          onChanged: (val) {
            setState(() {
              _c.rest = val.round();
            });
          },
        ),
      ],
    );
  }

  /// Reutilizamos un componente card para cada slider
  Widget _buildSliderCard({
    required String title,
    required int value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$title: $value min",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Slider(
              value: value.toDouble(),
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              label: "$value",
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  /// Label de si estamos en Enfoque o Descanso
  Widget _labelEnfoqueDescanso() {
    return Text(
      _c.isFocusing ? "ENFOQUE" : "DESCANSO",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  /// Cronómetro grande. Se anima SOLO si estamos en DESCANSO.
  Widget _buildTimerText() {
    if (_c.isFocusing) {
      // ENFOQUE: Texto sin animación
      return Text(
        _formatTime(_c.timeLeft),
        style: const TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      // DESCANSO: Usamos un AnimatedSwitcher animar.
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          // Efecto Fade + Scale en descanso
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Text(
          _formatTime(_c.timeLeft),
          key: ValueKey<int>(_c.timeLeft),
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}