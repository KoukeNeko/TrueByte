# TrueByte

TrueByte is a native macOS media verification app inspired by the workflow of
H2testw: write deterministic test files to a selected folder or volume, read the
data back, and report whether the storage returned exactly what was written.

It is built for the practical problem H2testw became famous for: checking USB
sticks, SD cards, external SSDs, adapters, and other mounted storage for fake
capacity, corruption, bad addressing, unstable writes, or suspiciously unreliable
media behavior.

## Why It Exists

Fake or failing flash media often looks normal at first. It may mount, report a
reasonable capacity, and accept files, while silently losing data after a certain
point. TrueByte tests the storage through the filesystem in the same spirit as
H2testw and F3:

- It writes `.h2w` test files into the selected target.
- It fills each file with deterministic, verifiable data.
- It reads the files back and compares the returned bytes.
- It reports speed, progress, corruption categories, and the first error.
- It leaves the test files in place so you can verify them again later.

TrueByte does not do destructive raw device probing. It works on mounted
folders and volumes through normal macOS file access.

## Current Status

TrueByte is an early macOS implementation with a usable GUI and a working
H2-style write and verify engine.

Important compatibility note:

TrueByte writes H2-style `.h2w` files with the same broad structure described in
the H2testw readme: numbered files, 1 MiB chunks, up to 1 GiB per file, and a
512-byte sector header containing the global offset in little-endian form.
However, the pseudo-random payload generator is independently implemented. That
means TrueByte is self-consistent, but it should not yet be treated as
byte-compatible with Windows H2testw or F3 output.

## Features

- Native SwiftUI macOS interface.
- Select any writable folder or mounted volume.
- Write + Verify mode for first-time tests.
- Verify Only mode for previously generated TrueByte `.h2w` files.
- Optional "use all available space" testing with a filesystem safety reserve.
- Progress for the whole test and the current file.
- Write speed, read speed, elapsed time, and estimated remaining time.
- Visible flushing state when file data is being synchronized to media.
- Stall messaging when no byte progress is detected for a while.
- Error report with lost data, overwritten sectors, slightly changed sectors,
  corrupted sectors, aliased bytes, and first-error details.
- Read/write sandbox entitlement for user-selected folders.
- Project-local run script for repeatable build and launch.

## Quick Start

1. Open TrueByte.
2. Click `Select Target`.
3. Choose the USB drive, SD card, external disk, or folder you want to test.
4. For a first test, choose `Write + Verify`.
5. Choose a test size:
   - Use a small size such as `1 GiB` for a quick smoke test.
   - Enable `Use all available space` for a full-capacity test.
6. Click `Start`.
7. Wait for writing and verification to finish.
8. Read the result.
9. Delete the `.h2w` files with `Clear .h2w` when you no longer need them.

## Modes

### Write + Verify

Use this for a new test.

TrueByte writes numbered `.h2w` files such as:

```text
1.h2w
2.h2w
3.h2w
```

Then it immediately reads those files back and verifies the contents.

### Verify Only

Use this only when the target already contains numbered TrueByte `.h2w` files.

If there are no numbered `.h2w` files, verification will fail with:

```text
No numbered .h2w files were found.
```

That is expected. `Verify Only` is for re-checking existing test files, not for
starting a new storage test.

## Understanding Results

### Passed

The data read back matched the data TrueByte expected for the tested range.

This is a good sign, but it does not prove the device will never fail. It means
the tested filesystem path, adapter, connection, and storage media behaved
correctly during this run.

### Failed

The media did not return the exact bytes that were written.

Possible causes include:

- Fake-capacity flash media.
- Bad flash blocks.
- Addressing errors.
- Unstable USB or SD adapters.
- Bad cables or ports.
- A storage controller that stalls or retries heavily.
- Filesystem or device disconnection during the test.

If a test fails, repeat it after formatting the media, using a different port,
reader, cable, or adapter.

## What The Error Counters Mean

- `Data Lost`: bytes that could not be read back as expected.
- `Overwritten`: sectors that appear to contain data from a different offset.
- `Slightly Changed`: sectors with only a few changed bits.
- `Corrupted`: sectors with broader byte differences.
- `Aliased`: estimated bytes whose offsets suggest address aliasing.
- `First Error`: the first offset where TrueByte observed a mismatch.

