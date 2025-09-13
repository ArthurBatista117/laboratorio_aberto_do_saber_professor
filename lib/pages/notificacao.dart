import 'package:flutter/material.dart';
import 'package:laboratorio_aberto_do_saber_professor/pages/alarme.dart';
import 'package:laboratorio_aberto_do_saber_professor/services/notificacao_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool whatsappNotification = false;
  TimeOfDay selectedTime = TimeOfDay.now();
  bool alarmSound = false;

  List<bool> selectedDays = [false, false, false, false, false, false, false];
  List<String> weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  void initState() {
    super.initState();
    AlarmService.init();
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // Função para salvar o alarme no SharedPreferences
  Future<void> _saveAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingAlarms = prefs.getStringList('saved_alarms') ?? [];
      
      // Cria o objeto AlarmData
      final newAlarm = AlarmData(
        timeFormatted: selectedTime.format(context),
        selectedDays: List<bool>.from(selectedDays),
        whatsappNotification: whatsappNotification,
        alarmSound: alarmSound,
        createdAt: DateTime.now(),
      );
      
      // Adiciona o novo alarme à lista
      existingAlarms.add(jsonEncode(newAlarm.toJson()));
      
      // Salva a lista atualizada
      await prefs.setStringList('saved_alarms', existingAlarms);
      
      print('Alarme salvo: ${newAlarm.timeFormatted}'); // Debug
    } catch (e) {
      print('Erro ao salvar alarme: $e');
    }
  }

  // Função para validar se pelo menos um dia foi selecionado
  bool _validateSelection() {
    bool hasDaySelected = selectedDays.any((day) => day);
    bool hasNotificationType = whatsappNotification || alarmSound;
    
    if (!hasDaySelected) {
      _showErrorDialog('Selecione pelo menos um dia da semana');
      return false;
    }
    
    if (!hasNotificationType) {
      _showErrorDialog('Selecione pelo menos um tipo de notificação');
      return false;
    }
    
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atenção'),
          content: Text(message),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sucesso!'),
          content: const Text('Alarme configurado com sucesso!'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha o dialog
                Navigator.pop(context); // Volta para a tela anterior
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Função para salvar o alarme
  Future<void> _handleSaveAlarm() async {
    if (!_validateSelection()) {
      return;
    }

    try {
      // Salva o alarme usando o AlarmService
      await AlarmService.setAlarms(
        selectedTime: selectedTime,
        selectedDays: selectedDays,
      );
      
      // Salva os dados do alarme no SharedPreferences para o histórico
      await _saveAlarmData();
      
      // Mostra mensagem de sucesso
      _showSuccessDialog();
      
    } catch (e) {
      print('Erro ao configurar alarme: $e');
      _showErrorDialog('Erro ao configurar o alarme. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text(
          'Configurar Notificação',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () async {
              // Navega para a tela de gerenciamento e aguarda o retorno
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageAlarmsScreen(),
                ),
              );
              
              // Se algum alarme foi modificado, você pode atualizar a tela aqui se necessário
              if (result != null && result == 'alarm_deleted') {
                // Opcional: fazer alguma ação quando alarmes foram deletados
                print('Alarmes foram modificados na tela de gerenciamento');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      size: 40,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Configure seus lembretes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Seção do Horário
            _buildSectionTitle('⏰ Horário'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _pickTime(context),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Seção dos Dias
            _buildSectionTitle('📅 Dias da Semana'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDays[index] = !selectedDays[index];
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selectedDays[index]
                                ? Colors.blue[600]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: selectedDays[index]
                                ? Border.all(
                                    color: Colors.blue[700]!,
                                    width: 2,
                                  )
                                : Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                          ),
                          child: Center(
                            child: Text(
                              weekDays[index],
                              style: TextStyle(
                                color: selectedDays[index]
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: selectedDays[index]
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Toque nos dias para ativar/desativar',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Seção dos Tipos de Notificação
            _buildSectionTitle('🔔 Tipos de Notificação'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  // WhatsApp
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: whatsappNotification
                          ? Colors.blue[50]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: whatsappNotification
                            ? Colors.blue[300]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.chat_sharp,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Receber mensagem no WhatsApp',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: whatsappNotification,
                          onChanged: (value) {
                            setState(() {
                              whatsappNotification = value;
                            });
                          },
                          activeThumbColor: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Alarme
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: alarmSound ? Colors.orange[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: alarmSound
                            ? Colors.orange[300]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.volume_up,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alarme Sonoro',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Tocar som de alarme no horário',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: alarmSound,
                          onChanged: (value) {
                            setState(() {
                              alarmSound = value;
                            });
                          },
                          activeThumbColor: Colors.orange[600],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleSaveAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue[700],
      ),
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