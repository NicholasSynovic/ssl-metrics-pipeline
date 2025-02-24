#!/bin/bash
# This is the progam that analyzes a single repository
dt=$(date -d "today" +"%Y_%m_%d_%H_%M")
token=$2
repositoryFolder=$(basename $1 .git)
githubShortCode=$(echo $1 | sed -e 's/https:\/\/github.com\///g')

rootDir=$(basename $3 .txt)
jsonDir=json
pdfDir=pdfs
logDir=logs

mkdir $rootDir
mkdir $rootDir/$jsonDir
mkdir $rootDir/$pdfDir
mkdir $rootDir/$logDir

source env/bin/activate

git clone $1
git -C $repositoryFolder pull

# Extract commits
ssl-metrics-git-commits-loc-extract -d $repositoryFolder -b HEAD -o $rootDir/$jsonDir/$repositoryFolder-commits.json --log $rootDir/$logDir/$repositoryFolder-commits.log

# Extract issues
ssl-metrics-github-issues-collect -p -r $githubShortCode -o $rootDir/$jsonDir/$repositoryFolder-issues.json -t $token --log $rootDir/$logDir/$repositoryFolder-issues.log

# Compute bus factor
ssl-metrics-git-bus-factor-compute -i $rootDir/$jsonDir/$repositoryFolder-commits.json -o $rootDir/$jsonDir/$repositoryFolder-bf.json

# Graph bus factor
ssl-metrics-git-bus-factor-graph -i $rootDir/$jsonDir/$repositoryFolder-bf.json -o $rootDir/$pdfDir/$repositoryFolder-bf.pdf --type bar --title $githubShortCode" Bus Factor" --x-label "Day" --y-label "Bus Factor" --stylesheet style.mplstyle
ssl-metrics-git-bus-factor-graph -i $rootDir/$jsonDir/$repositoryFolder-bf.json -o $rootDir/$repositoryFolder-bf.png --type bar --title $githubShortCode" Bus Factor" --x-label "Day" --y-label "Bus Factor" --stylesheet style.mplstyle

# Compute issue density
ssl-metrics-github-issue-density-compute -c $rootDir/$jsonDir/$repositoryFolder-commits.json -i $rootDir/$jsonDir/$repositoryFolder-issues.json -o $rootDir/$jsonDir/$repositoryFolder-id.json

# Graph issue density
ssl-metrics-github-issue-density-graph -i $rootDir/$jsonDir/$repositoryFolder-id.json -o $rootDir/$pdfDir/$repositoryFolder-id.pdf --title $githubShortCode" Issue Density" --x-label "Day" --y-label "Issue Density" --stylesheet style.mplstyle
ssl-metrics-github-issue-density-graph -i $rootDir/$jsonDir/$repositoryFolder-id.json -o $rootDir/$repositoryFolder-id.png --title $githubShortCode" Issue Density" --x-label "Day" --y-label "Issue Density" --stylesheet style.mplstyle

# Compute productivity
ssl-metrics-git-productivity-compute -i $rootDir/$jsonDir/$repositoryFolder-commits.json -o $rootDir/$jsonDir/$repositoryFolder-pr.json

# Graph productivity
ssl-metrics-git-productivity-graph -i $rootDir/$jsonDir/$repositoryFolder-pr.json -o $rootDir/$pdfDir/$repositoryFolder-p.pdf --title $githubShortCode" Productivity" --x-label "Day" --y-label "Productivity" --stylesheet style.mplstyle
ssl-metrics-git-productivity-graph -i $rootDir/$jsonDir/$repositoryFolder-pr.json -o $rootDir/$repositoryFolder-p.png --title $githubShortCode" Productivity" --x-label "Day" --y-label "Productivity" --stylesheet style.mplstyle

# Compute issue spoilage
ssl-metrics-github-issue-spoilage-compute -i $rootDir/$jsonDir/$repositoryFolder-issues.json -o $rootDir/$jsonDir/$repositoryFolder-is.json

# Graph issue spoilage
ssl-metrics-github-issue-spoilage-graph -i $rootDir/$jsonDir/$repositoryFolder-is.json -o $rootDir/$pdfDir/$repositoryFolder-is.pdf --title $githubShortCode" Issue Spoilage" --x-label "Day" --y-label "Issue Spoilage" --stylesheet style.mplstyle
ssl-metrics-github-issue-spoilage-graph -i $rootDir/$jsonDir/$repositoryFolder-is.json -o $rootDir/$repositoryFolder-is.png --title $githubShortCode" Issue Spoilage" --x-label "Day" --y-label "Issue Spoilage" --stylesheet style.mplstyle

# Sync outputs to GDrive
rclone copy $rootDir gdrive:"Software and Systems Laboratory"/"Paper Writing"/"figures"/$dt/$rootDir
