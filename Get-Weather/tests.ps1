# PSScriptAnalyzer tests
$scripts = Get-ChildItem -File -Filter '*.ps1' -Recurse | Where-Object {$_.Name -NotMatch 'tests.ps1'}
$Rules   = Get-ScriptAnalyzerRule

If ($scripts.count -gt 0) {
  Describe "Testing all Script against default PSScriptAnalyzer rule-set" {
    foreach ($Script in $scripts) {
      Context "Testing Script '$($script.FullName)'" {
        foreach ($rule in $rules) {
          It "passes the PSScriptAnalyzer Rule $($rule.RuleName)" {
            If (-not ($module.BaseName -match 'AppVeyor') -and -not ($rule.Rulename -eq 'PSAvoidUsingWriteHost') ) {
              (Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0
            }
          }
        }
      }
    }
  }
}