<#
.SYNOPSIS
    Retrieves Jira issues and creates an iCalendar file with HTML formatted data.
.DESCRIPTION
    This script uses Jira REST API to fetch issues based on a JQL query and creates
    an iCalendar (.ics) file containing a formatted HTML table with the Jira data.
.NOTES
    Requires PowerShell 5.1 or higher
    Requires access to Jira REST API
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ReleaseVersion = "W14.2025.04.02",  # Default value if not provided
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "JiraConfig.ps1"       # Default config file path
)

# Display the received release version
Write-Host "Script started with release version: $ReleaseVersion"

# Get the directory of the current script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Resolve the config file path (either absolute or relative to script directory)
if (-not [System.IO.Path]::IsPathRooted($ConfigFile)) {
    $ConfigFile = Join-Path $scriptDir $ConfigFile
}

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    Write-Error "Please create a configuration file with Jira settings."
    exit
}

# Load configuration from file
try {
    Write-Host "Loading configuration from: $ConfigFile"
    # Use dot-sourcing with the full path
    . $ConfigFile
    
    # Verify required configuration variables
    if (-not $script:jiraBaseUrl -or -not $script:jiraApiToken -or -not $script:jqlQueryTemplate) {
        Write-Error "Configuration file is missing required variables."
        exit
    }
    
    Write-Host "Configuration loaded successfully."
} 
catch {
    Write-Error "Error loading configuration: $_"
    exit
}

# Extract date from release version (format: W15.2025.04.08)
Write-Host "Extracting date from release version: $ReleaseVersion"

$releaseDate = $null
if ($ReleaseVersion -match 'W\d+\.(\d{4})\.(\d{2})\.(\d{2})') {
    Write-Host "Regex match successful"
    $year = $matches[1]
    $month = [int]$matches[2]
    $day = [int]$matches[3]
    
    try {
        $releaseDate = Get-Date -Year $year -Month $month -Day $day
        
        # Get English month name regardless of system locale
        $englishMonths = @('January','February','March','April','May','June','July','August','September','October','November','December')
        $englishMonth = $englishMonths[$month-1]
        
        # Add ordinal suffix to day
        $dayNum = $day
        $suffix = switch -regex ($dayNum) {
            '1(1|2|3)$' { 'th' }
            '1$' { 'st' }
            '2$' { 'nd' }
            '3$' { 'rd' }
            default { 'th' }
        }
        
        $formattedDate = "$dayNum<sup>$suffix</sup> $englishMonth"
        Write-Host "Using release date: $dayNum$suffix $englishMonth $year"
    }
    catch {
        Write-Warning "Could not parse date from release version. Using today's date instead."
        $today = Get-Date
        $englishMonths = @('January','February','March','April','May','June','July','August','September','October','November','December')
        $formattedDate = "$($today.Day)<sup>th</sup> $($englishMonths[$today.Month-1])"
    }
}
else {
    Write-Warning "Release version format not recognized. Using today's date instead."
    $today = Get-Date
    $englishMonths = @('January','February','March','April','May','June','July','August','September','October','November','December')
    $formattedDate = "$($today.Day)<sup>th</sup> $($englishMonths[$today.Month-1])"
}

# Set up authorization header with just the token
$headers = @{
    Authorization = "Bearer $script:jiraApiToken"
    "Content-Type" = "application/json"
}

# Replace placeholder in JQL query template with actual release version
$jqlQuery = $script:jqlQueryTemplate -replace '{RELEASE_VERSION}', $ReleaseVersion

# Prepare the API request
$apiEndpoint = "$script:jiraBaseUrl/rest/api/2/search"
$body = @{
    jql = $jqlQuery
    maxResults = 100
    fields = @("summary", "fixVersions", "status", "issuetype", $script:customFieldIncCrqSrq)
} | ConvertTo-Json

# Execute the API request with simple error handling
try {
    $response = Invoke-RestMethod -Uri $apiEndpoint -Method Post -Headers $headers -Body $body
    $issues = $response.issues
    
    if ($issues.Count -eq 0) {
        Write-Warning "No issues found matching the JQL query."
        Write-Warning "Please check if the release version '$ReleaseVersion' is correct."
        exit
    }
    
    Write-Host "Retrieved $($issues.Count) issues from Jira."
} 
catch {
    Write-Error "Error retrieving Jira issues: $_"
    Write-Error "Please check if the release version '$ReleaseVersion' is correct."
    Write-Error "The JQL query may be invalid or there might be an issue with the Jira API connection."
    exit
}

