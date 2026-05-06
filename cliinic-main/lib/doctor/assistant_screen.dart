import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'doctor_colors.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  final List<String> _suggestions = [
    'Résumer les rendez-vous du jour',
    'Conseils pour diagnostiquer une carie',
    'Protocole d\'hygiène dentaire',
    'Interpréter un X-Ray dentaire',
    'Médicaments anti-douleur dentaires',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _loading = true;
    });
    _scrollToBottom();

    String context = '';
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final pending = await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .get();
        context =
            'Le docteur a ${pending.docs.length} demande(s) de rendez-vous en attente. ';
      }
    } catch (_) {}

    try {
      final response = await _callClaude(text.trim(), context);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Désolé, une erreur s\'est produite. Veuillez réessayer.',
        });
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _callClaude(String userMessage, String context) async {
    try {
      final uri = Uri.parse('https://api.anthropic.com/v1/messages');
      final body = jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 1000,
        'system':
            'Tu es un assistant médical intelligent pour un médecin dentiste. '
            'Tu réponds en français de façon professionnelle et concise. '
            'Tu aides avec les diagnostics, les protocoles de soins dentaires, '
            'la gestion des patients, et les informations médicales. '
            '$context',
        'messages': [
          {'role': 'user', 'content': userMessage}
        ],
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'YOUR_API_KEY_HERE',
          'anthropic-version': '2023-06-01',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        return _simulateResponse(userMessage);
      }
    } catch (_) {
      return _simulateResponse(userMessage);
    }
  }

  String _simulateResponse(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('rendez-vous') || lower.contains('appointment')) {
      return 'Pour gérer vos rendez-vous efficacement :\n\n'
          '• Vérifiez l\'onglet "Requests" pour les nouvelles demandes\n'
          '• Confirmez ou refusez chaque demande\n'
          '• Utilisez l\'onglet "Schedule" pour visualiser votre agenda\n\n'
          'Souhaitez-vous des conseils sur l\'organisation de votre agenda ?';
    }
    if (lower.contains('carie') || lower.contains('diagnostic')) {
      return 'Pour diagnostiquer une carie :\n\n'
          '• **Examen visuel** : recherchez des taches brunes/noires\n'
          '• **Sondage** : testez la dureté de l\'émail\n'
          '• **X-Ray** : indispensable pour les caries inter-proximales\n'
          '• **Transillumination** : utile pour les petites lésions\n\n'
          'Stades : initiale (réversible), dentine (restauration), pulpe (traitement endodontique).';
    }
    if (lower.contains('x-ray') || lower.contains('radio')) {
      return 'Pour les radiographies dentaires :\n\n'
          '• **Bitewing** : détecte les caries inter-proximales\n'
          '• **Périapicale** : évalue la racine et l\'os alvéolaire\n'
          '• **Panoramique** : vue d\'ensemble de toutes les dents\n\n'
          'Fréquence recommandée : tous les 2 ans pour patients à faible risque.';
    }
    if (lower.contains('hygiène') || lower.contains('protocole')) {
      return 'Protocole d\'hygiène dentaire recommandé :\n\n'
          '• Brossage 2x/jour pendant 2 minutes (technique Bass)\n'
          '• Fil dentaire 1x/jour\n'
          '• Bain de bouche antiseptique si nécessaire\n'
          '• Détartrage professionnel 2x/an\n'
          '• Alimentation : limiter sucres et boissons acides\n\n'
          'Adaptez le conseil selon le profil de risque du patient.';
    }
    return 'Je suis votre assistant médical dentaire. Je peux vous aider avec :\n\n'
        '• Les diagnostics dentaires\n'
        '• Les protocoles de soins\n'
        '• La gestion des patients\n'
        '• L\'interprétation des radiographies\n\n'
        'Posez-moi votre question spécifique pour une réponse détaillée.';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DC.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: DC.green, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant IA',
                    style: TextStyle(
                        color: DC.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('Votre aide médicale intelligente',
                    style: TextStyle(color: DC.textSub, fontSize: 10)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: DC.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: DC.textSub),
            onPressed: () => setState(() => _messages.clear()),
            tooltip: 'Effacer la conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) return _buildTyping();
                      final m = _messages[i];
                      final isUser = m['role'] == 'user';
                      return _buildBubble(m['content'] ?? '', isUser);
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DC.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: DC.green, size: 48),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text('Bonjour Docteur !',
              style: TextStyle(
                  color: DC.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Je suis votre assistant médical IA.\nPosez-moi n\'importe quelle question.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DC.textSub, fontSize: 13),
          ),
        ),
        const SizedBox(height: 28),
        const Text('Suggestions rapides',
            style: TextStyle(
                color: DC.green,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        const SizedBox(height: 12),
        ..._suggestions.map((s) => GestureDetector(
              onTap: () => _send(s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: DC.cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: DC.green, size: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s,
                          style:
                              const TextStyle(color: DC.text, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? DC.green : DC.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: DC.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.black : DC.text,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DC.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: DC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: DC.green, strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            const Text('En train de réfléchir...',
                style: TextStyle(color: DC.textSub, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: DC.surface,
        border: Border(top: BorderSide(color: DC.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: DC.text),
              maxLines: null,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'Posez une question médicale...',
                hintStyle: const TextStyle(color: DC.textMuted),
                filled: true,
                fillColor: DC.card,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: DC.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: DC.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: DC.green, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _send(_ctrl.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: DC.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}