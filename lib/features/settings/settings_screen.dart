import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/secure_storage_helper.dart';
import 'keys_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _geminiController = TextEditingController();
  final _deepseekController = TextEditingController();
  final _openrouterController = TextEditingController();

  bool _obscureGemini = true;
  bool _obscureDeepseek = true;
  bool _obscureOpenrouter = true;

  @override
  void dispose() {
    _geminiController.dispose();
    _deepseekController.dispose();
    _openrouterController.dispose();
    super.dispose();
  }

  void _saveKey(String keyType, String value) async {
    await ref.read(keysProvider.notifier).saveKey(keyType, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกคีย์สำเร็จแล้ว!'),
          backgroundColor: AppTheme.emerald400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keysState = ref.watch(keysProvider);

    // Sync values once loaded
    if (!keysState.isLoading) {
      if (_geminiController.text.isEmpty && keysState.gemini.isNotEmpty) {
        _geminiController.text = keysState.gemini;
      }
      if (_deepseekController.text.isEmpty && keysState.deepseek.isNotEmpty) {
        _deepseekController.text = keysState.deepseek;
      }
      if (_openrouterController.text.isEmpty && keysState.openrouter.isNotEmpty) {
        _openrouterController.text = keysState.openrouter;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าระบบ & API Keys', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: keysState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Card(
                    color: AppTheme.indigo600.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppTheme.indigo600.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '🛡️ ข้อมูลความปลอดภัยของ API Keys',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.indigo500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'คีย์ทั้งหมดจะถูกบันทึกไว้ในหน่วยความจำเข้ารหัส (Secure Storage) ภายในโทรศัพท์มือถือของคุณโดยตรง ข้อมูลจะไม่ถูกส่งไปยังเซิร์ฟเวอร์ภายนอกใดๆ และจะถูกใช้สำหรับการส่งขอบริการจากมือถือของคุณโดยตรงเท่านั้น',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'การตั้งค่า API Keys',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate100,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Gemini Key Card
                  _buildKeyCard(
                    title: 'Google Gemini API Key',
                    description: 'สำหรับใช้งานโมเดล Gemini 2.5 Flash ในระบบแชทและการแปลข่าวสารภาษาไทยโดยอัตโนมัติ (รับคีย์ฟรีจาก Google AI Studio)',
                    controller: _geminiController,
                    obscureText: _obscureGemini,
                    onToggleObscure: () => setState(() => _obscureGemini = !_obscureGemini),
                    onSave: () => _saveKey(SecureStorageHelper.geminiKey, _geminiController.text.trim()),
                  ),
                  const SizedBox(height: 16),

                  // DeepSeek Key Card
                  _buildKeyCard(
                    title: 'DeepSeek Official API Key',
                    description: 'สำหรับเชื่อมต่อกับ API ทางการของ DeepSeek โดยตรง (แบบเติมเงินมีความเร็วและความเสถียรสูง)',
                    controller: _deepseekController,
                    obscureText: _obscureDeepseek,
                    onToggleObscure: () => setState(() => _obscureDeepseek = !_obscureDeepseek),
                    onSave: () => _saveKey(SecureStorageHelper.deepseekKey, _deepseekController.text.trim()),
                  ),
                  const SizedBox(height: 16),

                  // OpenRouter Key Card
                  _buildKeyCard(
                    title: 'OpenRouter API Key',
                    description: 'สำหรับเชื่อมต่อโมเดลรุ่นฟรีของ DeepSeek V4 หรือ Qwen 3 (สมัครคีย์ได้ที่ openrouter.ai)',
                    controller: _openrouterController,
                    obscureText: _obscureOpenrouter,
                    onToggleObscure: () => setState(() => _obscureOpenrouter = !_obscureOpenrouter),
                    onSave: () => _saveKey(SecureStorageHelper.openrouterKey, _openrouterController.text.trim()),
                  ),
                  const SizedBox(height: 32),

                  // Reset All Card
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('ล้างข้อมูลคีย์ทั้งหมด?'),
                            content: const Text('คุณต้องการลบ API Keys ทั้งหมดที่บันทึกไว้ในโทรศัพท์เครื่องนี้หรือไม่? เมื่อลบแล้วฟีเจอร์ AI จะไม่สามารถทำงานได้ชั่วคราว'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('ยกเลิก', style: TextStyle(color: AppTheme.slate400)),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(keysProvider.notifier).clearAll();
                                  _geminiController.clear();
                                  _deepseekController.clear();
                                  _openrouterController.clear();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ลบข้อมูลคีย์ทั้งหมดเรียบร้อยแล้ว'),
                                      backgroundColor: AppTheme.rose400,
                                    ),
                                  );
                                },
                                child: const Text('ยืนยันการลบ', style: TextStyle(color: AppTheme.rose400)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_forever, color: AppTheme.rose400),
                      label: const Text(
                        'ล้างคีย์ทั้งหมดออกจากระบบ',
                        style: TextStyle(color: AppTheme.rose400, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildKeyCard({
    required String title,
    required String description,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required VoidCallback onSave,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.slate100,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.slate400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      hintText: 'กรอก API Key ของคุณที่นี่',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.slate400,
                          size: 20,
                        ),
                        onPressed: onToggleObscure,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.indigo600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('บันทึก', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
