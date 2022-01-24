"""A shim to black which knows how to tee output for --output-file."""

import argparse
import sys
from os import getenv
from os.path import dirname, join
from types import TracebackType
from typing import Type, TextIO, Optional, cast

from black import nullcontext, patched_main

parser = argparse.ArgumentParser()
parser.add_argument("--output-file", default=None)
parser.add_argument("--failure-message", default=None)

class LoadFromFile (argparse.Action):
    def __call__ (self, parser, namespace, values, option_string = None):
        # with open(join(dirname(dirname(dirname(dirname(__file__)))), values)) as f:
        with open(join(dirname(dirname(dirname(__file__))), values)) as f:
        # with open(join(dirname(__file__), values)) as f:
            # parse arguments in the file and store them in the target namespace
            parser.parse_args(f.read().splitlines(), namespace)

# Support passing args through a file so the aspect has access to configuration flags
parser.add_argument('--argsfile', action=LoadFromFile)


class Tee:
    """Something that looks like a File/Writeable but does teed writes."""

    def __init__(self, name: str, mode: str) -> None:
        self._file = open(name, mode)
        self._stdout = sys.stdout

    def __enter__(self) -> "Tee":
        sys.stdout = cast(TextIO, self)
        return self

    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType],
    ) -> Optional[bool]:
        sys.stdout = self._stdout
        self.close()
        return None

    def write(self, data: str) -> int:
        self._file.write(data)
        return self._stdout.write(data)

    def flush(self) -> None:
        self._file.flush()
        self._stdout.flush()

    def close(self) -> None:
        self._file.close()


if __name__ == "__main__":
    opts, args = parser.parse_known_args()

    if opts.output_file:
        print("Teeing output....")
        ctx = Tee(opts.output_file, "w")
    else:
        ctx = nullcontext()

    with ctx:
        sys.argv = [sys.argv[0]] + args
        try:
            patched_main()
        except SystemExit as e:
            if e.code == 1:
                failure_msg = opts.failure_message
                if failure_msg:
                    print(f"{'':*^80}", file=sys.stderr)
                    print(
                        failure_msg,
                        file=sys.stderr,
                    )
                    print(f"{'':*^80}", file=sys.stderr)
            raise
