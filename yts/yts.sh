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
