import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

class Settings extends ChangeNotifier {
  Settings({
    String baseUrl = "http://localhost:11434",
    String model = "llama3.2",
    String theme = "dark",
    String systemPrompt = "You are DanyAI, a helpful assistant.",
    double temperature = 0.7,
    int numCtx = 4096,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.1,
  }) : _baseUrl = baseUrl,
       _model = model,
       _theme = theme,
       _systemPrompt = systemPrompt,
       _temperature = temperature,
       _numCtx = numCtx,
       _topP = topP,
       _topK = topK,
       _repeatPenalty = repeatPenalty;

  String _baseUrl;
  String _model;
  String _theme;
  String _systemPrompt;
  double _temperature;
  int _numCtx;
  double _topP;
  int _topK;
  double _repeatPenalty;

  String get baseUrl => _baseUrl;
  set baseUrl(String v) {
    _baseUrl = v;
    save();
  }

  String get model => _model;
  set model(String v) {
    _model = v;
    save();
  }

  String get theme => _theme;
  set theme(String v) {
    _theme = v;
    save();
  }

  String get systemPrompt => _systemPrompt;
  set systemPrompt(String v) {
    _systemPrompt = v;
    save();
  }

  double get temperature => _temperature;
  set temperature(double v) {
    _temperature = v;
    save();
  }

  int get numCtx => _numCtx;
  set numCtx(int v) {
    _numCtx = v;
    save();
  }

  double get topP => _topP;
  set topP(double v) {
    _topP = v;
    save();
  }

  int get topK => _topK;
  set topK(int v) {
    _topK = v;
    save();
  }

  double get repeatPenalty => _repeatPenalty;
  set repeatPenalty(double v) {
    _repeatPenalty = v;
    save();
  }

  static Future<Settings> load() async {
    final p = await SharedPreferences.getInstance();
    return Settings(
      baseUrl: p.getString("url") ?? "http://localhost:11434",
      model: p.getString("mod") ?? "llama3.2",
      theme: p.getString("thm") ?? "dark",
      systemPrompt: p.getString("sys") ?? "You are DanyAI, a helpful assistant.",
      temperature: p.getDouble("tmp") ?? 0.7,
      numCtx: p.getInt("ctx") ?? 4096,
      topP: p.getDouble("tpp") ?? 0.9,
      topK: p.getInt("tpk") ?? 40,
      repeatPenalty: p.getDouble("rpp") ?? 1.1,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString("url", _baseUrl);
    await p.setString("mod", _model);
    await p.setString("thm", _theme);
    await p.setString("sys", _systemPrompt);
    await p.setDouble("tmp", _temperature);
    await p.setInt("ctx", _numCtx);
    await p.setDouble("tpp", _topP);
    await p.setInt("tpk", _topK);
    await p.setDouble("rpp", _repeatPenalty);
    notifyListeners();
  }
}