These categories are inspired by the classic H2testw style of reporting. They
are intended to help you tell the difference between a small bit flip, a broad
corruption pattern, and an address wrap or aliasing pattern.

## Safety Model

TrueByte is designed to be conservative:

- It writes only regular files inside the selected target.
- It does not overwrite unrelated files.
- It refuses to start a Write + Verify run if `.h2w` files already exist.
- It does not require administrator privileges.
- It does not perform raw block-device writes.
- In full-space mode it keeps a small free-space reserve for filesystem safety.

Still, use care:

- Test suspect media when it is empty.
- Do not test important data in place.
- Do not unplug the device during a write, flush, or verify pass.
- Expect full-capacity tests to take a long time on slow flash media.

## Why Progress Can Pause

Flash media often writes quickly for a while, then slows down or appears to
pause. TrueByte now shows that state more clearly:

- `Flushing file data to media` means the app is synchronizing a completed file.
- A long flushing message means the storage is taking longer than usual.
- A no-byte-progress warning means the device may be retrying writes or has
  temporarily stopped responding.

A pause does not always mean the app is frozen. It can be a real storage or USB
controller behavior.

## Build And Run

The project is an Xcode macOS app.

Requirements:

- macOS 14 or newer target.
- Xcode with SwiftUI macOS support.

Run from the repository root:

```bash
./script/build_and_run.sh
```

Verify that the app builds and launches:

```bash
./script/build_and_run.sh --verify
```

Build without launching:

```bash
xcodebuild \
  -project TrueByte.xcodeproj \
  -scheme TrueByte \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath build/DerivedData \
  build
```

The Codex app Run action is wired through:

```text
.codex/environments/environment.toml
script/build_and_run.sh
```

## Project Structure

```text
TrueByte/
  App/
    TrueByteApp.swift
  Models/
    StorageModels.swift
  Services/
    StorageTestEngine.swift
  Stores/
    TestController.swift
  Support/
    ByteCountFormat.swift
    FocusedCommands.swift
    H2WFileScanner.swift
  Views/
    ContentView.swift
    ProgressPanelView.swift
    ReportPanelView.swift
    TargetPanelView.swift
script/
  build_and_run.sh
.codex/
  environments/
    environment.toml
```

## Architecture

TrueByte keeps UI, orchestration, and media testing separate:

- `TrueByteApp` defines the macOS scene and default window size.
- `ContentView` composes the split layout.
- `TargetPanelView` owns target selection, mode, size, and primary actions.
- `ProgressPanelView` presents stable progress and activity messaging.
- `ReportPanelView` presents the verification report and log.
- `TestController` bridges SwiftUI state to the background test engine.
- `StorageTestEngine` owns file planning, writing, flushing, verifying, and
  error classification.
- `H2WFileScanner` finds existing `.h2w` files.

The storage test runs in a detached background task. UI progress updates are
throttled so heavy I/O does not flood SwiftUI with updates.

## Test File Format

TrueByte writes data in 1 MiB chunks. Each `.h2w` file is at most 1 GiB.

Within the generated data, each 512-byte sector begins with an 8-byte
little-endian global offset. The remaining bytes are filled with deterministic
pseudo-random data derived from that offset.

This makes each sector independently checkable and helps identify whether a
sector was altered, lost, or replaced by data from a different address.

## Limitations

- Not a raw block-device capacity probe.
- Not currently byte-compatible with Windows H2testw or F3 payloads.
- Cannot prove future reliability after the test completes.
- Full-space tests can take a long time.
- macOS sandbox access is limited to user-selected folders and volumes.

## References

- H2testw by Harald Boegeholz / c't magazine:
  https://www.heise.de/download/product/h2testw-50539
- H2testw readme:
  https://h2testw.com/wp-content/uploads/readme.txt
- F3, Fight Flash Fraud:
  https://github.com/AltraMayor/f3

## License

TrueByte is released under the MIT License. See `LICENSE`.
