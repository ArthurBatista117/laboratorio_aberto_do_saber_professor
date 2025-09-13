import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ManageAlarmsScreen extends StatefulWidget {
  const ManageAlarmsScreen({super.key});

  @override
  State<ManageAlarmsScreen> createState() => _ManageAlarmsScreenState();
}

class _ManageAlarmsScreenState extends State<ManageAlarmsScreen> {
  List<AlarmData> alarms = [];
  List<String> weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getStringList('saved_alarms') ?? [];
      
      print('Carregando alarmes: ${alarmsJson.length} encontrados'); // Debug
      
      List<AlarmData> loadedAlarms = [];
      for (String json in alarmsJson) {
        try {
          final alarm = AlarmData.fromJson(jsonDecode(json));
          loadedAlarms.add(alarm);
          print('Alarme carregado: ${alarm.timeFormatted}'); // Debug
        } catch (e) {
          print('Erro ao carregar alarme: $e'); // Debug
        }
      }
      
      // Ordena os alarmes por horário
      loadedAlarms.sort((a, b) {
        final timeA = _parseTimeFromString(a.timeFormatted);
        final timeB = _parseTimeFromString(b.timeFormatted);
        return timeA.compareTo(timeB);
      });
      
      setState(() {
        alarms = loadedAlarms;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar alarmes: $e');
      setState(() {
        alarms = [];
        _isLoading = false;
      });
    }
  }

  // Converte string de tempo para comparação
  int _parseTimeFromString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return 0;
    
    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _deleteAlarm(int index) async {
    final alarmToDelete = alarms[index];
    
    try {
      // Para cada dia ativo no alarme, remove o alarme correspondente
      for (int dayIndex = 0; dayIndex < alarmToDelete.selectedDays.length; dayIndex++) {
        if (alarmToDelete.selectedDays[dayIndex]) {
          await Alarm.stop(dayIndex + 1);
          print('Alarme parado para o dia $dayIndex'); // Debug
        }
      }

      setState(() {
        alarms.removeAt(index);
      });

      await _saveAlarms();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alarme removido com sucesso!'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Desfazer',
            textColor: Colors.white,
            onPressed: () => _undoDeleteAlarm(alarmToDelete, index),
          ),
        ),
      );
    } catch (e) {
      print('Erro ao deletar alarme: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao remover alarme. Tente novamente.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Função para desfazer a exclusão
  Future<void> _undoDeleteAlarm(AlarmData alarm, int index) async {
    setState(() {
      alarms.insert(index, alarm);
    });
    await _saveAlarms();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Alarme restaurado!'),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteAllAlarms() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text(
            'Tem certeza que deseja excluir todos os ${alarms.length} alarmes?',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performDeleteAll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir Todos'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteAll() async {
    try {
      // Para todos os alarmes ativos
      await Alarm.stopAll();
      print('Todos os alarmes foram parados'); // Debug
      
      final deletedCount = alarms.length;
      
      setState(() {
        alarms.clear();
      });
      
      await _saveAlarms();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedCount alarmes foram removidos!'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Erro ao deletar todos os alarmes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao remover alarmes. Tente novamente.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
      await prefs.setStringList('saved_alarms', alarmsJson);
      print('${alarms.length} alarmes salvos'); // Debug
    } catch (e) {
      print('Erro ao salvar alarmes: $e');
    }
  }

  String _getActiveDaysText(List<bool> selectedDays) {
    List<String> activeDays = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        activeDays.add(weekDays[i]);
      }
    }
    
    if (activeDays.isEmpty) return 'Nenhum dia selecionado';
    if (activeDays.length == 7) return 'Todos os dias';
    return activeDays.join(', ');
  }

  // Função para atualizar a lista quando voltar de outras telas
  Future<void> _refreshAlarms() async {
    await _loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Retorna informação sobre mudanças quando sair da tela
        Navigator.pop(context, 'alarm_list_updated');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          title: Text(
            'Gerenciar Alarmes (${alarms.length})',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context, 'alarm_list_updated'),
          ),
          actions: [
            if (alarms.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshAlarms,
                tooltip: 'Atualizar lista',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _deleteAllAlarms,
                tooltip: 'Excluir todos os alarmes',
              ),
            ],
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : alarms.isEmpty
                ? _buildEmptyState()
                : _buildAlarmsList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando alarmes...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.alarm_off,
              size: 60,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum alarme configurado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Configure seus primeiros lembretes\npara não esquecer das notificações',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'create_new_alarm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Criar Novo Alarme',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmsList() {
    return RefreshIndicator(
      onRefresh: _refreshAlarms,
      color: Colors.blue[600],
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com horário e botão de excluir
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm.timeFormatted,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Criado em ${_formatDate(alarm.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteDialog(index);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir'),
                                ],
                              ),
                            ),
                          ];
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Dias da semana
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getActiveDaysText(alarm.selectedDays),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tipos de notificação
                  Row(
                    children: [
                      if (alarm.whatsappNotification) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (alarm.alarmSound) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.volume_up,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Sonoro',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!alarm.whatsappNotification && !alarm.alarmSound) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Sem notificação',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deseja excluir o alarme de ${alarms[index].timeFormatted}?'),
              const SizedBox(height: 8),
              Text(
                'Dias ativos: ${_getActiveDaysText(alarms[index].selectedDays)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAlarm(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}

class AlarmData {
  final String timeFormatted;
  final List<bool> selectedDays;
  final bool whatsappNotification;
  final bool alarmSound;
  final DateTime createdAt;

  AlarmData({
    required this.timeFormatted,
    required this.selectedDays,
    required this.whatsappNotification,
    required this.alarmSound,
    required this.createdAt,
  });

  factory AlarmData.fromJson(Map<String, dynamic> json) {
    return AlarmData(
      timeFormatted: json['timeFormatted'],
      selectedDays: List<bool>.from(json['selectedDays']),
      whatsappNotification: json['whatsappNotification'],
      alarmSound: json['alarmSound'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeFormatted': timeFormatted,
      'selectedDays': selectedDays,
      'whatsappNotification': whatsappNotification,
      'alarmSound': alarmSound,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}