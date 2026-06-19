const String documentsDirectory = '/storage/emulated/0/Documents/NITM';
const String githubRepoUrl = "https://github.com/deskbtm/nitmgpt";

/// Supply at build time: `--dart-define=OPENAI_API_KEY=sk-...`
const String openAiApiKey = String.fromEnvironment(
  'OPENAI_API_KEY',
  defaultValue: '',
);

/// Optional HuggingFace token for gated model downloads.
/// Supply at build time: `--dart-define=HUGGING_FACE_TOKEN=hf_...`
const String huggingFaceToken = String.fromEnvironment(
  'HUGGING_FACE_TOKEN',
  defaultValue: '',
);

const String MY_GITHUB_NAME = "Nawbc";
const String REPO_NAME = "deskbtm/nitmgpt";
