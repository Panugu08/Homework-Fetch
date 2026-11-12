#!/bin/bash

# Checks if assignment.json already exists. If it doesn't the script will fetch the json data and add it to assignments.json
# If it already exists, the script will skip to using the existing data to print out upcoming assignments
if [ ! -f "assignments.json" ]; then
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

    # Creates a user agent that allows us to access the apid by ensuring that Brightspace treats the script like a normal human user
    USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36"

    # Grabs Course IDs so that we can fetch the assignments for each active course that the user has on Brightspace
    COURSE_IDS=$(curl -s -H "user-agent: $USER_AGENT" -b "$FULL_COOKIE_STRING" "https://purdue.brightspace.com/d2l/api/lp/1.33/enrollments/myenrollments/?isActive=true" | jq -r '.Items[] | select(.OrgUnit.Type.Code == "Course Offering") | .OrgUnit.Id')

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
CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Gets all of the assignments in the assignments.json file
# Removes the quotes from text in the json file, passes in the Current date as an argument, 
# selects assignments that are not past due, and then sorts all of them by due date
jq -r --arg now "$CURRENT_DATE" '.[] | select(.EventType == 6 and .EndDateTime != null and .EndDateTime > $now) | "\(.EndDateTime)  |  \(.Title)"' assignments.json | sort


    
