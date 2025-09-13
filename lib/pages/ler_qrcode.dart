import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class LerQrCode extends StatefulWidget {
  const LerQrCode({super.key});

  @override
  State<LerQrCode> createState() => _LerQrCodeState();
}

class _LerQrCodeState extends State<LerQrCode> {
  bool _isScanned = false;

  Future<void> _handleCode(String code) async {
    if (_isScanned) return; // impede múltiplos disparos
    setState(() => _isScanned = true);

    final uri = Uri.tryParse(code);

    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      // Se for URL válida, abre no navegador
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Se não for URL, mostra num diálogo
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("QR Code encontrado"),
            content: Text(code),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isScanned = false); // permite ler de novo
                },
                child: const Text("Fechar"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final scannerSize = screenSize.width * 0.5;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(
          "L.A.S",
          style: TextStyle(
            fontSize: isSmallScreen ? 35 : 50,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.05,
            vertical: 16,
          ),
          child: Column(
            children: [
              // Card com instruções
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (!isSmallScreen)
                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 32,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Aponte o QR CODE para a câmera",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 28,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Aponte o QR CODE para a câmera",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenSize.height * 0.02),

              // Card com o scanner
              Expanded(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          MobileScanner(
                            onDetect: (capture) {
                              for (final barcode in capture.barcodes) {
                                final code = barcode.rawValue;
                                if (code != null) {
                                  _handleCode(code);
                                }
                              }
                            },
                          ),
                          // Overlay com bordas do scanner
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          // Indicador visual no centro
                          Center(
                            child: Container(
                              width: scannerSize.clamp(150.0, 250.0),
                              height: scannerSize.clamp(150.0, 250.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blueAccent,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenSize.height * 0.02),

              // Card com informações adicionais
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (!isSmallScreen)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Posicione o QR Code dentro da área destacada",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Posicione o QR Code dentro da área destacada",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                    ],
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
