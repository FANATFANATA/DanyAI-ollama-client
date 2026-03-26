import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

class Settings extends ChangeNotifier {
  Settings({
    this.baseUrl = "http://localhost:11434",
    this.model = "llama3.2",
    this.theme = "dark",
    this.systemPrompt = "You are DanyAI, a helpful assistant.",
    this.temperature = 0.7,
    this.numCtx = 4096,
    this.topP = 0.9,
    this.topK = 40,
    this.repeatPenalty = 1.1,
  });

  String baseUrl;
  String model;
  String theme;
  String systemPrompt;
  double temperature;
  int numCtx;
  double topP;
  int topK;
  double repeatPenalty;

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
    await p.setString("url", baseUrl);
    await p.setString("mod", model);
    await p.setString("thm", theme);
    await p.setString("sys", systemPrompt);
    await p.setDouble("tmp", temperature);
    await p.setInt("ctx", numCtx);
    await p.setDouble("tpp", topP);
    await p.setInt("tpk", topK);
    await p.setDouble("rpp", repeatPenalty);
    notifyListeners();
  }
}
