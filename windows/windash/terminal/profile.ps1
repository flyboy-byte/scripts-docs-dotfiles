# Shared PowerShell profile (Windows PowerShell 5.1 and PowerShell 7) - installed by setup\install-terminal.ps1.
# Change $PoshTheme to any file in ~\.config\oh-my-posh\themes:
#   powerlevel10k_modern, powerlevel10k_rainbow, powerlevel10k_classic, powerlevel10k_lean, robbyrussell (oh-my-zsh default)
$PoshTheme = 'powerlevel10k_modern'

# Skipped when output is redirected so scripts and tools that load the profile stay clean.
if (-not [Console]::IsOutputRedirected) {
    oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\themes\$PoshTheme.omp.json" | Invoke-Expression

    # File/folder icons in ls / Get-ChildItem output.
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue

    # Gray inline suggestions from history (PSReadLine 2.1+). Right arrow accepts the suggestion.
    if ((Get-Module PSReadLine).Version -ge [version]'2.1.0') {
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
    }
}
