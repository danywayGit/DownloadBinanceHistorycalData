<#
.Synopsis
   Get Binance symbols list
.DESCRIPTION
   Get Binance symbols list for spot or futur (CM = COIN-M Futures, UM = USD-M Futures)
.EXAMPLE
   Get-SymbolsList '-Spot'
.EXAMPLE
   Get-SymbolsList -Futures' -FuturesType 'cm'
.EXAMPLE
   Get-SymbolsList -Futures' -FuturesType 'um'
#>
function Get-SymbolsList {
    [CmdletBinding(DefaultParameterSetName='Spot')]
    Param(
        [Parameter(Position=0, Mandatory=$false, ParameterSetName='Spot')]
        [switch]
        $Spot,

        [Parameter(Position=0, Mandatory=$false, ParameterSetName='Futures')]
        [switch]
        $Futures,

        [Parameter(Position=1, Mandatory=$true, ParameterSetName='Futures')]
        [ValidateSet('cm', 'um')]
        [string]
        $FuturesType
    )

    $symbolsFolder = "symbols-list"
    if (-not (Test-Path $symbolsFolder)) {
        $null = New-Item -ItemType Directory -Path $symbolsFolder
    }

    if ($Futures) {
        switch ($FuturesType) {
            cm { 
                    $baseUrl = 'https://dapi.binance.com/dapi/v1/exchangeInfo'
                    $symbolsFile = Join-Path -Path $symbolsFolder -ChildPath "futur-cm.txt"
                    $ContractType = 'futures-cm'
            }
            um { 
                    $baseUrl = 'https://fapi.binance.com/fapi/v1/exchangeInfo'
                    $symbolsFile = Join-Path -Path $symbolsFolder -ChildPath "futur-um.txt"
                    $ContractType = 'futures-um'
            }
            Default {
                throw "FuturesType must be set to 'cm' or 'um'"
            }
        }
    }
    # for spot    
    else {
        $baseUrl = 'https://api.binance.com/api/v3/exchangeInfo'
        $symbolsFile = Join-Path -Path $symbolsFolder -ChildPath "spot.txt"
        $ContractType = 'spot'
    }

    try {
        $WebRequestResult = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
        $symbolsList = $WebRequestResult.Content | ConvertFrom-Json
    }
    catch {
        $errorMessage = $_.Exception.Message
        $response = $_.Exception.Response
        if ($response -and $response.StatusCode -eq 404) {
            Write-Host "Warning : $($response.ResponseUri) $($response.StatusCode)." -ForegroundColor Yellow
        }
        else {
            Write-Host "Warning : $errorMessage" -ForegroundColor Yellow
            Write-Host "Warning : uri = $($params.Uri)" -ForegroundColor Yellow
        }
    }

    Write-Host "Getting all symbols for contract type $ContractType"
    # status = TRADING for spot, and Futurs um, contractStatus = TRADING for futur cm
    (@($symbolsList).symbols | Where-Object {$_.status -eq 'TRADING' -or $_.contractStatus -eq 'TRADING'}).symbol | Out-File $symbolsFile
    Write-Verbose "Symbols saved in $symbolsFolder"   
}