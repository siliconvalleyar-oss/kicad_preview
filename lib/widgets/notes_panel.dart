import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_state.dart';

class NotesPanel extends StatefulWidget {
  const NotesPanel({super.key});

  @override
  State<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<NotesPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendNote(AppState appState) {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    appState.addNote(text);
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Auto-insert pending ref from chat mode
        final pendingRef = appState.pendingRef;
        if (pendingRef != null && _inputController.text.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _inputController.text = pendingRef;
            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: _inputController.text.length),
            );
          });
        }
        return Container(
          width: 260,
          decoration: const BoxDecoration(
            color: Color(0xFF252540),
            border: Border(
              left: BorderSide(color: Color(0xFF3D3D5C)),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D2D44),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF3D3D5C)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_alt, size: 16, color: Color(0xFF6C5CE7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Chat mode toggle
                    GestureDetector(
                      onTap: () => appState.toggleChatMode(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: appState.chatMode
                              ? const Color(0xFF6C5CE7).withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: appState.chatMode
                                ? const Color(0xFF6C5CE7)
                                : Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 12,
                              color: appState.chatMode
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 10,
                                color: appState.chatMode
                                    ? const Color(0xFF6C5CE7)
                                    : Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Share button
                    GestureDetector(
                      onTap: () => appState.shareNotes(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.share,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Notes list
              Expanded(
                child: _notes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_note,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 8),
                              Text(
                                appState.chatMode
                                    ? 'Tap a component on the schematic\nto insert its reference, then\ntype your note below.'
                                    : 'Write notes about your\nschematic or PCB below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          final refEnd = note.indexOf(']');
                          final hasRef = refEnd >= 0 && note.startsWith('[');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D44),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: hasRef
                                  ? RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: note.substring(0, refEnd + 1),
                                            style: TextStyle(
                                              color: const Color(0xFF6C5CE7),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: note.substring(refEnd + 1),
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      note,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
              // Input area
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D2D44),
                  border: Border(
                    top: BorderSide(color: Color(0xFF3D3D5C)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: appState.chatMode
                              ? 'Type note or tap component...'
                              : 'Write a note...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _sendNote(appState),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _sendNote(appState),
                      icon: const Icon(Icons.send, size: 18),
                      color: const Color(0xFF6C5CE7),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> get _notes => context.read<AppState>().notes;
}
