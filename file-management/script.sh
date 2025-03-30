#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Catch pipeline errors
set -x  # Debug mode (optional, remove if not needed)

# Function to display usage information
usage() {
    echo "Usage: $0 --dir1 <directory1> --dir2 <directory2> --file <filename>"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dir1) DIR1="$2"; shift ;;
        --dir2) DIR2="$2"; shift ;;
        --file) FILENAME="$2"; shift ;;
        *) usage ;;  # Invalid argument
    esac
    shift
done

# Validate input parameters
if [[ -z "$DIR1" || -z "$DIR2" || -z "$FILENAME" ]]; then
    echo "Error: Missing required arguments"
    usage
fi

# Create directories if they don’t exist
mkdir -p "$DIR1"
echo "Directory $DIR1 created or already exists."

mkdir -p "$DIR2"
echo "Directory $DIR2 created or already exists."

# Create file inside DIR1
FILE_PATH="$DIR1/$FILENAME"
touch "$FILE_PATH"
echo "File $FILENAME created inside $DIR1."

# Write sample content into the file
echo "#!/bin/bash" > "$FILE_PATH"
echo "# This is an auto-generated script" >> "$FILE_PATH"
echo "echo 'Hello, this script was created dynamically!'" >> "$FILE_PATH"
chmod +x "$FILE_PATH"
echo "Sample script written inside $FILENAME."

# Move file to DIR2
mv "$FILE_PATH" "$DIR2/"
echo "File $FILENAME moved to $DIR2."

# List contents of DIR2 to confirm move
echo "Contents of $DIR2:"
ls -lh "$DIR2"

echo "File management operations completed successfully."

