# yts

A bash function to download YouTube video transcripts and convert them to Markdown format.
Taken from [David Gasquez's](https://davidgasquez.com/useful-llm-tools-2024/) excellent [qv](https://github.com/davidgasquez/dotfiles/blob/bb9df4a369dbaef95ca0c35642de491c7dd41269/shell/zshrc#L75-L99) function.

## Installation

1. Install required dependencies:
```bash
# Install yt-dlp (see https://github.com/yt-dlp/yt-dlp?tab=readme-ov-file#installation)
brew install yt-dlp   # macOS
# or
uv pip install yt-dlp    # Using pip

# Install llm (see https://github.com/simonw/llm)
brew install llm     # macOS
# or
uv pip install llm   # Using pip
```

2. Install the vtt2md script:
```bash
sudo cp vtt2md.sh /usr/local/bin/vtt2md
sudo chmod 0755 /usr/local/bin/vtt2md
```

3. Add the following to your `.bashrc` or `.zshrc`:
```bash
# This is also in yts.sh
yts() {
  local url="$1"
  local output_file="${2:-transcript.md}"

  # Fetch subtitles from YouTube
  local subtitle_url=$(yt-dlp -q --skip-download --convert-subs srt --write-sub --sub-langs "en" --write-auto-sub --print "requested_subtitles.en.url" "$url")
  curl -o /tmp/subtitles.vtt -s "$subtitle_url"

  # Check if the content was retrieved successfully
  if [ ! -f "/tmp/subtitles.vtt" ]; then
    echo "Failed to retrieve subtitles from the URL."
    return 1
  fi

  # Convert VTT to Markdown
  vtt2md < /tmp/subtitles.vtt > "$output_file"

  # Check if the output file was created successfully
  if [ ! -f "$output_file" ]; then
    echo "Failed to create output file: $output_file"
    rm -f /tmp/subtitles.vtt
    return 1
  fi

  # Clean up temporary file
  rm -f /tmp/subtitles.vtt
  echo "Transcript saved to: $output_file"
}
```

## Usage

```bash
# output file is optional, if you leave it blank it will be transcript.md
yts "https://www.youtube.com/watch?v=VIDEO_ID" [output_file.md]
```

## License

MIT