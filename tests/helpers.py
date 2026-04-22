import json
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run_chezmoi(*args, input_text=None):
    command = ["chezmoi", "execute-template", "--source", str(ROOT), *args]
    result = subprocess.run(
        command,
        input=input_text,
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout


def load_yaml_as_json(path):
    template = "{{ include %s | fromYaml | toJson }}" % json.dumps(path)
    return json.loads(run_chezmoi(input_text=template))


def render_template(path, override_data):
    with tempfile.NamedTemporaryFile(
        "w", suffix=".json", encoding="utf-8", delete=False
    ) as handle:
        json.dump(override_data, handle)
        handle.flush()
        temp_path = handle.name
    try:
        return run_chezmoi("--override-data-file", temp_path, "--file", path)
    finally:
        Path(temp_path).unlink(missing_ok=True)


def load_fixture(path):
    return (ROOT / path).read_text(encoding="utf-8")


def write_fixture(path, content):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
