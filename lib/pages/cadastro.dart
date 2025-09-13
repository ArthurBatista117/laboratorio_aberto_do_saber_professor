import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

var cpfMask = MaskTextInputFormatter(
  mask: '###.###.###-##',
  filter: {"#": RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.eager,
);

var telefoneMask = MaskTextInputFormatter(
  mask: '(##) #####-####',
  filter: {"#": RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.eager,
);

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  bool _isLoading = false;

  Future<void> enviarCadastro(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        "https://laboratorio-aberto-do-saber-6.onrender.com/cadastro",
      );
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": controllers["nome"]!.text,
          "cpf": controllers["cpf"]!.text,
          "telefone": controllers["telefone"]!.text,
          "email": controllers["email"]!.text,
          "senha": controllers["senha"]!.text,
        }),
      );

      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Cadastro realizado com sucesso!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
        // Limpar os campos após sucesso
        for (var controller in controllers.values) {
          controller.clear();
        }
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Erro ao cadastrar'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão. Tente novamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  final _keyForm = GlobalKey<FormState>();

  final Map<String, TextEditingController> controllers = {
    "nome": TextEditingController(),
    "cpf": TextEditingController(),
    "telefone": TextEditingController(),
    "email": TextEditingController(),
    "senha": TextEditingController(),
  };

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTextField({
    required String key,
    required String label,
    required String? Function(String?) validator,
    List<MaskTextInputFormatter>? inputFormatters,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controllers[key],
        validator: validator,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blue) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.blue.shade700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(
          "L.A.S",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 2,
        centerTitle: true,
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Card(
              elevation: 8,
              shadowColor: Colors.blue.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _keyForm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header do formulário
                      Container(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 48,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Criar Conta',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Preencha os dados abaixo para se cadastrar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Campos do formulário
                      _buildTextField(
                        key: "nome",
                        label: "Nome Completo",
                        prefixIcon: Icons.person,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Por favor digite seu nome";
                          } else if (value.length < 2) {
                            return "Digite um nome válido";
                          }
                          return null;
                        },
                      ),

                      _buildTextField(
                        key: "cpf",
                        label: "CPF",
                        prefixIcon: Icons.badge,
                        keyboardType: TextInputType.number,
                        inputFormatters: [cpfMask],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Por favor digite seu CPF";
                          } else if (value.length < 14) {
                            return "CPF incompleto";
                          }
                          return null;
                        },
                      ),

                      _buildTextField(
                        key: "email",
                        label: "E-mail",
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-mail é obrigatório';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Digite um e-mail válido';
                          }
                          return null;
                        },
                      ),

                      _buildTextField(
                        key: "telefone",
                        label: "Telefone",
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [telefoneMask],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Telefone é obrigatório';
                          } else if (value.length < 15) {
                            return 'Telefone incompleto';
                          }
                          return null;
                        },
                      ),

                      _buildTextField(
                        key: "senha",
                        label: "Senha",
                        prefixIcon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite uma senha';
                          } else if (value.length < 6) {
                            return 'Senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24),

                      // Botão de cadastro
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_keyForm.currentState!.validate()) {
                              await enviarCadastro(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Cadastrando...",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  "Criar Conta",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Texto informativo
                      Text(
                        'Ao criar uma conta, você concorda com nossos termos de uso.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}