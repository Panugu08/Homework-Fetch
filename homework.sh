#!/bin/bash

# Trigger the API download if assignments.json is doesn't exist yet or if the user typed --refresh
if [ ! -f "assignments.json" ] || [ "$1" == "--refresh" ]; then
    # Only loads the cookies.txt if it exists to make sure the program doesn't crash when fetching data from the api
    if [ -f "cookies.txt" ]; then
        source cookies.txt
    else 
        echo "Error: Missing cookies.txt file. Please follow the directions in the README file and create cookies.txt"
        exit 1
    fi

    # Verify the Cookie String is actually loaded so that the program doesn't crash when trying to fetch data from the api
    if [ -z "$FULL_COOKIE_STRING" ]; then
        echo "Error: Missing cookies. Please add the Full Cookie String to cookies.txt"
        exit 1
    fi

    # Creates a user agent that allows us to access the api by ensuring that Brightspace treats the script like a normal human user
    USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36"

    # Grabs Course IDs so that we can fetch the assignments for each active course that the user has on Brightspace
    COURSE_IDS=$(curl -s -H "user-agent: $USER_AGENT" -b "$FULL_COOKIE_STRING" "https://purdue.brightspace.com/d2l/api/lp/1.33/enrollments/myenrollments/?isActive=true" | jq -r '.Items[] | select(.OrgUnit.Type.Code == "Course Offering") | .OrgUnit.Id' 2>/dev/null)

    # If COURSE_IDS is empty, the cookies are likely expired or invalid
    if [ -z "$COURSE_IDS" ]; then
        echo "❌ Error: Failed to fetch course data. Your session cookies are likely invalid or expired."
        echo "Please log into Brightspace, copy a fresh cookie string, and update cookies.txt. (Follow the instructions in the README file)"
        exit 1
    fi

    # Clear out the old assignments.json file or create a it if it doesn't already exist
    > assignments.json
    
    # Loops through each Course ID, fetches their assignment data from their event calendar and then appends the raw JSON data to assignment.json
    for ID in $COURSE_IDS; do
        curl -s -H "user-agent: $USER_AGENT" -b "$FULL_COOKIE_STRING" "https://purdue.brightspace.com/d2l/api/le/1.33/$ID/calendar/events/" | jq '.' >> assignments.json
        # Adds a delay to each request so that Brightspace doesn't get bombarded by requests and temporarily ban us
        sleep 0.5
    done 
fi 

# Grabs the current date so it can be used to filter out assignments past their due date
CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Calculates the date 7 days from current date for both Linux and macOS.
if date --version >/dev/null 2>&1; then
    MAX_DATE=$(date -u -d "+7 days" +"%Y-%m-%dT%H:%M:%S.000Z")
else 
    MAX_DATE=$(date -u -v+7d +"%Y-%m-%dT%H:%M:%S.000Z")
fi


# Gets assignments, sorts them chronologically, and applies color-coding based on urgency
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
     else "Due in \($diff / 86400 | floor) days" end) as $countdown | 
    "\($color)\($countdown)\u001b[0m  |  \u001b[1;38;2;235;219;178m\(.Title)\u001b[0m \u001b[38;2;150;150;150m(\(.EndDateTime[0:19] + "Z" | fromdateiso8601 | localtime | strftime("%B %d at %I:%M %p")))\u001b[0m"' \
    assignments.json)
    
echo -e "\n\033[1;38;2;214;180;131mUpcoming Assignments (Next 7 Days):\033[0m"
echo -e "-------------------------------------"

# Tells the user they have no upcoming assignments or prints out a list of their upcoming assignments
if [ -z "$UPCOMING_ASSIGNMENTS" ]; then
    echo -e "\033[1;32mNo upcoming assignments due on Brightspace in the next 7 days!\033[0m"
else
    echo -e "$UPCOMING_ASSIGNMENTS"
fi

echo -e "-------------------------------------"
echo ""