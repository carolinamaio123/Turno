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

    final currentStaffCounts = _getCurrentStaffCount(_currentTime); // Contagem em tempo real

    return SingleChildScrollView(
      // Usa o controller vertical que foi passado pelo SchedulePage
      controller: widget.verticalScrollController, 
      child: SizedBox(
        width: totalWidth,
        height: contentHeight,
        child: Stack(
          children: [
            Column(
              children: List.generate(
                totalQuarters,
                (i) => Container(
                  height: TimeUtils.quarterHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: ((i * 15) % 60) == 30 
                            ? Colors.grey.shade600 
                            : Colors.grey.shade300,
                        width: ((i * 15) % 60) == 30 ? 1.2 : 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            for (final shift in widget.shifts) 
              _buildShiftWithAvatar(shift, columnWidth),
            
            // NOVO: Adiciona o Painel de Métricas em Tempo Real e a Linha da Hora
            _buildCurrentStaffPanel(currentStaffCounts, contentHeight),

            // REMOVIDO: _buildCurrentTimeIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftWithAvatar(Shift shift, double columnWidth) {
    final shiftHeight = TimeUtils.durationToHeight(shift.start, shift.end);
    final shiftTop = TimeUtils.timeToOffset(shift.start);
    final avatarSize = (columnWidth - 12) * 0.5;
    final avatarTop = _avatarPositions[shift.hashCode] ?? 8;

    return Stack(
      children: [
        Positioned(
          left: shift.column * columnWidth + 6,
          top: shiftTop,
          width: columnWidth - 12,
          height: shiftHeight,
          child: ShiftCard(shift: shift),
        ),
        
        Positioned(
          left: shift.column * columnWidth + 6 + ((columnWidth - 12 - avatarSize) / 2),
          top: shiftTop + avatarTop,
          child: GestureDetector(
            onTap: () => _showInfoPopup(context, shift),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: (avatarSize / 2) - 2,
                  backgroundColor: shift.color,
                  child: Text(
                    shift.initials, // Usa o novo getter
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (avatarSize / 2) * 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showInfoPopup(BuildContext context, Shift shift) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: shift.color,
                    radius: 24,
                    child: Text(
                      shift.initials, // Usa o novo getter
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      shift.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonDetailsPage(shift: shift),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('Ver informações completas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shift.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  // REMOVIDO: Widget _buildCurrentTimeIndicator() {...}
}

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          _item(Icons.home, 'Home', false),
          _item(Icons.calendar_month, 'Schedule', true),
          _item(Icons.mail, 'Requests', false),
          _item(Icons.notifications, 'Notifications', false),
          _item(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, bool active) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.teal : Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.teal : Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ==================================================
// PÁGINA DE DETALHES DA PESSOA (EDITÁVEL)
// ==================================================

class PersonDetailsPage extends StatefulWidget {
  final Shift shift;
  
  const PersonDetailsPage({super.key, required this.shift});

  @override
  State<PersonDetailsPage> createState() => _PersonDetailsPageState();
}

class _PersonDetailsPageState extends State<PersonDetailsPage> {
  String _phoneNumber = '+351 912 345 678';
  String _email = '';
  String _emergencyContact = '+351 913 456 789 (Maria Silva)';
  String _notes = 'Funcionário dedicado e pontual. Excelente trabalho em equipa. Necessita de formação adicional em sistema de gestão.';
  Map<String, String> _weeklySchedule = {
    'Segunda': '09:00 - 17:00',
    'Terça': '09:00 - 17:00',
    'Quarta': 'FOLGA',
    'Quinta': '09:00 - 17:00',
    'Sexta': '09:00 - 17:00',
    'Sábado': '08:00 - 12:00',
    'Domingo': 'FOLGA',
  };
  List<Map<String, dynamic>> _trainings = [
    {'title': 'Segurança no Trabalho', 'status': 'Concluída - 15/03/2024', 'completed': true},
    {'title': 'Atendimento ao Cliente', 'status': 'Concluída - 22/02/2024', 'completed': true},
    {'title': 'Gestão de Stock', 'status': 'Pendente - Prevista Jun/2024', 'completed': false},
    {'title': 'Novo Software ERP', 'status': 'Agendada - 15/05/2024', 'completed': false},
  ];
  List<Map<String, dynamic>> _vacations = [
    {'period': '01 Agosto 2024 - 15 Agosto 2024', 'duration': '15 dias', 'status': 'Aprovado'},
    {'period': '20 Dezembro 2024 - 03 Janeiro 2025', 'duration': '11 dias', 'status': 'Aprovado'},
    {'period': '15 Março 2025 - 22 Março 2025', 'duration': '6 dias', 'status': 'Pendente'},
  ];

  @override
  void initState() {
    super.initState();
    _email = '${widget.shift.name.toLowerCase().replaceAll(' ', '.')}@empresa.pt';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.shift.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(color: widget.shift.color),
            ),
            backgroundColor: widget.shift.color,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _showEditOptions,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          
          SliverList(
            delegate: SliverChildListDelegate([
              _buildHeaderSection(),
              _buildContactSection(),
              _buildCategorySection(),
              _buildWeeklyTimeOffSection(),
              _buildNotesSection(),
              _buildTrainingsSection(),
              _buildEvaluationsSection(),
              _buildVacationsSection(),
              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        backgroundColor: widget.shift.color,
        child: const Icon(Icons.phone, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: widget.shift.color,
            child: Text(
              widget.shift.initials, // Usa o novo getter
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shift.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Horário: ${_formatTime(widget.shift.start)} - ${_formatTime(widget.shift.end)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Duração: ${widget.shift.netDuration.inHours}h',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'Contactos',
      icon: Icons.contact_phone,
      onEdit: () => _editContactInfo(),
      children: [
        _buildContactItem(
          icon: Icons.phone,
          label: 'Telemóvel',
          value: _phoneNumber,
          onTap: () => _makePhoneCall(_phoneNumber),
        ),
        _buildContactItem(
          icon: Icons.email,
          label: 'Email',
          value: _email,
          onTap: () => _sendEmail(_email),
        ),
        _buildContactItem(
          icon: Icons.emergency,
          label: 'Contacto de Emergência',
          value: _emergencyContact,
          onTap: () => _makePhoneCall(_emergencyContact),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final category = categories[widget.shift.category]!;
    
    return _buildSection(
      title: 'Categoria',
      icon: Icons.work,
      children: [
        ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            category.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text('Letra: ${category.letter}'),
          trailing: Chip(
            label: Text(
              category.letter,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: category.color,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTimeOffSection() {
    return _buildSection(
      title: 'Plano de Folgas Semanal',
      icon: Icons.calendar_today,
      onEdit: () => _editWeeklySchedule(),
      children: _weeklySchedule.entries.map((entry) {
        return _buildScheduleDay(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'Notas',
      icon: Icons.note,
      onEdit: () => _editNotes(),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _notes,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingsSection() {
    return _buildSection(
      title: 'Formações',
      icon: Icons.school,
      onEdit: () => _editTrainings(),
      children: _trainings.map((training) {
        return _buildTrainingItem(
          training['title'] as String,
          training['status'] as String,
          training['completed'] as bool ? Icons.check_circle : Icons.pending,
          training['completed'] as bool ? Colors.green : Colors.orange,
        );
      }).toList(),
    );
  }

  Widget _buildEvaluationsSection() {
    return _buildSection(
      title: 'Avaliações',
      icon: Icons.star,
      children: [
        _buildEvaluationItem(
          'Avaliação Trimestral - Mar/2024',
          '4.5/5.0',
          'Excelente desempenho e proatividade',
        ),
        _buildEvaluationItem(
          'Avaliação Anual - 2023',
          '4.2/5.0',
          'Bom trabalho em equipa, áreas de melhoria identificadas',
        ),
        _buildEvaluationItem(
          'Avaliação Trimestral - Dez/2023',
          '4.0/5.0',
          'Progresso consistente, cumpre prazos',
        ),
      ],
    );
  }

  Widget _buildVacationsSection() {
    return _buildSection(
      title: 'Férias Marcadas',
      icon: Icons.beach_access,
      onEdit: () => _editVacations(),
      children: _vacations.map((vacation) {
        return _buildVacationItem(
          vacation['period'] as String,
          vacation['duration'] as String,
          vacation['status'] as String,
          vacation['status'] == 'Aprovado' ? Colors.green : Colors.orange,
        );
      }).toList(),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: widget.shift.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit, color: widget.shift.color, size: 20),
                    onPressed: onEdit,
                  ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: widget.shift.color, size: 22),
      title: Text(label),
      subtitle: Text(value),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildScheduleDay(String day, String schedule) {
    return ListTile(
      leading: Container(
        width: 40,
        alignment: Alignment.center,
        child: Text(
          day.substring(0, 3),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: schedule == 'FOLGA' ? Colors.red : Colors.green,
          ),
        ),
      ),
      title: Text(day),
      trailing: Text(
        schedule,
        style: TextStyle(
          color: schedule == 'FOLGA' ? Colors.red : Colors.green,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTrainingItem(String title, String status, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(status),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
    );
  }

  Widget _buildEvaluationItem(String period, String rating, String comments) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: widget.shift.color.withOpacity(0.2),
        child: Text(
          rating.split('/')[0],
          style: TextStyle(color: widget.shift.color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(period),
      subtitle: Text(comments, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildVacationItem(String period, String duration, String status, Color statusColor) {
    return ListTile(
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(period),
      subtitle: Text(duration),
      trailing: Chip(
        label: Text(
          status,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: statusColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Editar Informações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEditOption(Icons.contact_phone, 'Contactos', _editContactInfo),
            _buildEditOption(Icons.calendar_today, 'Horário Semanal', _editWeeklySchedule),
            _buildEditOption(Icons.note, 'Notas', _editNotes),
            _buildEditOption(Icons.school, 'Formações', _editTrainings),
            _buildEditOption(Icons.beach_access, 'Férias', _editVacations),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: widget.shift.color),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _editContactInfo() {
    final phoneController = TextEditingController(text: _phoneNumber);
    final emailController = TextEditingController(text: _email);
    final emergencyController = TextEditingController(text: _emergencyContact);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Contactos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField('Telemóvel', phoneController, Icons.phone),
              _buildEditField('Email', emailController, Icons.email),
              _buildEditField('Contacto Emergência', emergencyController, Icons.emergency),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _phoneNumber = phoneController.text;
                _email = emailController.text;
                _emergencyContact = emergencyController.text;
              });
              Navigator.pop(context);
              _showSuccessMessage('Contactos atualizados com sucesso!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.shift.color),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editWeeklySchedule() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Horário Semanal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _weeklySchedule.entries.map((entry) {
                  final day = entry.key;
                  final schedule = entry.value;
                  final controller = TextEditingController(text: schedule);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'Ex: 09:00-17:00 ou FOLGA',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                _weeklySchedule[day] = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                  _showSuccessMessage('Horário semanal atualizado!');
                },
                style: ElevatedButton.styleFrom(backgroundColor: widget.shift.color),
                child: const Text('Guardar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editNotes() {
    final notesController = TextEditingController(text: _notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Notas'),
        content: TextFormField(
          controller: notesController,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Escreva as notas aqui...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notes = notesController.text;
              });
              Navigator.pop(context);
              _showSuccessMessage('Notas atualizadas com sucesso!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.shift.color),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editTrainings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerir Formações'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._trainings.asMap().entries.map((entry) {
                final index = entry.key;
                final training = entry.value;
                final titleController = TextEditingController(text: training['title'] as String);
                final statusController = TextEditingController(text: training['status'] as String);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Formação'),
                          onChanged: (value) {
                            _trainings[index]['title'] = value;
                          },
                        ),
                        TextFormField(
                          controller: statusController,
                          decoration: const InputDecoration(labelText: 'Status'),
                          onChanged: (value) {
                            _trainings[index]['status'] = value;
                          },
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: training['completed'] as bool,
                              onChanged: (value) {
                                setState(() {
                                  _trainings[index]['completed'] = value;
                                });
                              },
                            ),
                            const Text('Concluída'),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _trainings.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _trainings.add({
                      'title': 'Nova Formação',
                      'status': 'Pendente',
                      'completed': false,
                    });
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Formação'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
              _showSuccessMessage('Formações atualizadas!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.shift.color),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editVacations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerir Férias'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._vacations.asMap().entries.map((entry) {
                final index = entry.key;
                final vacation = entry.value;
                final periodController = TextEditingController(text: vacation['period'] as String);
                final durationController = TextEditingController(text: vacation['duration'] as String);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: periodController,
                          decoration: const InputDecoration(labelText: 'Período'),
                          onChanged: (value) {
                            _vacations[index]['period'] = value;
                          },
                        ),
                        TextFormField(
                          controller: durationController,
                          decoration: const InputDecoration(labelText: 'Duração'),
                          onChanged: (value) {
                            _vacations[index]['duration'] = value;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: vacation['status'] as String,
                          items: ['Aprovado', 'Pendente', 'Cancelado']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _vacations[index]['status'] = value;
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _vacations.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _vacations.add({
                      'period': 'Nova data - Nova data',
                      'duration': '0 dias',
                      'status': 'Pendente',
                    });
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Férias'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
              _showSuccessMessage('Férias atualizadas!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.shift.color),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // REMOVIDO: String _getInitials(String name) {...}

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _makePhoneCall(String phoneNumber) {
    print('Chamar: $phoneNumber');
  }

  void _sendEmail(String email) {
    print('Enviar email para: $email');
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone, color: widget.shift.color),
              title: const Text('Ligar'),
              onTap: () {
                Navigator.pop(context);
                _makePhoneCall(_phoneNumber);
              },
            ),
            ListTile(
              leading: Icon(Icons.message, color: widget.shift.color),
              title: const Text('Mensagem'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.email, color: widget.shift.color),
              title: const Text('Email'),
              onTap: () {
                Navigator.pop(context);
                _sendEmail(_email);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// PÁGINA PRINCIPAL DO CALENDÁRIO
// ==================================================

// ATUALIZADO para StatefulWidget para gerir o ScrollController
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // NOVO: Controller para sincronizar o scroll vertical
  final ScrollController _verticalScrollController = ScrollController();
  final controller = ScheduleController();
  late final List<Shift> shifts;

  @override
  void initState() {
    super.initState();
    shifts = controller.loadShifts();
  }
  
  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: Column(
          children: [
            const TopAppBar(),
            const SegmentedButtons(),
            const CategoryLegend(),
            Expanded(
              child: Row(
                children: [
                  // Passa o controller para TimeColumn
                  TimeColumn(scrollController: _verticalScrollController),
                  Expanded(
                    // NOVO: Permite scroll horizontal
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ScheduleGrid(
                        shifts: shifts,
                        // Passa o controller para ScheduleGrid
                        verticalScrollController: _verticalScrollController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const BottomNavigation(),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// APLICAÇÃO PRINCIPAL
// ==================================================

class ScheduleApp extends StatelessWidget {
  const ScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'turnos_diarios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const SchedulePage(),
    );
  }
}

void main() {
  runApp(const ScheduleApp());
}
