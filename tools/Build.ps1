Param(
    [Parameter(Mandatory=$true)]
    [string]$version,
    [string]$configuration = "Release",
    [boolean]$build = $true,
    [boolean]$nuspec = $true,
    [boolean]$publish = $false,
    [boolean]$pack = $false,
    [string]$outputFolder = "..\nuget"
)

# Include build functions
. "./BuildFunctions.ps1"

# The solution we are building
$solution = "../src/ScaffoldR.sln"

# Assemblies we are releasing
$assemblies = "../src/ScaffoldR", "../src/ScaffoldR.EntityFramework"

# Test assemblies
$testAssemblies = "../src/ScaffoldR.Tests", "../src/ScaffoldR.EntityFramework.Tests"

# Start by changing the assembly version
Write-Host "Changing the assembly versions to '$version'..."
Get-ChildItem ($assemblies + $testAssemblies) -Filter "AssemblyInfo.cs" -Recurse | 
    % { Update-AssemblyVersion $_.FullName $version }

# Build the entire solution
if ($build) {
    Write-Host "Cleaning and building $solution (Configuration: $configuration)"
    New-Solution $solution $configuration
}

# Change dependency version on all depending assemblies
if ($nuspec) {
    Write-Host "Changing the ScaffoldR(s) NuGet Spec version dependencies to '$version'..."
    Get-ChildItem $assemblies -Filter "ScaffoldR*.nuspec" -Recurse | 
        % { Update-NugetSpecDependencyVersion $_.FullName "ScaffoldR" $version }
}

# Pack the assemblies and move to output folder
if ($pack) {
    Write-Host "Packaging projects..."
    Get-ChildItem $assemblies -Filter "ScaffoldR*.csproj" -Recurse | 
        % { Invoke-PackNuget $_.FullName $configuration $outputFolder } 
}

# Publish the assemblies
if ($publish) {
    Write-Host "Publishing packages..."
    Get-ChildItem $outputFolder -Filter "*$version.nupkg" -Recurse | 
        % { Publish-NugetPackage $_.FullName } 
}