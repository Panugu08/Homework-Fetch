# Homework-Fetch

A Bash Script that can fetch upcoming assignments from Brightspace and display them within the terminal.

## The Problem/Project Goal

I'm trying to solve the hassle of having to log in to Brightspace multiple times a day to check my assignments. I often have to do this to avoid forgetting about assignments. I wrote this Bash script to solve this problem by fetching upcoming assignments from Brightspace and displaying them within the terminal. This means I don't have to sign in to Brightspace all the time anymore since I can just check my assignments by running this script.

## How It Works

**The First Time the script is run:**
1. Reads session cookies from a local cookies.txt file.
2. Fetches raw JSON data from the Brightspace REST API using curl.
3. Caches the data locally in the assignments.json file.
4. Extracts assignments and their details from assignments.json using jq.
5. Compares due dates of each assignment against the system timestamp using the date command and drops assignments that are past due.
6. Formats and prints a clean list of assignments in chronological order that are due within 7 days.

**Every other time the script is run:** \
Skips steps 1-3 from above and goes straight to step four since the assignments.json file already exists and already contains the assignment data.

![System diagram](FlowChart.png)

## Tech Stack

- **Language**: Bash
- **Commands/Utilities**:
  - curl: Execute HTTP requests and attach session cookies for authentication.
  - jq: Extracting the relevant fields of the API's JSON file.
  - date: Filter assignments by the date string given by the API's JSON file.
- **Data Storage**:
  - A local JSON file called "assignments.json" will act as a cache to store the fetched assignments.
  - A local txt file called "cookies.txt" will securely store session cookies.
  - Both of these files are never commited to github and are included in .gitignore
- **External Source**: The Brightspace REST API
  - Will be accessed using curl get requests using the manually pasted cookies in cookies.txt.

## Prerequisites

Before running the script, ensure you have **Git** and **jq** installed:
- **macOS:** `brew install git jq` 
- **Windows (PowerShell):** `winget install Git.Git jqlang.jq` (Run the script using **Git Bash**)
- **Linux:** Install git, curl, and jq via your distribution's package manager (for example, on Ubuntu/Debian: `sudo apt install git curl jq`)

## Setup Instructions
1. **Clone the repository:**
   ```bash
   git clone https://github.com/Panugu08/Homework-Fetch.git
   cd Homework-Fetch
   ```
2. **Get your Brightspace session cookies:**
  - Log into Brightspace on your browser.
  - Open the Developer Tools (right-click and choose **Inspect**), navigate to the **Network** tab located on the very top menu bar, and refresh the page.
  - Switch to the **Console** tab which is also located on the top menu bar, type `fetch('/d2l/api/lp/1.33/users/whoami')`, and hit Enter.
  - Go back to the **Network** tab and find the **Filter** text box near the top.
  - Type `whoami` in the **Filter** text box
  - Right-click the `whoami` request that appears, hover over **Copy**, and select **Copy as cURL** or **Copy as cURL (bash)**.

3. **Configure `cookies.txt`:**
  - Paste the copied text from the previous step into a notepad and find the massive string next to the `-b` flag. 
  - Copy just the text _inside_ the single quotes (`'...'`). This is your `FULL_COOKIE_STRING`.
  - Rename the `cookies.example.txt` in this folder to `cookies.txt` and paste your string into the given template.
  - **Do not make any other changes to the `cookies.txt` file**
  - *(Security Note: Never share your `cookies.txt` file or commit it to GitHub—it grants full access to your Brightspace account.)*

4. **Run the script:**
   ```bash
   chmod +x homework.sh
   ./homework.sh
   ```
    - Use the **Terminal** to run this on Mac or Linux
    - Use the **Git Bash** app to run this on Windows

**Example Runs**

1. Working Example
    ```
    Upcoming Assignments (Next 7 Days):
    -------------------------------------
    Due in 6 days  |  Ch 9 Pt 4 - lecture 36 - climate change (November 30 at 01:30 PM)
    -------------------------------------
    ```

2. Invalid Session Cookies Example:
    ```
    ❌ Error: Failed to fetch course data. Your session cookies are likely invalid or expired.
    Please log into Brightspace, copy a fresh cookie string, and update cookies.txt. (Follow the instructions in the README file)
    ```


## How to Refresh Assignment data

1. Follow steps 2 and 3 from the setup instructions to update cookies.txt with the new session cookies from Brightspace
2. Then, run the script using the "--refresh" argument
  ```bash
    ./homework.sh --refresh
  ```

## Demo
- [Demo Video]()

## Future Plans

- [ ] **Browser Extension Support**: Use a browser extension to get the necessary cookies so that the user doesn't have to manually paste their session cookies into cookies.txt
- [x] **Color coding**: Color coded terminal output based on urgency (Ex: Red for due in 24 hrs)
- [x] **Due date countdowns**: Text displaying "Due in X hours/days" in front of each upcoming assignment
- [ ] **Auto run**: Make the script run automatically when the terminal is opened
- [ ] **Mark as Complete**: Allowing the user to mark completed assignments as complete so that they don't show up again


## Author
Pranay Anugu, [github.com/Panugu08](https://github.com/Panugu08).