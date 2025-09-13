import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ArquivosPage extends StatefulWidget {
  const ArquivosPage({super.key});

  @override
  State<ArquivosPage> createState() => _ArquivosPageState();
}

class _ArquivosPageState extends State<ArquivosPage> {
  final List<MaterialEstudo> _materiais = [];
  String _filtroSelecionado = 'Todos';
  String _termoPesquisa = '';
  final TextEditingController _pesquisaController = TextEditingController();

  List<MaterialEstudo> get _materiaisFiltrados {
    List<MaterialEstudo> materiais = _materiais;

    // Filtro por tipo
    if (_filtroSelecionado != 'Todos') {
      TipoMaterial? tipoFiltro;
      switch (_filtroSelecionado) {
        case 'Vídeoaulas':
          tipoFiltro = TipoMaterial.video;
        case 'Documentos':
          tipoFiltro = TipoMaterial.documento;
      }
      if (tipoFiltro != null) {
        materiais = materiais.where((m) => m.tipo == tipoFiltro).toList();
      }
    }

    // Filtro por pesquisa
    if (_termoPesquisa.isNotEmpty) {
      materiais = materiais.where((m) =>
          m.titulo.toLowerCase().contains(_termoPesquisa.toLowerCase())).toList();
    }

    return materiais;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioAdicionar(),
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          if (_materiais.isNotEmpty) _buildBarraPesquisa(),
          Expanded(
            child: _materiais.isEmpty 
              ? _buildEstadoVazio()
              : _buildListaMateriais(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_open, size: 40, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Materiais de Estudo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _materiais.isEmpty 
                    ? 'Nenhum material disponível'
                    : '${_materiaisFiltrados.length} materiais',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraPesquisa() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            controller: _pesquisaController,
            onChanged: (value) => setState(() => _termoPesquisa = value),
            decoration: InputDecoration(
              hintText: 'Pesquisar materiais...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _termoPesquisa.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _pesquisaController.clear();
                        setState(() => _termoPesquisa = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: ['Todos', 'Vídeoaulas', 'Documentos']
                .map((filtro) => Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filtro),
                        selected: _filtroSelecionado == filtro,
                        onSelected: (_) => setState(() => _filtroSelecionado = filtro),
                        selectedColor: Colors.blue.shade100,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListaMateriais() {
    if (_materiaisFiltrados.isEmpty) {
      return Center(
        child: Text(
          'Nenhum material encontrado',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _materiaisFiltrados.length,
      itemBuilder: (context, index) {
        final material = _materiaisFiltrados[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCorTipo(material.tipo).withOpacity(0.1),
              child: Icon(
                _getIconeTipo(material.tipo),
                color: _getCorTipo(material.tipo),
              ),
            ),
            title: Text(material.titulo, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material.descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text(
                  material.tipo == TipoMaterial.video ? 'Vídeoaula' : 'Documento',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getCorTipo(material.tipo),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    material.tipo == TipoMaterial.video ? Icons.play_arrow : Icons.open_in_new,
                    color: Colors.blue,
                  ),
                  onPressed: () => _abrirLink(material.url),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  onPressed: () => _removerMaterial(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 24),
            Text(
              'Nenhum material disponível',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12),
            Text(
              'Adicione vídeoaulas ou documentos usando o botão +',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioAdicionar() {
    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();
    final urlController = TextEditingController();
    TipoMaterial tipoSelecionado = TipoMaterial.video;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adicionar Material de Estudo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo de Material:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<TipoMaterial>(
                        title: Text('Vídeoaula'),
                        subtitle: Text('YouTube, Vimeo, etc.'),
                        value: TipoMaterial.video,
                        groupValue: tipoSelecionado,
                        onChanged: (value) {
                          setDialogState(() => tipoSelecionado = value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<TipoMaterial>(
                        title: Text('Documento'),
                        subtitle: Text('PDF, Word, etc.'),
                        value: TipoMaterial.documento,
                        groupValue: tipoSelecionado,
                        onChanged: (value) {
                          setDialogState(() => tipoSelecionado = value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Link*',
                    hintText: tipoSelecionado == TipoMaterial.video 
                        ? 'https://youtube.com/watch?v=...' 
                        : 'https://drive.google.com/...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _adicionarMaterial(
                tituloController.text,
                descricaoController.text,
                urlController.text,
                tipoSelecionado,
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Adicionar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarMaterial(String titulo, String descricao, String url, TipoMaterial tipo) {
    if (titulo.trim().isEmpty || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Título e link são obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _materiais.add(MaterialEstudo(
        titulo: titulo.trim(),
        descricao: descricao.trim().isEmpty ? 'Sem descrição' : descricao.trim(),
        tipo: tipo,
        url: url.trim(),
      ));
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Material adicionado com sucesso!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _removerMaterial(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover Material'),
        content: Text('Deseja remover este material de estudo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _materiais.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Material removido')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirLink(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir o link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link inválido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getIconeTipo(TipoMaterial tipo) {
    return tipo == TipoMaterial.video ? Icons.play_circle_filled : Icons.description;
  }

  Color _getCorTipo(TipoMaterial tipo) {
    return tipo == TipoMaterial.video ? Colors.red : Colors.blue;
  }
}

class MaterialEstudo {
  final String titulo;
  final String descricao;
  final TipoMaterial tipo;
  final String url;

  MaterialEstudo({
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.url,
  });
}

enum TipoMaterial { video, documento }