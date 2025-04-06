# Jira API Configuration
$script:jiraBaseUrl = "https://jira.example.com"
$script:jiraApiToken = "your-api-token"

# JQL Query Template
# Use {RELEASE_VERSION} as a placeholder for the release version
$script:jqlQueryTemplate = 'project in (Project1, Project2, Project3, Project4) AND issuetype in (Epic, "User Story") AND status != "Done" AND (fixVersion ~ "PREFIX1.{RELEASE_VERSION}" OR fixVersion ~ "PREFIX2.{RELEASE_VERSION}" OR fixVersion ~ "PREFIX3.{RELEASE_VERSION}" OR fixVersion ~ "PREFIX4.{RELEASE_VERSION}") ORDER BY fixVersion ASC'

# Custom Field IDs
$script:customFieldIncCrqSrq = "customfield_10000"