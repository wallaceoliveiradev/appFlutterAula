import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/treinamento_Service.dart';

class CadastrarTreinamentoScreen extends StatefulWidget {
  final Usuario usuario;

  const CadastrarTreinamentoScreen({super.key, required this.usuario});

  @override
  State<CadastrarTreinamentoScreen> createState() =>
      _CadastrarTreinamentoScreenState();
}

class _CadastrarTreinamentoScreenState
    extends State<CadastrarTreinamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _arquivoController = TextEditingController();
  final _validadeController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _arquivoController.dispose();
    _validadeController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      final validadeTexto = _validadeController.text.trim();
      await TreinamentoService().cadastrar(
        adminId: widget.usuario.id,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        arquivoUrl: _arquivoController.text.trim().isEmpty
            ? null
            : _arquivoController.text.trim(),
        validadeMeses: validadeTexto.isEmpty ? null : int.parse(validadeTexto),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treinamento cadastrado com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Treinamento'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o título do treinamento'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _arquivoController,
              decoration: const InputDecoration(
                labelText: 'Nome do arquivo',
                hintText: 'Ex.: NR35.pdf',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _validadeController,
              decoration: const InputDecoration(
                labelText: 'Validade em meses (opcional)',
                hintText: 'Ex.: 24',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final texto = value?.trim() ?? '';
                if (texto.isEmpty) return null;
                final meses = int.tryParse(texto);
                if (meses == null || meses <= 0) {
                  return 'Informe um número inteiro maior que zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _cadastrar,
                icon: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_salvando ? 'Salvando...' : 'Cadastrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
