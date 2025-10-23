import 'package:flutter/material.dart';
import 'dart:math'; // Necessário para a função max
import 'dart:async'; // Necessário para o Timer

// ==================================================
// MODELOS DE DADOS
// ==================================================

/// Identificadores fixos de categoria
enum CategoryId { chefia, padeiro, funcionario }

/// Modelo que contém metadados de cada categoria
class Category {
  final CategoryId id;
  final String label;
  final String letter;
  final Color color;

  const Category({
    required this.id,
    required this.label,
    required this.letter,
    required this.color,
  });
}

/// Mapa global de categorias
final Map<CategoryId, Category> categories = {
  CategoryId.chefia: Category(
    id: CategoryId.chefia,
    label: 'Chefia',
    letter: 'C',
    color: Colors.redAccent.shade700,
  ),
  CategoryId.padeiro: Category(
    id: CategoryId.padeiro,
    label: 'Padeiro',
    letter: 'P',
    color: Colors.orange.shade600,
  ),
  CategoryId.funcionario: Category(
    id: CategoryId.funcionario,
    label: 'Funcionário',
    letter: 'F',
    color: Colors.green.shade600,
  ),
};

class BreakPeriod {
  final TimeOfDay start;
  final TimeOfDay end;
  final String? label;

  BreakPeriod({
    required this.start,
    required this.end,
    this.label,
  });

  Duration get duration {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return Duration(minutes: endMinutes - startMinutes);
  }

  Map<String, dynamic> toJson() => {
        'start': {'h': start.hour, 'm': start.minute},
        'end': {'h': end.hour, 'm': end.minute},
        'label': label,
      };
}

class Shift {
  final String name;
  final TimeOfDay start;
  final TimeOfDay end;
  final int column;
  final CategoryId category;
  final List<BreakPeriod> breaks;

  const Shift({
    required this.name,
    required this.start,
    required this.end,
    required this.column,
    required this.category,
    this.breaks = const [],
  });

  // GETTER para a cor baseada na categoria
  Color get color => categories[category]!.color;

  // NOVO: Getter para as iniciais do nome
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0].toUpperCase()}${parts.last[0].toUpperCase()}';
  }

  Duration get netDuration {
    final total = Duration(
      minutes: (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute),
    );
    final breaksTotal =
        breaks.fold<Duration>(Duration.zero, (sum, b) => sum + b.duration);
    return total - breaksTotal;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'start': {'h': start.hour, 'm': start.minute},
        'end': {'h': end.hour, 'm': end.minute},
        'column': column,
        'category': category.name,
        'breaks': breaks.map((b) => b.toJson()).toList(),
      };
}

// ==================================================
// UTILITÁRIOS
// ==================================================

class TimeUtils {
  // Intervalo total do calendário
  static const int startHour = 1; // hora inicial (4:00)
  static const int endHour = 23; // hora final (23:00)
  static const double quarterHeight = 24; // altura de cada bloco de 15 min

  /// Converte um TimeOfDay em um deslocamento vertical (px)
  static double timeToOffset(TimeOfDay time) {
    final totalMinutes = (time.hour * 60 + time.minute) - (startHour * 60);
    final quarterCount = totalMinutes / 15;

    // Evita valores negativos (antes das 4h00)
    return (quarterCount * quarterHeight) > 0 ? quarterCount * quarterHeight : 0;
  }

  /// Converte duração (start → end) em altura (px)
  static double durationToHeight(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final duration = (endMinutes - startMinutes) > 0 ? (endMinutes - startMinutes) : 0;

    // 15 minutos = quarterHeight px
    return (duration / 15) * quarterHeight;
  }

  /// Garante que um horário está dentro do intervalo 4:00 → 23:00
  static TimeOfDay clamp(TimeOfDay time) {
    if (time.hour < startHour) return const TimeOfDay(hour: 1, minute: 0);
    if (time.hour >= endHour) return const TimeOfDay(hour: 23, minute: 0);
    return time;
  }
}

// ==================================================
// CONTROLADORES
// ==================================================

class ScheduleController {
  // NOVO: Implementação do Singleton pattern simples
  static final ScheduleController _instance = ScheduleController._internal();
  factory ScheduleController() => _instance;
  ScheduleController._internal();

  List<Shift> loadShifts() {
    return [
      // 🔴 Chefia
      Shift(
        name: 'Ana Rocha',
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 16, minute: 0),
        column: 0,
        category: CategoryId.chefia,
        breaks: [
          BreakPeriod(
            start: const TimeOfDay(hour: 12, minute: 30),
            end: const TimeOfDay(hour: 13, minute: 0),
            label: 'Almoço',
          ),
        ],
      ),
      Shift(
        name: 'Carlos Mendes',
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 0),
        column: 1,
        category: CategoryId.chefia,
        breaks: [
          BreakPeriod(
            start: const TimeOfDay(hour: 12, minute: 30),
            end: const TimeOfDay(hour: 13, minute: 0),
            label: 'Almoço',
          ),
        ],
      ),

