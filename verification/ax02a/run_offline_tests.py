"""Run AX-02A offline tests in a new, preserved artifact directory; no cleanup."""
import argparse
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--pattern', default='test_*.py')
    args = parser.parse_args()
    output = (ROOT / args.output).resolve()
    if not output.is_relative_to(ROOT / '.runtime'):
        raise ValueError('test artifacts must remain inside this repository .runtime')
    output.mkdir(parents=True, exist_ok=False)
    original = tempfile.mkdtemp

    def kept(suffix=None, prefix=None, dir=None):
        # All temporary calls, including old tests' explicit dirs, stay here.
        return original(suffix=suffix or '', prefix=prefix or 'case_', dir=output)

    class PreservedDirectory:
        def __init__(self, suffix=None, prefix=None, dir=None, **kwargs):
            self.name = kept(suffix, prefix, dir)

        def __enter__(self):
            return self.name

        def __exit__(self, *args):
            pass

        def cleanup(self):
            pass

    # Test-process adaptation only: do not change production or old test code.
    tempfile.mkdtemp = kept
    tempfile.TemporaryDirectory = PreservedDirectory
    suite = unittest.defaultTestLoader.discover(str(Path(__file__).parent), pattern=args.pattern)
    with (output / 'tests.txt').open('w', encoding='utf-8', newline='\n') as stream:
        result = unittest.TextTestRunner(stream=stream, verbosity=2).run(suite)
    summary = dict(tests=result.testsRun, failures=len(result.failures), errors=len(result.errors),
                   skipped=len(result.skipped), failed_cases=[str(t) for t, _ in result.failures],
                   error_cases=[str(t) for t, _ in result.errors], artifacts=str(output),
                   deletion='NONE', hardware='NONE')
    (output / 'summary.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8', newline='\n')
    print(json.dumps(summary, indent=2))
    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    raise SystemExit(main())
