import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';
import '../services/diagnostic_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatbotEntryScreen extends StatefulWidget {
  final String? initialVehicleId;

  const ChatbotEntryScreen({super.key, this.initialVehicleId});

  @override
  State<ChatbotEntryScreen> createState() => _ChatbotEntryScreenState();
}

class _ChatbotEntryScreenState extends State<ChatbotEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _generalChatController = TextEditingController();
  final _scrollController = ScrollController();
  final _symptomController = TextEditingController();

  // General Chat state
  final List<ChatMessage> _messages = [];
  bool _sendingGeneralMsg = false;

  // Vehicle Diagnostic state
  List<Vehicle> _vehicles = [];
  String? _selectedVehicleId;
  bool _loadingVehicles = true;
  bool _diagnosing = false;
  String? _diagnosis;
  String? _diagnosticError;

  final List<String> _suggestedPrompts = [
    'What documents are required to renew a revenue license in Sri Lanka?',
    'How often should I change engine oil and filter?',
    'What causes squealing noises when I apply the brakes?',
    'How can I get the best fuel efficiency for my car?',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVehicles();

    // Initial greeting message for General Chat
    _messages.add(
      ChatMessage(
        text:
            'Hello! I am Drivora AI Assistant. You can ask me anything about vehicle maintenance, document renewals, driving advice, or troubleshooting car issues!',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _generalChatController.dispose();
    _symptomController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _cleanText(String input) {
    return input.replaceAll('**', '').replaceAll('*', '').trim();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await DatabaseHelper.instance.getVehicles();
      setState(() {
        _vehicles = vehicles;
        if (vehicles.isNotEmpty) {
          if (widget.initialVehicleId != null &&
              vehicles.any((v) => v.id == widget.initialVehicleId)) {
            _selectedVehicleId = widget.initialVehicleId;
          } else {
            _selectedVehicleId = vehicles.first.id;
          }
        } else {
          _selectedVehicleId = null;
        }
        _loadingVehicles = false;
      });
    } catch (_) {
      setState(() => _loadingVehicles = false);
    }
  }

  // --- GENERAL CHAT LOGIC ---

  Future<void> _sendGeneralMessage([String? customText]) async {
    final text = customText ?? _generalChatController.text.trim();
    if (text.isEmpty || _sendingGeneralMsg) return;

    if (customText == null) {
      _generalChatController.clear();
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _sendingGeneralMsg = true;
    });

    _scrollToBottom();

    final aiReply = await _fetchGeneralAiResponse(text);

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: _cleanText(aiReply), isUser: false));
        _sendingGeneralMsg = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _fetchGeneralAiResponse(String userPrompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final conversationPayload = _messages.map((m) {
          return {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          };
        }).toList();

        final response = await http
            .post(
              Uri.parse('https://api.openai.com/v1/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${apiKey.trim()}',
              },
              body: jsonEncode({
                'model': 'gpt-4o-mini',
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are Drivora AI, a friendly and expert automotive assistant. You help vehicle owners with car advice, Sri Lanka & general document renewals (revenue license, insurance, emission test), maintenance schedules, and car troubleshooting. Do NOT use markdown bold stars or asterisks (** or *) in your output.',
                  },
                  ...conversationPayload,
                ],
                'max_tokens': 500,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final content =
              decoded['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      } catch (_) {
        // Fall back to built-in smart knowledge engine below
      }
    }

    return _generateOfflineResponse(userPrompt);
  }

  String _generateOfflineResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('revenue') ||
        q.contains('license') ||
        q.contains('document') ||
        q.contains('renew')) {
      return '📄 Sri Lanka Revenue License Renewal Requirements:\n\n'
          'To renew your vehicle revenue license, you typically need:\n'
          '1. Valid Vehicle Insurance Certificate (original)\n'
          '2. Valid Vehicle Emission Test Certificate (VET)\n'
          '3. Vehicle Registration Certificate (CR / Smart Card)\n'
          '4. Previous Year Revenue License\n\n'
          '💡 Tip: You can track your document expiry dates directly in Drivora to get timely alerts!';
    } else if (q.contains('oil') ||
        q.contains('service') ||
        q.contains('maintenance')) {
      return '🛢️ Engine Oil & Service Schedule Guidelines:\n\n'
          '• Mineral Oil: Change every 5,000 km or 6 months.\n'
          '• Synthetic Blend: Change every 7,500 km to 10,000 km.\n'
          '• Full Synthetic Oil: Change every 10,000 km to 15,000 km or 1 year.\n\n'
          'Always replace the oil filter during every oil change for optimal engine performance.';
    } else if (q.contains('brake') ||
        q.contains('noise') ||
        q.contains('squeal') ||
        q.contains('sound')) {
      return '🔊 Vehicle Noise & Brake Symptoms:\n\n'
          '• High-pitched squealing: Usually indicates worn brake pads touching the wear indicator.\n'
          '• Grinding metallic sound: Indicates brake pads are completely worn out and damaging the rotor.\n'
          '• Clicking/Knocking while turning: Often caused by a worn Constant Velocity (CV) joint.\n\n'
          '⚠️ Recommendation: Inspect brake pad thickness immediately if grinding occurs.';
    } else if (q.contains('fuel') ||
        q.contains('mileage') ||
        q.contains('efficiency') ||
        q.contains('petrol') ||
        q.contains('diesel')) {
      return '⛽ Tips to Improve Fuel Efficiency:\n\n'
          '1. Tire Pressure: Keep tires inflated to manufacturer specified PSI.\n'
          '2. Smooth Acceleration: Avoid rapid starts and aggressive braking.\n'
          '3. Air Filter: Clean or replace clogged air filters regularly.\n'
          '4. Reduce Excess Weight: Clear out unused items from trunk.\n'
          '5. Regular Maintenance: Ensure spark plugs and injectors are clean.';
    } else {
      return '🤖 Drivora AI Advice:\n\n'
          'Regular preventive maintenance is the key to vehicle longevity and safety. Make sure to regularly check:\n'
          '• Engine oil and coolant levels\n'
          '• Tire tread depth and pressure\n'
          '• Brake performance & document expiry dates\n\n'
          'Feel free to ask specific questions about document renewals, maintenance schedules, or symptoms!';
    }
  }

  // --- VEHICLE DIAGNOSTIC LOGIC ---

  Future<void> _runDiagnosis() async {
    final symptom = _symptomController.text.trim();
    if (symptom.isEmpty) return;
    if (_selectedVehicleId == null) {
      setState(() {
        _diagnosticError = 'Please select a vehicle first to analyze symptoms.';
      });
      return;
    }

    final selectedVehicle = _vehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => _vehicles.first,
    );

    setState(() {
      _diagnosing = true;
      _diagnosis = null;
      _diagnosticError = null;
    });

    try {
      final result = await DiagnosticService.diagnose(
        vehicleId: _selectedVehicleId!,
        symptomDescription: symptom,
      );
      if (mounted) setState(() => _diagnosis = _cleanText(result));
    } catch (_) {
      // Backend service fallback — use AI engine or local diagnostic generator
      try {
        final fallbackResult = await _fetchFallbackDiagnosis(
          selectedVehicle.displayName,
          symptom,
        );
        if (mounted) setState(() => _diagnosis = _cleanText(fallbackResult));
      } catch (_) {
        if (mounted) {
          setState(() {
            _diagnosticError =
                'Unable to connect to the vehicle diagnostic service. Please check your internet connection and try again.';
          });
        }
      }
    } finally {
      if (mounted) setState(() => _diagnosing = false);
    }
  }

  Future<String> _fetchFallbackDiagnosis(
      String vehicleName, String symptom) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final response = await http
            .post(
              Uri.parse('https://api.openai.com/v1/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${apiKey.trim()}',
              },
              body: jsonEncode({
                'model': 'gpt-4o-mini',
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are Drivora AI Vehicle Diagnostic Assistant. Provide a clear, structured diagnostic report for the reported vehicle symptom. Do NOT use markdown bold stars or asterisks (** or *) in your output.',
                  },
                  {
                    'role': 'user',
                    'content': 'Vehicle: $vehicleName\nSymptom: $symptom',
                  },
                ],
                'max_tokens': 500,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final content =
              decoded['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      } catch (_) {}
    }

    return _generateLocalDiagnosticReport(vehicleName, symptom);
  }

  String _generateLocalDiagnosticReport(String vehicleName, String symptom) {
    final s = symptom.toLowerCase();

    if (s.contains('light') ||
        s.contains('headlight') ||
        s.contains('lamp') ||
        s.contains('bulb')) {
      return '🔍 Diagnostic Report — $vehicleName\n\n'
          'Symptom: "$symptom"\n\n'
          '1. Most Likely Causes:\n'
          '• Burned-out bulb (filament or LED module failure)\n'
          '• Blown headlight fuse or faulty relay in engine fuse box\n'
          '• Loose or corroded wiring connector harness\n'
          '• Faulty headlight stalk switch on steering column\n\n'
          '2. Urgency & Safety Risk:\n'
          '⚠️ HIGH — Reduced night visibility poses severe road hazards and violates traffic safety regulations.\n\n'
          '3. Recommended Actions:\n'
          '1. Inspect fuses under hood / dashboard for any blown circuit.\n'
          '2. Swap with a known working bulb to verify bulb failure.\n'
          '3. Have an electrician test voltage at connector socket.\n\n'
          '4. Estimated Cost Range:\n'
          '• Fuse / Relay: Rs. 500 – Rs. 1,500\n'
          '• Replacement Bulb: Rs. 1,500 – Rs. 4,500';
    } else if (s.contains('brake') ||
        s.contains('squeal') ||
        s.contains('grind') ||
        s.contains('stop')) {
      return '🔍 Diagnostic Report — $vehicleName\n\n'
          'Symptom: "$symptom"\n\n'
          '1. Most Likely Causes:\n'
          '• Worn brake pads reaching squeal sensor indicator\n'
          '• Metal-on-metal rotor contact due to completely worn pads\n'
          '• Glazed brake rotors or trapped debris\n\n'
          '2. Urgency & Safety Risk:\n'
          '🚨 CRITICAL — Compromised braking distance directly affects stopping capability.\n\n'
          '3. Recommended Actions:\n'
          '1. Visually check brake pad thickness through wheel spokes.\n'
          '2. Have brake rotors resurfaced or replaced if grooved.\n\n'
          '4. Estimated Cost Range:\n'
          '• Front Brake Pad Set: Rs. 6,500 – Rs. 16,000';
    } else if (s.contains('overheat') ||
        s.contains('temperature') ||
        s.contains('coolant') ||
        s.contains('steam')) {
      return '🔍 Diagnostic Report — $vehicleName\n\n'
          'Symptom: "$symptom"\n\n'
          '1. Most Likely Causes:\n'
          '• Low engine coolant level or radiator leak\n'
          '• Stuck thermostat valve preventing coolant flow\n'
          '• Malfunctioning radiator cooling fan or fan switch\n'
          '• Failed water pump\n\n'
          '2. Urgency & Safety Risk:\n'
          '🚨 CRITICAL — Overheating can cause severe engine block warping or head gasket failure within minutes.\n\n'
          '3. Recommended Actions:\n'
          '1. Pull over safely and switch off engine immediately.\n'
          '2. Do NOT open radiator cap while engine is hot.\n'
          '3. Inspect coolant expansion tank level once cooled down.\n\n'
          '4. Estimated Cost Range:\n'
          '• Thermostat / Hose Repair: Rs. 3,500 – Rs. 8,500';
    } else {
      return '🔍 Diagnostic Report — $vehicleName\n\n'
          'Symptom: "$symptom"\n\n'
          '1. Most Likely Causes:\n'
          '• Electrical connection or sensor communication issue\n'
          '• Wear and tear on mechanical component assembly\n'
          '• Fluid level imbalance or filter blockage\n\n'
          '2. Urgency & Safety Risk:\n'
          '⚠️ MODERATE — Schedule inspection with a qualified technician to prevent further wear.\n\n'
          '3. Recommended Actions:\n'
          '1. Perform visual inspection under hood for fluid leaks or loose wires.\n'
          '2. Scan vehicle with OBD-II scanner for error codes if check engine light is illuminated.\n\n'
          '4. Estimated Cost Range:\n'
          '• Diagnostic scan & basic check: Rs. 2,000 – Rs. 5,000';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicleId =
        _vehicles.any((v) => v.id == _selectedVehicleId)
            ? _selectedVehicleId
            : (_vehicles.isNotEmpty ? _vehicles.first.id : null);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text('AI Assistant'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 20),
              text: 'General Chat',
            ),
            Tab(
              icon: Icon(Icons.build_outlined, size: 20),
              text: 'Vehicle Diagnosis',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: GENERAL CHAT
          _buildGeneralChatTab(),

          // TAB 2: VEHICLE DIAGNOSIS
          _buildVehicleDiagnosisTab(activeVehicleId),
        ],
      ),
    );
  }

  Widget _buildGeneralChatTab() {
    return Column(
      children: [
        // Suggestion Chips (shown if only greeting exists)
        if (_messages.length <= 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF18181C),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggested Questions:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _suggestedPrompts.map((prompt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: const Color(0xFF1E1E24),
                          side: const BorderSide(
                              color: Color(0xFF3B82F6), width: 0.8),
                          label: Text(
                            prompt,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          onPressed: () => _sendGeneralMessage(prompt),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

        // Chat Messages List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildChatMessageBubble(msg);
            },
          ),
        ),

        // Typing indicator
        if (_sendingGeneralMsg)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Drivora AI is thinking...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

        // Input Field Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E24),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _generalChatController,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendGeneralMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask anything about vehicles, maintenance...',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed:
                      _sendingGeneralMsg ? null : () => _sendGeneralMessage(),
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF3B82F6) : const Color(0xFF1E1E24),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SelectableText(
                _cleanText(msg.text),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A34),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(String errorMsg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Diagnostic Service Unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            errorMsg,
            style: const TextStyle(
              color: Color(0xFFFCA5A5),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _diagnosing ? null : _runDiagnosis,
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDiagnosisTab(String? activeVehicleId) {
    if (_loadingVehicles) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Vehicle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_vehicles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'No vehicles found. Please add a vehicle on the home dashboard first.',
                style: TextStyle(color: Colors.amber),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeVehicleId,
                  dropdownColor: const Color(0xFF1E1E24),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: _vehicles.map((v) {
                    return DropdownMenuItem<String>(
                      value: v.id,
                      child: Text('${v.displayName} (${v.plateNumber})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedVehicleId = val;
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Describe the Symptom or Issue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _symptomController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'e.g., "Hearing a squealing noise when braking at low speeds"',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _diagnosing ? null : _runDiagnosis,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _diagnosing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Analyze & Diagnose',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          if (_diagnosing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Analyzing symptoms with AI agent...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          if (_diagnosticError != null) ...[
            _buildErrorCard(_diagnosticError!),
            const SizedBox(height: 16),
          ],
          if (_diagnosis != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.smart_toy_outlined,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Diagnostic Report',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _cleanText(_diagnosis!),
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
