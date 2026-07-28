from pathlib import Path

for p in Path('lib/screens').rglob('*.dart'):
    text = p.read_text(encoding='utf-8')
    text = text.replace("import '../services/", "import '../../services/")
    text = text.replace("import '../widgets/", "import '../../widgets/")
    text = text.replace("import '../utils/", "import '../../utils/")
    text = text.replace("import '../data/", "import '../../data/")
    text = text.replace("import '../math/", "import '../math/")
    text = text.replace("import '../english/", "import '../english/")
    text = text.replace("import '../exams/", "import '../exams/")
    text = text.replace("import '../auth/", "import '../auth/")
    text = text.replace("import '../profile/", "import '../profile/")
    p.write_text(text, encoding='utf-8')