      // 🟠 Padeiro
      Shift(
        name: 'João Pereira',
        start: const TimeOfDay(hour: 5, minute: 30),
        end: const TimeOfDay(hour: 13, minute: 30),
        column: 2,
        category: CategoryId.padeiro,
        breaks: [
          BreakPeriod(
            start: const TimeOfDay(hour: 9, minute: 0),
            end: const TimeOfDay(hour: 9, minute: 30),
            label: 'Almoço',
          ),
        ],
      ),
      Shift(
        name: 'Marta Santos',
        start: const TimeOfDay(hour: 6, minute: 0),
        end: const TimeOfDay(hour: 14, minute: 0),
        column: 3,
        category: CategoryId.padeiro,
        breaks: [
          BreakPeriod(
            start: const TimeOfDay(hour: 10, minute: 0),
            end: const TimeOfDay(hour: 10, minute: 30),
            label: 'Almoço',
          ),
        ],
      ),

      // 🟢 Funcionário
      Shift(
        name: 'Neusa Silva',
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 16, minute: 0),
        column: 4,
        category: CategoryId.funcionario,
        breaks: [
          BreakPeriod(
            start: const TimeOfDay(hour: 12, minute: 30),
            end: const TimeOfDay(hour: 13, minute: 0),
            label: 'Almoço',
          ),
        ],
      ),
      Shift(
        name: 'José Almeida',
        start: const TimeOfDay(hour: 7, minute: 30),
        end: const TimeOfDay(hour: 15, minute: 30),
        column: 5,
        category: CategoryId.funcionario,
        breaks: [
          BreakPeriod(
            start: const TimeOfDay(hour: 11, minute: 30),
            end: const TimeOfDay(hour: 12, minute: 0),
            label: 'Almoço',
          ),
        ],
      ),
      Shift(
        name: 'Noite Passada',
        start: const TimeOfDay(hour: 22, minute: 0),
        end: const TimeOfDay(hour: 6, minute: 0),
        column: 6,
        category: CategoryId.padeiro,
      ),
    ];
  }
}

// ==================================================
// WIDGETS PRINCIPAIS
// ==================================================

class ShiftCard extends StatelessWidget {
  final Shift shift;
  const ShiftCard({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: shift.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class TopAppBar extends StatelessWidget {
  const TopAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
          const Expanded(
            child: Center(
              child: Text(
                'Turnos Diários',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () {}),
        ],
      ),
    );
  }
}

class SegmentedButtons extends StatelessWidget {
  const SegmentedButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            Expanded(child: _Segment(label: 'My Schedule', selected: true)),
            SizedBox(width: 6),
            Expanded(child: _Segment(label: 'All')),
            SizedBox(width: 6),
            Expanded(child: _Segment(label: 'Teams')),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;

  const _Segment({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: selected
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06), blurRadius: 6)
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.black : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class CategoryLegend extends StatelessWidget {
  const CategoryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    final items = categories.values.map((cat) {
      return _LegendItem(
        color: cat.color,
        label: '${cat.letter} = ${cat.label}',
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: item,
                      ))
                  .toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items,
            ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class TimeColumn extends StatelessWidget {
  // NOVO: Controller para sincronização
  final ScrollController? scrollController; 
  const TimeColumn({super.key, this.scrollController}); // Atualizado

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      color: Colors.grey.shade100,
      child: ListView.builder(
        // NOVO: Usar o controller para sincronizar com ScheduleGrid
        controller: scrollController, 
        itemCount: (TimeUtils.endHour - TimeUtils.startHour) * 4,
        itemBuilder: (context, index) {
          final totalMinutes = index * 15;
          final hour = totalMinutes ~/ 60 + TimeUtils.startHour;
          final minute = totalMinutes % 60;
          final isHour = minute == 0;
          final isHalf = minute == 30;

          return Container(
            height: TimeUtils.quarterHeight,
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isHalf ? Colors.grey.shade600 : Colors.grey.shade300,
                  width: isHalf ? 1.2 : 0.6,
                ),
              ),
            ),
            child: isHour
                ? Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text('${hour.toString().padLeft(2, '0')}h',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class ScheduleGrid extends StatefulWidget {
  final List<Shift> shifts;
  // NOVO: Controller vertical externo
  final ScrollController verticalScrollController;

  const ScheduleGrid({
    super.key, 
    required this.shifts, 
    required this.verticalScrollController, // Atualizado
  });

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  // REMOVIDO: final ScrollController _scrollController = ScrollController();
  final Map<int, double> _avatarPositions = {};
  Timer? _timer; // NOVO: Timer para atualizações em tempo real
  TimeOfDay _currentTime = TimeOfDay.now(); // NOVO: Hora atual

  @override
  void initState() {
    super.initState();
    // Usa o controller passado pelo widget pai
    widget.verticalScrollController.addListener(_updateAvatarPositions);
    _startTimer(); // Inicia o timer para atualização em tempo real
  }
  
  // NOVO: Método para iniciar o timer
  void _startTimer() {
    // Atualiza a cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = TimeOfDay.now(); 
        });
      }
    });
  }