# Create HTML table for the calendar invite
$tableStyle = "style='border-collapse: collapse; width: 100%; border: 1px solid #9CC2E5;'"
$headerStyle = "style='background-color: #9CC2E5; padding: 8px; border: 1px solid #9CC2E5; text-align: left;'"
$cellStyle = "style='padding: 8px; border: 1px solid #9CC2E5; text-align: left;'"

$htmlTable = @"
<table $tableStyle>
    <tr>
        <th $headerStyle>Issue Key</th>
        <th $headerStyle>Title</th>
        <th $headerStyle>Fix Versions</th>
        <th $headerStyle>INC/CRQ/SRQ</th>
    </tr>
"@

foreach ($issue in $issues) {
    $issueKey = $issue.key
    $title = $issue.fields.summary
    
    # Create hyperlink for the issue key
    $issueUrl = "$script:jiraBaseUrl/browse/$issueKey"
    $issueKeyWithLink = "<a href='$issueUrl'>$issueKey</a>"
    
    # Handle fix versions (could be multiple)
    $fixVersions = if ($issue.fields.fixVersions) {
        ($issue.fields.fixVersions | ForEach-Object { $_.name }) -join ", "
    } else { "N/A" }
    
    # Get the custom field for INC/CRQ/SRQ - using the field ID from config
    $customFieldName = $script:customFieldIncCrqSrq
    $incCrqSrq = if ($issue.fields.$customFieldName) { 
        $issue.fields.$customFieldName 
    } else { "N/A" }
    
    $htmlTable += @"
    <tr>
        <td $cellStyle>$issueKeyWithLink</td>
        <td $cellStyle>$title</td>
        <td $cellStyle>$fixVersions</td>
        <td $cellStyle>$incCrqSrq</td>
    </tr>
"@
}

$htmlTable += "</table>"

# Create the HTML content
$htmlContent = @"
<html>
<body>
<p>Hi All,</p>
<p>I am placing this Go-Live/Chat @ $formattedDate for the Product movement and Activation of ACE Migration Parent Change &lt;type here&gt;</p>
<p style="color: #4CAF50; font-weight: bold;">Note:- Required people will be called in (Requested in Live Chat) when required/On the basis of their turn.</p>
$htmlTable
<p>For more details, please visit <a href='$script:jiraBaseUrl'>Jira</a>.</p>
</body>
</html>
"@

# Properly escape the HTML content for iCalendar
# Replace newlines with \n and escape commas and semicolons
$escapedHtml = $htmlContent -replace "\r\n", "\n" -replace "\n", "\\n" -replace ",", "\," -replace ";", "\;"

# Create a plain text description as fallback
$plainTextDesc = "ACE Deployment live chat for $ReleaseVersion"

# Set up iCalendar parameters - use release date with fixed times (10 AM to 4 PM)
if ($releaseDate) {
    $startTime = $releaseDate.Date.AddHours(10) # 10:00 AM
    $endTime = $releaseDate.Date.AddHours(16)   # 4:00 PM
} else {
    $today = Get-Date
    $startTime = $today.Date.AddHours(10)
    $endTime = $today.Date.AddHours(16)
}
$startTimeStr = $startTime.ToString("yyyyMMddTHHmmss")
$endTimeStr = $endTime.ToString("yyyyMMddTHHmmss")
$now = (Get-Date).ToString("yyyyMMddTHHmmss")
$uid = [Guid]::NewGuid().ToString()

# Create the .ics file with HTML content using X-ALT-DESC and set as tentative
$icsContent = @"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//PowerShell Script//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
UID:$uid
DTSTAMP:$now
DTSTART:$startTimeStr
DTEND:$endTimeStr
SUMMARY:ACE Deployment live chat for $ReleaseVersion
LOCATION:Virtual Meeting
DESCRIPTION:$plainTextDesc
X-ALT-DESC;FMTTYPE=text/html:$escapedHtml
TRANSP:OPAQUE
STATUS:TENTATIVE
X-MICROSOFT-CDO-BUSYSTATUS:TENTATIVE
END:VEVENT
END:VCALENDAR
"@

# Save the .ics file
$desktopPath = [Environment]::GetFolderPath("Desktop")
$icsFile = Join-Path $desktopPath "JiraIssues_$ReleaseVersion.ics"
$icsContent | Out-File -FilePath $icsFile -Encoding utf8

# Open the .ics file with the default application
Start-Process $icsFile

Write-Host "iCalendar file created on desktop: $icsFile"
Write-Host "The file has been opened automatically." 