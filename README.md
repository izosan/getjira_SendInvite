Deployment Calendar Invite Generator
A PowerShell tool that automatically creates calendar invites for ACE deployment live chat sessions by retrieving Jira issues for a specific release version.
Features
Retrieves Jira issues based on a specified release version
Creates a formatted HTML table with issue details
Generates an iCalendar (.ics) file with the meeting details
Sets the calendar invite as "Tentative"
Includes clickable links to Jira issues
Extracts the meeting date from the release version
Requirements
Windows operating system
PowerShell 5.1 or higher
Access to Jira REST API
Appropriate Jira API token
Installation
Clone this repository or download the files:
Get-JiraIssuesAndCreateCalendarInvite.ps1 (Main PowerShell script)
run_Get-JiraIssuesAndCreateCalendarInvite.bat (Batch file launcher)
JiraConfig.template.ps1 (Configuration template)
Create your configuration file:
Copy JiraConfig.template.ps1 to JiraConfig.ps1
Edit JiraConfig.ps1 with your Jira settings (see Configuration section)
Configuration
Create a JiraConfig.ps1 file based on the template with the following settings:
Security Note
The JiraConfig.ps1 file contains sensitive information and should not be committed to version control. It has been added to .gitignore to prevent accidental commits.
Usage
Using the Batch File
Double-click the run_Get-JiraIssuesAndCreateCalendarInvite.bat file
Enter the release version when prompted (e.g., W15.2025.04.09)
The script will retrieve Jira issues and create a calendar invite
The .ics file will be saved to your desktop and opened automatically
Using PowerShell Directly
Release Version Format
The release version should follow this format: W[week].[year].[month].[day]
Examples:
W14.2025.04.02
W15.2025.04.09
The date portion (year, month, day) is used to set the calendar invite date.
Troubleshooting
No Issues Found
If no issues are found, check:
The release version format
That issues exist with the specified fix versions
Your Jira API token permissions
API Errors
If you encounter API errors:
Verify your Jira base URL
Check your API token
Ensure the JQL query syntax is correct
Confirm the custom field ID is correct
Date Extraction Issues
If the date is not correctly extracted:
Ensure the release version follows the format W[week].[year].[month].[day]
Check the debug output for any regex matching errors
Customization
You can customize the script by modifying:
The JQL query to filter different issues
The HTML table styling
The calendar invite details (time, duration, etc.)
The message text in the calendar invite
Contributing
Contributions are welcome! Please feel free to submit a Pull Request.
License
This project is licensed under the MIT License - see the LICENSE file for details.
Acknowledgments
Thanks to the Jira REST API for making this automation possible
Inspired by the need to streamline deployment communication