  void _updateAvatarPositions() {
    setState(() {
      for (final shift in widget.shifts) {
        final shiftHeight = TimeUtils.durationToHeight(shift.start, shift.end);
        final avatarSize = (_getColumnWidth() - 12) * 0.5;
        
        // Usa o offset do controller do widget
        double avatarY = widget.verticalScrollController.offset;
        avatarY = avatarY.clamp(0, shiftHeight - avatarSize);
        
        _avatarPositions[shift.hashCode] = avatarY;
      }
    });
  }

  // Atualizado: Usar largura fixa para permitir scroll horizontal
  double _getColumnWidth() {
    return 100.0; 
  }

  @override
  void dispose() {
    // Não dispor o controller que foi passado
    _timer?.cancel(); // Cancela o timer
    super.dispose();
  }
  
  // NOVO: Método de Contagem de Staff
  Map<CategoryId, int> _getCurrentStaffCount(TimeOfDay currentTime) {
    final Map<CategoryId, int> counts = {
      CategoryId.chefia: 0,
      CategoryId.padeiro: 0,
      CategoryId.funcionario: 0,
    };

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;

    for (final shift in widget.shifts) {
      final startMinutes = shift.start.hour * 60 + shift.start.minute;
      final endMinutes = shift.end.hour * 60 + shift.end.minute;
      
      // Lógica para turnos que atravessam a meia-noite (00:00)
      bool isOvernight = startMinutes > endMinutes;

      if (isOvernight) {
        // Se a hora atual estiver entre o início e 23:59, OU entre 00:00 e o fim.
        if (currentMinutes >= startMinutes || currentMinutes < endMinutes) {
          counts[shift.category] = (counts[shift.category] ?? 0) + 1;
        }
      } else {
        // Turno normal
        if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
          counts[shift.category] = (counts[shift.category] ?? 0) + 1;
        }
      }
    }

    return counts;
  }
  
  // NOVO: Método para construir o Painel de Métricas em Tempo Real (A Nova Coluna)
  Widget _buildCurrentStaffPanel(Map<CategoryId, int> counts, double totalHeight) {
    // Garantir que a largura total é suficiente para todas as colunas
    final maxColumn = widget.shifts.map((s) => s.column).reduce((a, b) => a > b ? a : b) + 1;
    final totalWidth = maxColumn * _getColumnWidth();
    
    // 1. Formatar o texto de contagem (C:X P:Y F:Z)
    final String metricsText = 
        'C:${counts[CategoryId.chefia]} '
        'P:${counts[CategoryId.padeiro]} '
        'F:${counts[CategoryId.funcionario]}';

    final double panelWidth = _getColumnWidth(); 
    final double textTopOffset = widget.verticalScrollController.offset;
    final double timeLineTop = TimeUtils.timeToOffset(_currentTime);

    return Positioned(
      left: 0,
      top: 0, 
      width: totalWidth, 
      height: totalHeight,
      child: Stack(
        children: [
          // A. Coluna Vertical Translúcida (Plano de Fundo)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: panelWidth,
            child: Container(
              color: Colors.blue.withOpacity(0.15), // Cor translúcida
            ),
          ),
          
          // B. Linha de tempo atual (Move-se com o tempo)
          Positioned(
            top: timeLineTop,
            left: 0,
            right: 0,
            child: Container(
              height: 1.5,
              color: Colors.red,
            ),
          ),
          
          // C. Texto Flutuante de Métricas (Move-se com o scroll)
          Positioned(
            top: textTopOffset, 
            left: 0,
            child: Container(
              width: panelWidth,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8), // Fundo mais opaco para o texto
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(8)),
              ),
              child: Text(
                metricsText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final totalQuarters = (TimeUtils.endHour - TimeUtils.startHour) * 4;
    final contentHeight = totalQuarters * TimeUtils.quarterHeight;
    final columnWidth = _getColumnWidth();
    
    // Calcula a largura total do conteúdo para o scroll horizontal
    final maxColumn = widget.shifts.map((s) => s.column).reduce((a, b) => a > b ? a : b) + 1;
    final totalWidth = maxColumn * columnWidth; 

    final currentStaffCounts = _getCurrentStaffCount(_currentTime); // Contagem em tempo 
