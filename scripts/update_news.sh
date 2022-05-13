#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# Script to move new news epubs to Dropbox folder, and remove old news from the Dropbox folder.

max_num_days=7
news_folder="$HOME/devel/rpi-books/fetched-news"
dropbox_folder="$HOME/dropbox-books-henrik"
#sources=( "The Economist" "Le Monde" "FAZ" "人民日报" )
sources=("The Economist" "人民日报" "Le Monde" "联合早报网 zaobao.com" "Zeit Online" "Spiegel Online RSS - German alle Themen")

echo ""
echo "Considering the following news sources: ${sources[@]}."
echo "Searching for new news epubs in directory $news_folder, which will also be cleaned."
echo "News will be moved to directory $dropbox_folder, which will also be cleaned."

# If new epubs exist, add them to Dropbox. Use -print0 to handle paths containing spaces.
to_copy_array=()
for source in "${sources[@]}"; do
    find "$dropbox_folder" -name "*$source*" -mtime +$max_num_days -type f -print -exec rm -rv "{}" \;
    find "$news_folder" -name "*$source*" -mtime +$max_num_days -type f -print -exec rm -rv "{}" \;
    while IFS=  read -r -d $'\0'; do
        to_copy_array+=("$REPLY")
    done < <(find "$news_folder" -name "*$source*.epub" -type f -print0)
done

# Use the -n flag to not overwrite existing.
if (( ${#to_copy_array[@]} != 0 )); then
    cp -n -v "${to_copy_array[@]}" "$dropbox_folder"
fi
echo "Copied ${#to_copy_array[@]} epubs to $dropbox_folder."

echo "Cron job to update news completed at $(date)."
