#!/bin/bash

# Create a temporary file for initial processing
temp_file=$(mktemp)

# Read from stdin and process
cat - | awk '
    # Skip headers and timestamps
    /^WEBVTT/ { next; }
    /^Kind:/ { next; }
    /^Language:/ { next; }
    /-->/ { next; }
    
    # Skip empty lines and lines with just numbers (cue identifiers)
    /^[ \t]*$/ { next; }
    /^[0-9]+$/ { next; }
    
    # We only get here with actual content lines
    {
        # Remove any HTML tags if present
        gsub(/<[^>]*>/, "", $0);
        
        # Skip if line became empty after tag removal
        if ($0 ~ /^[ \t]*$/) next;
        
        # This is actual subtitle text - print it
        print $0;
    }
' > "$temp_file"

# Second pass: Format into paragraphs and capitalize sentence beginnings
awk '
    BEGIN { paragraph = ""; }
    
    # Process each line of text
    {
        # Capitalize the first letter of lines that start paragraphs
        if (paragraph == "" || paragraph ~ /[.!?]$/) {
            # Capitalize the first letter if line starts with lowercase
            if ($0 ~ /^[a-z]/) {
                $0 = toupper(substr($0, 1, 1)) substr($0, 2);
            }
        }
        
        # Append to current paragraph
        if (paragraph == "") {
            paragraph = $0;
        } else if (paragraph ~ /[.!?]$/) {
            # Previous line ended with punctuation - start new paragraph
            print paragraph;
            print "";  # Empty line between paragraphs
            paragraph = $0;
        } else {
            # Continue same paragraph
            paragraph = paragraph " " $0;
        }
    }
    
    # Print final paragraph
    END {
        if (paragraph != "") {
            print paragraph;
        }
    }
' "$temp_file" > "${temp_file}.2"

# Clean up first temp file
rm "$temp_file"

# Ensure proper capitalization for all sentences within paragraphs
cat "${temp_file}.2" | awk '
    {
        # Capitalize after end of sentence punctuation
        line = $0;
        while (match(line, /[.!?] [a-z]/) > 0) {
            pos = RSTART + 2;
            line = substr(line, 1, pos-1) toupper(substr(line, pos, 1)) substr(line, pos+1);
        }
        print line;
    }
' > "${temp_file}.3"

REFORMATTING_PROMPT="Reformat the following text, add proper punctuation and line breaks between paragraphs. Sandgarden is a proper noun. Do not change the words or modify in any other way: $(cat "${temp_file}.3")"
llm "$REFORMATTING_PROMPT"

# Clean up remaining temp files
rm "${temp_file}.2" "${temp_file}.3"