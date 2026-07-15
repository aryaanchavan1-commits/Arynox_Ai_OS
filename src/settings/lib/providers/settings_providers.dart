import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentSettingsPageProvider = StateProvider<String>((ref) => 'home');

// AI Settings
enum AiProvider {
  groq,
  openai,
  anthropic,
  gemini,
  openRouter,
  ollama,
  lmStudio,
  custom,
}

enum AiMode { local, cloud, hybrid }

class AiSettings {
  final AiProvider defaultProvider;
  final String providerApiKey;
  final String providerBaseUrl;
  final String preferredModel;
  final double temperature;
  final int maxTokens;
  final bool streaming;
  final bool reasoningMode;
  final bool vision;
  final bool voice;
  final bool memory;
  final int contextLength;
  final AiMode mode;
  final bool encryptKeys;

  const AiSettings({
    this.defaultProvider = AiProvider.groq,
    this.providerApiKey = '',
    this.providerBaseUrl = '',
    this.preferredModel = 'llama3-70b-8192',
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.streaming = true,
    this.reasoningMode = false,
    this.vision = true,
    this.voice = true,
    this.memory = true,
    this.contextLength = 8192,
    this.mode = AiMode.hybrid,
    this.encryptKeys = true,
  });
}

final aiSettingsProvider = StateProvider<AiSettings>((ref) => const AiSettings());

class SettingsState {
  final bool darkMode;
  final bool reducedMotion;
  final double textScale;
  final String language;
  final bool autoUpdate;
  final bool telemetry;

  const SettingsState({
    this.darkMode = true,
    this.reducedMotion = false,
    this.textScale = 1.0,
    this.language = 'en',
    this.autoUpdate = true,
    this.telemetry = false,
  });
}

final settingsStateProvider = StateProvider<SettingsState>((ref) => const SettingsState());
