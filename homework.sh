#!/bin/bash

if [ ! -f "assignments.json" ] || [ "$1" == "--refresh" ]; then
    if [ -f "cookies.txt" ]; then
        source cookies.txt
    else 
        echo "Error: Missing cookies.txt file. Please follow the directions in the README file and create cookies.txt"
        exit 1
    fi

    if [ -z "$FULL_COOKIE_STRING" ]; then
        echo "Error: Missing cookies. Please add the Full Cookie String to cookies.txt"
        exit 1
    fi

    USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36"

    COURSE_IDS=$(curl -s -H "user-agent: $USER_AGENT" -b "$FULL_COOKIE_STRING" "https://purdue.brightspace.com/d2l/api/lp/1.33/enrollments/myenrollments/?isActive=true" | jq -r '.Items[] | select(.OrgUnit.Type.Code == "Course Offering") | .OrgUnit.Id' 2>/dev/null)

    if [ -z "$COURSE_IDS" ]; then
        echo "❌ Error: Failed to fetch course data. Your session cookies are likely invalid or expired."
        echo "Please log into Brightspace, copy a fresh cookie string, and update cookies.txt. (Follow the instructions in the README file)"
        exit 1
    fi

    > assignments.json
    
    for ID in $COURSE_IDS; do
        curl -s -H "user-agent: $USER_AGENT" -b "$FULL_COOKIE_STRING" "https://purdue.brightspace.com/d2l/api/le/1.33/$ID/calendar/events/" | jq '.' >> assignments.json
        
        # Pause briefly between requests so Brightspace doesn't think 
        # we are a bot and block us for sending too many things at once.
        sleep 0.5
    done 
fi 

CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Linux and Mac computers handle date math differently, 
# so we check which system we're on to make sure this works on both.
if date --version >/dev/null 2>&1; then
    MAX_DATE=$(date -u -d "+7 days" +"%Y-%m-%dT%H:%M:%S.000Z")
else 
    MAX_DATE=$(date -u -v+7d +"%Y-%m-%dT%H:%M:%S.000Z")
fi


# We use jq to process the JSON data:
# 1. Select only actual homework/quizzes (EventType == 6) due within our 7-day window. 
# This ensures we don't get things that are not assignments like lectures and announcements.
# 2. Clean up date formats and turn them into numbers so we can easily find out
# how long before the assignment is due and use that to apply color coding
# 3. Calculates the due date counter by using the amount of time before an assignment is due
UPCOMING_ASSIGNMENTS=$(jq -r -s \
    --arg now "$CURRENT_DATE" \
    --arg max "$MAX_DATE" \
    '[ .[][] | select(.EventType == 6 and .EndDateTime != null and .EndDateTime > $now and .EndDateTime <= $max) ] | sort_by(.EndDateTime)[] | 
    (.EndDateTime[0:19] + "Z" | fromdateiso8601) as $due | 
    ($now[0:19] + "Z" | fromdateiso8601) as $curr | 
    ($due - $curr) as $diff | 
    (if $diff <= 86400 then "\u001b[38;2;204;119;102m" elif $diff <= 172800 then "\u001b[38;2;215;153;33m" else "\u001b[38;2;142;158;114m" end) as $color | 
    (if $diff < 3600 then "Due in < 1 hour"
    elif $diff < 86400 then "Due in \($diff / 3600 | floor) hours"
    elif $diff < 172800 then "Due in 1 day"
    else "Due in \($diff / 86400 | ceil) days" end) as $countdown | 
    "\($color)\($countdown)\u001b[0m  |  \u001b[1;38;2;235;219;178m\(.Title)\u001b[0m \u001b[38;2;150;150;150m(\(.EndDateTime[0:19] + "Z" | fromdateiso8601 | localtime | strftime("%B %d at %I:%M %p")))\u001b[0m"' \
    assignments.json)
    
echo -e "\n\033[1;38;2;214;180;131mUpcoming Assignments (Next 7 Days):\033[0m"
echo -e "-------------------------------------"

if [ -z "$UPCOMING_ASSIGNMENTS" ]; then
    echo -e "\033[1;32mNo upcoming assignments due on Brightspace in the next 7 days!\033[0m"
else
    echo -e "$UPCOMING_ASSIGNMENTS"
fi

echo -e "-------------------------------------"
echo ""