import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../services/gemini_service.dart';
import '../providers/ai_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
  String? _loadedPdfPath;
  int _currentPage = 1;
  int _pageCount = 1;
  double _zoomLevel = 1.0;
  bool _isInverted = false;
  bool _isLoading = false;
  bool _isAiSummarizing = false;
  String _aiProgressText = "";

  @override
  void initState() {
    super.initState();
    _loadLastPdf();
  }

  Future<void> _loadLastPdf() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPath = prefs.getString(AppConstants.prefLastPdfPath);
    if (lastPath != null && lastPath.isNotEmpty) {
      final file = File(lastPath);
      if (await file.exists()) {
        setState(() {
          _loadedPdfPath = lastPath;
        });
      } else {
        await prefs.remove(AppConstants.prefLastPdfPath);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        
        setState(() {
          _loadedPdfPath = path;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.prefLastPdfPath, path);
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');
    }
  }

  void _restoreLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPage = prefs.getInt('${AppConstants.prefLastPdfPage}_${_loadedPdfPath}');
    if (lastPage != null && lastPage > 1 && lastPage <= _pageCount) {
       _pdfViewerController.jumpToPage(lastPage);
    }
  }

  void _saveCurrentPage(int page) async {
    if (_loadedPdfPath != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${AppConstants.prefLastPdfPage}_${_loadedPdfPath}', page);
    }
  }

  void _jumpToPageDialog() {
    final ctx = context;
    final alertOptionsCtrl = TextEditingController(text: _currentPage.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.appColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusModal)),
          title: Text('Jump to Page', style: AppTypography.headlineSM.copyWith(color: context.appColors.textPrimary)),
          content: TextField(
            controller: alertOptionsCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: AppTypography.body.copyWith(color: context.appColors.textPrimary),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
               hintText: '1 - $_pageCount',
               hintStyle: AppTypography.body.copyWith(color: context.appColors.textSecondary),
               enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.appColors.border)),
               focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
            onSubmitted: (v) {
              Navigator.pop(ctx, int.tryParse(v));
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTypography.body.copyWith(color: context.appColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(alertOptionsCtrl.text)),
              child: Text('Go', style: AppTypography.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((val) {
      if (val != null && val is int) {
        if (val > 0 && val <= _pageCount) {
          _pdfViewerController.jumpToPage(val);
        }
      }
    });
  }

  Future<void> _summarizePdf(bool wholeDoc) async {
    if (_loadedPdfPath == null) return;

    setState(() {
      _isAiSummarizing = true;
      _aiProgressText = wholeDoc ? "Reading entire document..." : "Reading current page...";
    });

    try {
      final bytes = File(_loadedPdfPath!).readAsBytesSync();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      String text = "";
      if (wholeDoc) {
        text = extractor.extractText();
      } else {
        text = extractor.extractText(startPageIndex: _currentPage - 1, endPageIndex: _currentPage - 1);
      }
      
      document.dispose();

      if (text.trim().isEmpty) {
        throw Exception("No text could be extracted from this ${wholeDoc ? 'document' : 'page'}. AI cannot summarize image-only scanned files without OCR.");
      }

      setState(() {
        _aiProgressText = wholeDoc ? "Summarizing full document..." : "Summarizing page...";
      });

      final aiProvider = context.read<AIProvider>();
      final summary = await aiProvider.summarizePdfText(text);

      if (mounted) {
        _showResultsDialog(summary, wholeDoc ? 'AI Document Summary' : 'AI Page Summary');
      }
    } catch (e) {
      if (mounted) {
        _showResultsDialog("Error generating summary: \n\n${e.toString()}", "Error");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiSummarizing = false;
          _aiProgressText = "";
        });
      }
    }
  }

  Future<void> _detectAndSolveQuestions() async {
    if (_loadedPdfPath == null) return;

    setState(() {
      _isAiSummarizing = true;
      _aiProgressText = "Scanning document for questions...";
    });

    try {
      final bytes = File(_loadedPdfPath!).readAsBytesSync();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();

      if (text.trim().isEmpty) {
        throw Exception("No text found. Cannot detect questions.");
      }

      final aiProvider = context.read<AIProvider>();
      final questions = await aiProvider.detectQuestions(text);

      if (!mounted) return;
      setState(() { _isAiSummarizing = false; });

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No questions detected in this document."))
        );
        return;
      }

      _showQuestionSelector(questions, text);
    } catch (e) {
      if (mounted) {
        setState(() { _isAiSummarizing = false; });
        debugPrint("Detection Error: $e");
      }
    }
  }

  void _showQuestionSelector(List<Map<String, String>> questions, String fullText) {
    final List<String> selectedIds = [];
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: ctx.appColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusModal)),
              title: Row(
                children: [
                  Icon(PhosphorIcons.listChecks(), color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Select Questions to Solve', style: AppTypography.headlineSM.copyWith(color: ctx.appColors.textPrimary)),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    final id = q['id'] ?? '';
                    final isSelected = selectedIds.contains(id);
                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      title: Text(id, style: AppTypography.bodyMD.copyWith(color: ctx.appColors.textPrimary, fontWeight: FontWeight.bold)),
                      subtitle: Text(q['snippet'] ?? '', style: AppTypography.bodySM.copyWith(color: ctx.appColors.textSecondary)),
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selectedIds.add(id);
                          } else {
                            selectedIds.remove(id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: AppTypography.bodyMD.copyWith(color: ctx.appColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: ctx.appColors.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: selectedIds.isEmpty ? null : () {
                    Navigator.pop(ctx);
                    _solveQuestions(selectedIds, fullText);
                  },
                  child: const Text('Solve Selected', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _solveQuestions(List<String> ids, String fullText) async {
    final buffer = StringBuffer();
    final aiProvider = context.read<AIProvider>();

    try {
      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];
        
        setState(() {
          _isAiSummarizing = true;
          _aiProgressText = "Solving question ${i + 1} of ${ids.length} ($id)...";
        });

        final result = await aiProvider.solveQuestion(id, fullText);
        
        buffer.writeln('# Question $id');
        buffer.writeln('$result\n');
        if (i < ids.length - 1) {
          buffer.writeln('---'); // Divider between questions
        }
      }

      if (mounted) {
        _showResultsDialog(buffer.toString(), "Solved Questions");
      }
    } catch (e) {
      if (mounted) {
        _showResultsDialog("An error occurred during solving: $e", "Review Error");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiSummarizing = false;
          _aiProgressText = "";
        });
      }
    }
  }

  void _showSummaryOptions() {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          backgroundColor: ctx.appColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusModal)),
          title: Text('AI Summarize Options', style: AppTypography.headlineSM.copyWith(color: ctx.appColors.textPrimary)),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                _summarizePdf(false);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.fileText(), color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text('Summarize Current Page', style: AppTypography.body.copyWith(color: ctx.appColors.textPrimary)),
                  ],
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                _summarizePdf(true);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.folders(), color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text('Summarize Entire Document', style: AppTypography.body.copyWith(color: ctx.appColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResultsDialog(String markdownContent, String title) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ctx.appColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusModal)),
          title: Row(
            children: [
              Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title, 
                style: AppTypography.headlineSM.copyWith(color: ctx.appColors.textPrimary)
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            height: 500,
            child: Markdown(
              data: markdownContent,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: AppTypography.bodyMD.copyWith(color: ctx.appColors.textSecondary),
                h1: AppTypography.displaySM.copyWith(color: ctx.appColors.textPrimary, fontSize: 22),
                h2: AppTypography.displaySM.copyWith(color: ctx.appColors.textPrimary, fontSize: 18),
                h3: AppTypography.displaySM.copyWith(color: ctx.appColors.textPrimary, fontSize: 16),
                listBullet: AppTypography.bodyMD.copyWith(color: ctx.appColors.textPrimary),
                blockquote: AppTypography.bodyMD.copyWith(color: ctx.appColors.textSecondary, fontStyle: FontStyle.italic),
                blockquoteDecoration: BoxDecoration(
                  color: ctx.appColors.background.withValues(alpha: 0.5),
                  border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                blockquotePadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: AppTypography.bodyMD.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static const ColorFilter _invertColorFilter = ColorFilter.matrix([
    -1,  0,  0, 0, 255,
     0, -1,  0, 0, 255,
     0,  0, -1, 0, 255,
     0,  0,  0, 1,   0,
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    
    return Stack(
      children: [
        Column(
          children: [
            _buildToolbar(colors),
            Expanded(
              child: _loadedPdfPath == null
                  ? _buildEmptyState(colors)
                  : _buildPdfViewer(colors),
            ),
          ],
        ),
        if (_isAiSummarizing)
          _buildLoadingOverlay(colors),
      ],
    );
  }

  Widget _buildLoadingOverlay(AppColorsExtension colors) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppConstants.radiusModal),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Mindful Agent is on it...',
                style: AppTypography.titleMD.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _aiProgressText,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.filePdf(PhosphorIconsStyle.light), size: 64, color: colors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No PDF loaded',
            style: AppTypography.titleMD.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: Icon(PhosphorIcons.folderOpen(), size: 20),
            label: const Text('Open Local PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusButton)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer(AppColorsExtension colors) {
    Widget viewer = Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScaleEvent) {
          final newZoom = (_zoomLevel * pointerSignal.scale).clamp(0.5, 3.0);
          _pdfViewerController.zoomLevel = newZoom;
        } else if (pointerSignal is PointerScrollEvent) {
          final isCtrl = HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
                         HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight);
          if (isCtrl) {
            final delta = pointerSignal.scrollDelta.dy;
            final newZoom = (_zoomLevel - (delta / 500)).clamp(0.5, 3.0);
            _pdfViewerController.zoomLevel = newZoom;
          }
        }
      },
      child: SfPdfViewer.file(
        File(_loadedPdfPath!),
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        canShowScrollHead: false,
        canShowScrollStatus: true,
        interactionMode: PdfInteractionMode.pan,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            _pageCount = details.document.pages.count;
          });
          _restoreLastPage();
        },
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPage = details.newPageNumber;
          });
          _saveCurrentPage(details.newPageNumber);
        },
        onZoomLevelChanged: (PdfZoomDetails details) {
          setState(() {
            _zoomLevel = details.newZoomLevel;
          });
        },
      ),
    );

    if (_isInverted) {
      viewer = ColorFiltered(
        colorFilter: _invertColorFilter,
        child: viewer,
      );
    }

    return Container(
      color: _isInverted ? Colors.black : Colors.white,
      child: viewer,
    );
  }

  Widget _buildToolbar(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      child: Row(
        children: [
          _ToolbarBtn(
            icon: PhosphorIcons.folderOpen(),
            onTap: _pickFile,
            tooltip: 'Open PDF',
          ),
          const SizedBox(width: 16),
          if (_loadedPdfPath != null) ...[
            Container(width: 1, height: 24, color: colors.border),
            const SizedBox(width: 16),
            _ToolbarBtn(
              icon: PhosphorIcons.arrowLeft(),
              onTap: _pdfViewerController.previousPage,
              tooltip: 'Previous Page',
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _jumpToPageDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '$_currentPage / $_pageCount',
                  style: AppTypography.bodySM.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ToolbarBtn(
              icon: PhosphorIcons.arrowRight(),
              onTap: _pdfViewerController.nextPage,
              tooltip: 'Next Page',
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 24, color: colors.border),
            const SizedBox(width: 16),
            _ToolbarBtn(
              icon: PhosphorIcons.magnifyingGlassMinus(),
              onTap: () {
                _pdfViewerController.zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 3.0);
              },
              tooltip: 'Zoom Out',
            ),
            Text(
              '${(_zoomLevel * 100).round()}%',
              style: AppTypography.bodySM.copyWith(color: colors.textSecondary),
            ),
            _ToolbarBtn(
              icon: PhosphorIcons.magnifyingGlassPlus(),
              onTap: () {
                _pdfViewerController.zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 3.0);
              },
              tooltip: 'Zoom In',
            ),
            const Spacer(),
            _ToolbarBtn(
              icon: PhosphorIcons.moon(),
              onTap: () {
                setState(() => _isInverted = !_isInverted);
              },
              tooltip: 'Invert Colors',
              isActive: _isInverted,
            ),
            const SizedBox(width: 16),
            _ToolbarBtn(
              icon: PhosphorIcons.lightbulb(),
              onTap: _isAiSummarizing ? () {} : _detectAndSolveQuestions,
              tooltip: 'Identify and Solve Questions',
              isActive: _isAiSummarizing,
            ),
            const SizedBox(width: 16),
            _ToolbarBtn(
              icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              onTap: _isAiSummarizing ? () {} : _showSummaryOptions,
              tooltip: 'AI Summarize Document',
              isActive: _isAiSummarizing,
            ),
          ]
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isActive;

  const _ToolbarBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  State<_ToolbarBtn> createState() => _ToolbarBtnState();
}

class _ToolbarBtnState extends State<_ToolbarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isActive
                 ? AppColors.primary.withValues(alpha: 0.2)
                 : _hovered ? colors.surfaceElevated : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isActive ? AppColors.primary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
