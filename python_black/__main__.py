"""A shim to black which knows how to tee output for --output-file."""

import argparse
import sys
from os import getenv
from types import TracebackType
from typing import Type, TextIO, Optional, cast

from black import nullcontext, patched_main

parser = argparse.ArgumentParser()
parser.add_argument("--output-file", default=None)


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
                failure_msg = getenv("BLACK_FAILURE_MSG")
                if failure_msg:
                    print(f"{'':*^80}", file=sys.stderr)
                    print(
                        failure_msg,
                        file=sys.stderr,
                    )
                    print(f"{'':*^80}", file=sys.stderr)
            raise
